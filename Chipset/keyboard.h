#pragma once
#include "stdafx.h"

namespace Tower { namespace Chipset {
	struct KBC {
	private:
		KBC();
		KBC(const KBC &copy);
		KBC &operator=(const KBC &copy);

		const static int8 translate[256];

		struct Buffer {
			static int8 Read();
			static void WriteRaw(int8 byte);
			static void Write(int8 byte);
			static void Write(int8 *bytes);
		} Buffer;

		static int8 last_command;
		static int8 port61_toggle;
		static int8 chip_ram[0x20];
		static int8 out_bfr[16];

		// status byte
		static int8 out_bfr_len;
		static int8 system_flag;
		static int8 in_bfr_is_command;
		static int8 kbd_switched_off;
		static int8 transmit_timeout;
		static int8 receive_timeout;
		static int8 even_parity;

		// command byte
		static int8 enable_irq1;
		static int8 enable_irq12;
		static int8 system_flag_2;
		static int8 ignore_kbd_lock;
		static int8 kbd_clock_off;
		static int8 aux_clock_off;
		static int8 translation_on;

	public:
		static int8 TOWER_CC Read8(int16 port);
		static int16 TOWER_CC Read16(int16 port);
		static int32 TOWER_CC Read32(int16 port);
		static void TOWER_CC Write8(int16 port, int8 value);
		static void TOWER_CC Write16(int16 port, int16 value);
		static void TOWER_CC Write32(int16 port, int32 value);

		static void FromKbd(int8 *sequence);
		static void FromKbd(int8 byte);
	};

	class Keyboard {
	private:
		Keyboard();
		Keyboard(const Keyboard &copy);
		Keyboard &operator=(const Keyboard &copy);

		static void Send(int8 byte) {KBC::FromKbd(byte);}
		static void Send(int8 *sequence) {KBC::FromKbd(sequence);}
		static void SendACK() {KBC::FromKbd(0xfa);}
		static void SendERR() {KBC::FromKbd(0xfe);}

		const static struct scifo {
			char *make;
			char *brake;
		} Scancodes[0x100][3];

		static int8 last_command;
		static int8 scancode_set;
		static int8 LEDs;

	public:
		static void FromKbc(int8 byte);

		static void tower_KeyEvent(int32 info);
	};
}}