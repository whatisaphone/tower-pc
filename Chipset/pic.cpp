#include "stdafx.h"
#include "pic.h"

#include "Piston\String.h"

namespace Tower { namespace Chipset {
	Pic::PicChip Pic::m, Pic::s;

	// cpu assrts INTA pin and expects vector
	TOWER_EXPORT int8 tower_pic_INTA() {
		int8 ret = 0;

		for(int i = Pic::m.highest_priority; i < Pic::m.highest_priority + 8; ++i)
			if(Pic::m.irr & (1 << (i & 7))) if(!(Pic::m.mask & (1 << (i & 7)))) {
				ret = i & 7;
				Pic::m.irr &= ~(1 << ret);
				Pic::m.isr |= (1 << ret);
				break;
			}

		if(ret == 2) {
			for(int i = Pic::s.highest_priority; i < Pic::s.highest_priority + 8; ++i)
				if(Pic::s.irr & (1 << (i & 7))) if(!(Pic::s.mask & (1 << (i & 7)))) {
					ret = i & 7;
					Pic::s.irr &= ~(1 << ret);
					Pic::s.isr |= (1 << ret);
					break;
				}
			return Pic::s.vector_offset | ret;
		} else
			return Pic::m.vector_offset | ret;
	}

	// device asserts an IR pin
	TOWER_EXPORT void tower_pic_RaiseIRQ(int8 irq) {
		ZSSERT(irq <= 0xf);
		if(irq > 0xf) return;

		Pic::PicChip &chip = (irq & 8 ? Pic::s : Pic::m);

		irq &= 7;
		chip.irr |= (1 << irq);
		Pic::CheckPendingInts(chip);
	}

	void Pic::CheckPendingInts(PicChip &chip) {
		for(int8 i = chip.highest_priority; i < chip.highest_priority + 8; ++i)
			if(chip.irr & (1 << (i & 7))) // if IRR bit set
			if(!(chip.mask & (1 << i))) { // if not masked
				plug_pic->ExternalInterrupt();
				break;
			}
	}

	int8 Pic::Read8(int16 port) {
		ZSSERT((port & 0xff7e) == 0x20);
		PicChip &chip = (port & 0x80 ? s : m);
		ZSSERT(!chip.init_stage);

		if(!(port & 1)) { // 0x20 or 0xa0
			return chip.next_read_isr ? chip.isr : chip.irr;
		} else
			return chip.mask;
	}

	int16 Pic::Read16(int16 port) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIC] Invalid 16-bit read from port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
		return 0xffff;
	}

	int32 Pic::Read32(int16 port) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIC] Invalid 32-bit read from port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
		return 0xffffffff;
	}

	void Pic::Write8(int16 port, int8 value) {
		ZSSERT((port & 0xff7e) == 0x20);
		PicChip &chip = (port & 0x80 ? s : m);

		if(!(port & 1)) { // 0x20 or 0xa0
			if(value & 0x10) { // icw1
				ZSSERT(value == 0x11);
				chip.needs_icw4 = (value & 0x1);
				chip.only_pic = (value & 0x2) ? 1 : 0;
				chip.call_addr_interval_4 = (value & 0x4) ? 1 : 0;
				chip.level_triggered = (value & 0x8) ? 1 : 0;
				chip.msc_vect = (value & 0xe0) >> 5;
				chip.init_stage = 2;
			} else if(!(value & 0x8)) { // ocw2
				ZSSERT(!chip.init_stage);
				switch(value & 0xe0) {
				case 0xa0: // non-specific eoi + set lowest priority
					ZSSERT(0);
					for(int p = chip.highest_priority; p < chip.highest_priority + 8; ++p)
						if(chip.isr & (1 << (p & 7))) {
							chip.highest_priority = (p + 1) & 7;
							chip.isr &= ~(1 << (p & 7));
							break;
						}
					break; // nothing was in-service, ignore
				case 0x20: // non-specific eoi
					for(int p = chip.highest_priority; p < chip.highest_priority + 8; ++p)
						if(chip.isr & (1 << (p & 7))) {
							chip.isr &= ~(1 << (p & 7));
							break;
						}
					break; // nothing was in-service, ignore

				case 0x60: // specific eoi
					ZSSERT(0);
					chip.isr &= ~(1 << (value & 7));
					break;

				case 0x80: // rotate in auto eoi mode (set)
				case 0x00: // rotate in auto eoi mode (clear)
					ZSSERT(0);
					break;

				case 0xc0: // set lowest priority
					ZSSERT(0);
					chip.highest_priority = ((value + 1) & 7);
				case 0xe0: // specific eoi + set lowest priority
					ZSSERT(0);
					chip.isr &= ~(1 << (value & 7));
					break;
				}
				CheckPendingInts(chip);
			} else { // ocw3
				ZSSERT(!chip.init_stage);
				ZSSERT((value & 0xfe) == 0x0a); // bits we don't handle yet
				chip.next_read_isr = value & 1;
			}
		} else { // 0x21 or 0xa1
			if(chip.init_stage == 2) { // icw2
				chip.vector_offset = value;
				chip.init_stage = (chip.only_pic ? (chip.needs_icw4 ? 4 : 0) : 3);
			} else if(chip.init_stage == 3) { // icw3
				chip.icw3 = value;
				++chip.init_stage;
				if(!chip.needs_icw4)
					Write8(port, 0); // icw4=0
			} else if(chip.init_stage == 4) { // icw4
				ZSSERT(value == 0x01);
				chip.mode8086 = (value & 0x1);
				chip.auto_eoi = (value & 0x2) ? 1 : 0;
				chip.buf_ismaster = (value & 0x4) ? 1 : 0;
				chip.buf_enabled = (value & 0x8) ? 1 : 0;
				chip.special_nested = (value & 0x10) ? 1 : 0;
				if(chip.mode8086)
					chip.vector_offset &= 0xf8; // only keep top 5 bits
				chip.init_stage = 0; // ready for normal operation
			} else { // ocw2/imr
				chip.mask = value;
			}
		}
	}

	void Pic::Write16(int16 port, int16 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIC] Invalid 16-bit write of " +
			Piston::String::Render(value).PadLeft(4, L'0') + L" to port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}

	void Pic::Write32(int16 port, int32 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIC] Invalid 32-bit write of " +
			Piston::String::Render(value).PadLeft(8, L'0') + L" to port 0x" +
			Piston::String::Render(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}
}}