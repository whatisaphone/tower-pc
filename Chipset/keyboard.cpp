#include "stdafx.h"
#include "keyboard.h"

#include "Piston\String.h"
#include "Piston\Win32\ui.h"

#include "keyboard_codes.h"

namespace Tower { namespace Chipset {
	int8 KBC::last_command;
	int8 KBC::port61_toggle;
	int8 KBC::chip_ram[0x20];
	int8 KBC::out_bfr[16];

	// status byte
	int8 KBC::out_bfr_len;
	int8 KBC::system_flag;
	int8 KBC::in_bfr_is_command;
	int8 KBC::kbd_switched_off;
	int8 KBC::transmit_timeout;
	int8 KBC::receive_timeout;
	int8 KBC::even_parity;

	// command byte
	int8 KBC::enable_irq1;
	int8 KBC::enable_irq12;
	int8 KBC::system_flag_2;
	int8 KBC::ignore_kbd_lock;
	int8 KBC::kbd_clock_off;
	int8 KBC::aux_clock_off;
	int8 KBC::translation_on;

	int8 Keyboard::last_command;
	int8 Keyboard::scancode_set;
	int8 Keyboard::LEDs;

	TOWER_EXPORT void tower_KeyDown(int32 keyInfo) {
		Keyboard::tower_KeyEvent(keyInfo);
	}

	TOWER_EXPORT void tower_KeyUp(int32 keyInfo) {
		Keyboard::tower_KeyEvent(keyInfo);
	}

	void Keyboard::tower_KeyEvent(int32 keyInfo) {
		ZSSERT((int16)keyInfo <= 0xff);

		int16 vkey;
		if((int16)keyInfo == Piston::Win32::VK_SHIFT)
			vkey = (keyInfo & (1 << 24) ? Piston::Win32::VK_SHIFT_L : Piston::Win32::VK_SHIFT_R);
		else if((int16)keyInfo == Piston::Win32::VK_CTRL)
			vkey = (keyInfo & (1 << 24) ? Piston::Win32::VK_CTRL_L : Piston::Win32::VK_CTRL_R);
		else if((int16)keyInfo == Piston::Win32::VK_ALT)
			vkey = (keyInfo & (1 << 24) ? Piston::Win32::VK_ALT_L : Piston::Win32::VK_ALT_R);
		else
			vkey = (int16)keyInfo;

		ZSSERT(Scancodes[vkey][0].make[0] != 0);
		plug->Log(plug_persist, LOG_DEBUG, L"[KBC] keyInfo = 0x" +
			Piston::String::Renderhex(keyInfo).PadLeft(8, L'0') + L": v-key 0x" +
			Piston::String::Renderhex(vkey).PadLeft(2, L'0') +
			(keyInfo & (1 << 31) ? L" down" : L" up"));

		if(keyInfo & (1 << 31))
			KBC::FromKbd((int8 *)Scancodes[vkey][scancode_set].make);
		else
			KBC::FromKbd((int8 *)Scancodes[vkey][scancode_set].brake);
 	}

	int8 KBC::Buffer::Read() {
		int8 ret;

		if(out_bfr_len > 0) {
			ret = out_bfr[0];

			for(int i = 1; i < out_bfr_len; ++i)
				out_bfr[i - 1] = out_bfr[i];
			--out_bfr_len;

			plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Read 0x" +
				Piston::String::Renderhex(ret).PadLeft(2, L'0') + L" from buffer (remaining bytes: " +
				Piston::String::Render(out_bfr_len) + L")");
		} else {
			ret = 0;
			plug->Log(plug_persist, LOG_ERROR, L"[KBC] Buffer read while buffer is empty!  Returning 0x" +
				Piston::String::Renderhex(ret).PadLeft(2, L'0'));
		}

		return ret;
	}

	void KBC::Buffer::WriteRaw(int8 byte) {
		ZSSERT(out_bfr_len < sizeof(out_bfr));
		out_bfr[out_bfr_len++] = byte;
	}

	void KBC::Buffer::Write(int8 byte) {
		ZSSERT(out_bfr_len < sizeof(out_bfr));
		if(translation_on) {
			ZSSERT(byte != 0xf0);
			out_bfr[out_bfr_len++] = translate[byte];
			plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Wrote 0x" +
				Piston::String::Renderhex(out_bfr[out_bfr_len - 1]).PadLeft(2, L'0') + L" into buffer (was 0x" +
				Piston::String::Renderhex(byte).PadLeft(2, L'0') + L" before translation)");
		} else {
			out_bfr[out_bfr_len++] = byte;
			plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Wrote 0x" +
				Piston::String::Renderhex(out_bfr[out_bfr_len - 1]).PadLeft(2, L'0') + L" into buffer");
		}
	}

	void KBC::Buffer::Write(int8 *bytes) {
		for(; *bytes; ++bytes) {
			if(out_bfr_len >= sizeof(out_bfr)) {
				plug->Log(plug_persist, LOG_ERROR, L"[KBC] No room for keyboard data in buffer; ignoring.");
				return;
			}
			if(translation_on) {
				if(*bytes == 0xf0) { // convert prefix
					ZSSERT(*(bytes + 1));
					out_bfr[out_bfr_len++] = translate[*++bytes] | 0x80;
					plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Wrote 0x" +
						Piston::String::Renderhex(out_bfr[out_bfr_len - 1]).PadLeft(2, L'0') + L" into buffer (was 0xf0 0x" +
						Piston::String::Renderhex(*bytes).PadLeft(2, L'0') + L" before translation)");
				} else {
					out_bfr[out_bfr_len++] = translate[*bytes];
					plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Wrote 0x" +
						Piston::String::Renderhex(out_bfr[out_bfr_len - 1]).PadLeft(2, L'0') + L" into buffer (was 0x" +
						Piston::String::Renderhex(*bytes).PadLeft(2, L'0') + L" before translation)");
				}
			} else {
				out_bfr[out_bfr_len++] = *bytes;
				plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Wrote 0x" +
					Piston::String::Renderhex(out_bfr[out_bfr_len - 1]).PadLeft(2, L'0') + L" into buffer");
			}
		}
	}

	void KBC::FromKbd(int8 *sequence) {
		if(kbd_clock_off || (kbd_switched_off & !ignore_kbd_lock))
			return;

		Buffer::Write(sequence);

		if(enable_irq1)
			plug_dev->RaiseIRQ(1);
	}

	void KBC::FromKbd(int8 byte) {
		if(kbd_clock_off || (kbd_switched_off & !ignore_kbd_lock))
			return;

		Buffer::Write(byte);

		if(enable_irq1)
			plug_dev->RaiseIRQ(1);
	}

	void Keyboard::FromKbc(int8 byte) {
		switch(last_command) { // expecting a write from previous command?
		case 0xed: // set LEDs
			LEDs = byte;
			plug->StatusItems.SetText(plug_status_scrl, (LEDs & 1 ? L"SCRL on" : L"SCRL off"));
			plug->StatusItems.SetText(plug_status_num, (LEDs & 2 ? L"NUM on" : L"NUM off"));
			plug->StatusItems.SetText(plug_status_caps, (LEDs & 4 ? L"CAPS on" : L"CAPS off"));
			SendACK();

			last_command = 0;
			break;
		case 0xf0: // set scancode set
			if(byte == 0) {
				int8 resp[3] = {0xfa, scancode_set + 1, 0};
				Send(resp);
			} else if(byte <= 3) {
				plug->Log(plug_persist, LOG_INFO, L"[KBD] Scancode set " +
					Piston::String::Render(byte) + L" selected");
				scancode_set = byte - 1;
			} else {
				plug->Log(plug_persist, LOG_ERROR, L"[KBD] Invalid scancode set 0x" +
					Piston::String::Renderhex(byte).PadLeft(2, L'0') + L" requested");
				ZSSERT(0);
				SendERR();
			}

			last_command = 0;
			break;
		default:
			switch(last_command = byte) {
			case 0x05: // ??? (win 3.0 setup)
				plug->Log(plug_persist, LOG_INFO, L"[KBD] Received unknown byte 0x05, ERR'd");
				SendERR();
				break;
			case 0xed: // set LEDs
				SendACK(); // ack
				break;
			case 0xee: // diagnostic echo
				Send(0xee);
				break;
			case 0xf0: // select scancode set
				SendACK();
				break;
			case 0xf2: // read keyboard ID
				Send((int8 *)"\xFA\x83\xAB"); // FA=ack, 83AB=id
				break;
			case 0xf4: // enable keyboard
				plug->Log(plug_persist, LOG_INFO, L"[KBD] Keyboard enabled");
				SendACK();
				break;
			case 0xf5: // disable keyboard
				plug->Log(plug_persist, LOG_INFO, L"[KBD] Keyboard disabled");
				SendACK();
				break;
			default:
				plug->Log(plug_persist, LOG_ERROR, L"[KBD] Unknown byte received from controller: 0x" +
					Piston::String::Renderhex(byte).PadLeft(2, L'0'));
				ZSSERT(0);
				SendERR();
			}
		}

	}

	int8 TOWER_CC KBC::Read8(int16 port) {
		switch(port) {
		case 0x60:
			return Buffer::Read();
		case 0x61: // ignore for now
			port61_toggle ^= 0x10;
			return port61_toggle;
		case 0x64:
			plug->Log(plug_persist, LOG_TRACE, L"[KBC] Read status byte, out_bfr_len = " +
				Piston::String::Render(out_bfr_len));
			return (out_bfr_len ? 1 : 0) |
				(system_flag << 2) |
				(in_bfr_is_command << 3) |
				(kbd_switched_off << 4) |
				(transmit_timeout << 5) |
				(receive_timeout << 6) |
				(even_parity << 7);
		}
		plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 8-bit read from port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
		return 0xff;
	}

	int16 TOWER_CC KBC::Read16(int16 port) {
		plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 16-bit read from port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
		return 0xffff;
	}

	int32 TOWER_CC KBC::Read32(int16 port) {
		plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 32-bit read from port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
		return 0xffffffff;
	}

	void TOWER_CC KBC::Write8(int16 port, int8 value) {
		switch(port) {
		case 0x60: // write command byte
			in_bfr_is_command = 0;
			switch(last_command) {
			case 0x60:
				enable_irq1 = value & 1 ? 1 : 0;
				enable_irq12 = value & 2 ? 1 : 0;
				system_flag = value & 4 ? 1 : 0;
				ignore_kbd_lock = value & 8 ? 1 : 0;
				kbd_clock_off = value & 16 ? 1 : 0;
				aux_clock_off = value & 32 ? 1 : 0;
				translation_on = value & 64 ? 1 : 0;
				ZSSERT((value & 0x84) == 0); // unknown bytes

				last_command = 0;
				break;
			case 0xd1: // write output port
				ZSSERT(value & 1); // system reset line MUST BE 1 (active low)
				if(value & 2)
					plug->Log(plug_persist, LOG_WARNING, L"[KBC] Enable A20: unimplemented.");

				last_command = 0;
				break;
			default:
				Keyboard::FromKbc(value);
			}
			break;
		case 0x61: // (?) ignore for now
			plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Write of 0x" +
				Piston::String::Renderhex(value) + L" to port 0x61");
			break;
		case 0x64:
			in_bfr_is_command = 1;
			switch(last_command = value) {
			case 0x20: // read command byte
				Buffer::WriteRaw(
					(enable_irq1 << 0) |
					(enable_irq12 << 1) |
					(system_flag_2 << 2) |
					(ignore_kbd_lock << 3) |
					(kbd_clock_off << 4) |
					(aux_clock_off << 5) |
					(translation_on << 6));
				break;
			case 0x60: // write command byte to port 0x60
				break;
			case 0xa7: // disable aux
				if(!aux_clock_off)
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Aux clock disabled");
				aux_clock_off = 1;
				break;
			case 0xa8: // enable aux
				if(aux_clock_off)
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Aux clock enabled");
				aux_clock_off = 0;
				break;
			case 0xad: // disable keyboard
				if(!kbd_clock_off)
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Keyboard clock disabled");
				kbd_clock_off = 1;
				break;
			case 0xae: // enable keyboard
				if(kbd_clock_off)
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Keyboard clock enabled");
				kbd_clock_off = 0;
				break;
			case 0xd1: // write output port to port 0x60
				break;
			case 0xf0: case 0xf1: case 0xf2: case 0xf3:
			case 0xf4: case 0xf5: case 0xf6: case 0xf7:
			case 0xf8: case 0xf9: case 0xfa: case 0xfb:
			case 0xfc: case 0xfd: case 0xfe: case 0xff: // pulse low bits low
				if(!(value & 1)) {
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Output port bits " +
						Piston::String::Render(~value & 15) + L" pulsed low; system reset.");
					ZSSERT(0); // put reset code in?
				} else {
					plug->Log(plug_persist, LOG_INFO, L"[KBC] Output port bits " +
						Piston::String::Render(~value & 15) + L" pulsed low");
				} break;
			default:
				plug->Log(plug_persist, LOG_DEBUG, L"[KBC] Write of 0x" +
					Piston::String::Renderhex(value) + L" to port 0x64");
				ZSSERT(0);
			} break;
		default:
			plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 8-bit write of " +
				Piston::String::Render(value).PadLeft(2, L'0') + L" to port 0x" +
				Piston::String::Render(port).PadLeft(4, L'0'));
			ZSSERT(0);
		}
	}

	void TOWER_CC KBC::Write16(int16 port, int16 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 16-bit write of " +
			Piston::String::Render(value).PadLeft(4, L'0') + L" to port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}

	void TOWER_CC KBC::Write32(int16 port, int32 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[KBC] Invalid 32-bit write of " +
			Piston::String::Render(value).PadLeft(8, L'0') + L" to port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}
}}