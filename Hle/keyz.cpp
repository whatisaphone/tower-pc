#include "stdafx.h"
#include "calls.h"

#include "Piston\String.h"
#include "Piston\System\Thread.h"

namespace Tower { namespace Hle {
	//int pending_key;

	const static struct {
		int8 normal, shift;
	} to_ascii[0x80] = { // scancode set 1
		// 0x0_
		{0, 0},
		{0, 0},
		{'1', '!'},
		{'2', '@'},
		{'3', '#'},
		{'4', '$'},
		{'5', '%'},
		{'6', '^'},
		{'7', '&'},
		{'8', '*'},
		{'9', '('},
		{'0', ')'},
		{'-', '_'},
		{'=', '+'},
		{8, 8},
		{'\t', '\t'},

		// 0x1_
		{'q', 'Q'},
		{'w', 'W'},
		{'e', 'E'},
		{'r', 'R'},
		{'t', 'T'},
		{'y', 'Y'},
		{'u', 'U'},
		{'i', 'I'},
		{'o', 'O'},
		{'p', 'P'},
		{'[', '{'},
		{']', '}'},
		{13, 13},
		{0, 0},
		{'a', 'A'},
		{'s', 'S'},

		// 0x2_
		{'d', 'D'},
		{'f', 'F'},
		{'g', 'G'},
		{'h', 'H'},
		{'j', 'J'},
		{'k', 'K'},
		{'l', 'L'},
		{';', ':'},
		{'\'', '"'},
		{'`', '~'},
		{0, 0},
		{'\\', '|'},
		{'z', 'Z'},
		{'x', 'X'},
		{'c', 'C'},
		{'v', 'V'},

		// 0x3_
		{'b', 'B'},
		{'n', 'N'},
		{'m', 'M'},
		{',', '<'},
		{'.', '>'},
		{'/', '?'},
		{0, 0},
		{'*', '*'},
		{0, 0},
		{' ', ' '},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{0, 0},
		{'7', '7'}
	};

	void int_09() {
		int16 first = plug_dev->MemRead16(0x480);
		int16 last = plug_dev->MemRead16(0x482);
		int16 next = plug_dev->MemRead16(0x41a);
		int16 free = plug_dev->MemRead16(0x41c);
		int8 status_1 = plug_dev->MemRead8(0x417);
		int8 status_2 = plug_dev->MemRead8(0x418);
		int8 status_3 = plug_dev->MemRead8(0x496);
		int8 status_4 = plug_dev->MemRead8(0x497);

		plug->Log(plug_persist, LOG_TRACE, L"Enter HLE's int_09");

		while(plug_dev->PortRead8(0x64) & 1) { // while there are still any keys
			int8 special = 0;
			int8 scan = 0, to_add = 0;

			scan = plug_dev->PortRead8(0x60);
			if(scan == 0xe0) {
				special = 1;
				ZSSERT(plug_dev->PortRead8(0x64) & 1);
				scan = plug_dev->PortRead8(0x60);
			}

			switch(scan) {
			case 0x2a: // L shift
				status_1 |= 2;
				break;
			case 0x2a + 0x80:
				status_1 &= ~2;
				break;
			case 0x36: // R shift
				status_1 |= 1;
				break;
			case 0x36 + 0x80:
				status_1 &= ~1;
				break;
			case 0x3a: // caps lock
				status_1 ^= 0x40;
				status_2 |= 0x40;
				break;
			case 0xba:
				status_2 &= ~0x40;
				break;
			case 0x45: // numlock
				status_1 ^= 0x20;
				status_2 |= 0x20;
				break;
			case 0xc5:
				status_2 &= ~0x20;
				break;
			case 0x52: // insert
				status_2 |= 0x80;
				break;
			case 0xd2:
				status_2 &= ~0x80;
				break;
			}

			if(scan >= 0x80)
				continue; // ignore key releases

			int8 use_shift = (status_1 & 3 ? 1 : 0) ^ (status_1 & 0x40 ? 1 : 0);

			if(use_shift)
				to_add = to_ascii[scan].shift;
			else
				to_add = to_ascii[scan].normal;

			//if(to_add) {
				if((free + 2 == next) || ((free + 2 >= last) && (next == first))) {
					plug->Log(plug_persist, LOG_WARNING, L"[KEYZ] Keyboard buffer full, unable to add 0x" + 
						Piston::String::Renderhex((scan << 8) | to_add).PadLeft(4, L'0'));
				} else {
					plug->Log(plug_persist, LOG_TRACE,
						(special ? L"int_09 dequeued extended scancode 0x" : L"int_09 dequeued scancode 0x") +
						Piston::String::Renderhex(scan).PadLeft(2, L'0') + L", added 0x" +
						Piston::String::Renderhex((scan << 8) | to_add).PadLeft(4, L'0') +
						L" to circular buffer");
					plug_dev->MemWrite16(0x400 + free, (scan << 8) | to_add);
					free += 2;
				}
			//}
		}

		plug->Log(plug_persist, LOG_TRACE, L"Leaving hle_int_09");

		plug_dev->MemWrite8(0x417, status_1);
		plug_dev->MemWrite8(0x418, status_2);
		plug_dev->MemWrite8(0x496, status_3);
		plug_dev->MemWrite8(0x497, status_4);
		if(free >= last) free = first;
		plug_dev->MemWrite16(0x41c, free);
	}

	void int_16() {
		int16 first = plug_dev->MemRead16(0x480);
		int16 last = plug_dev->MemRead16(0x482);
		int16 next = plug_dev->MemRead16(0x41a);
		int16 free = plug_dev->MemRead16(0x41c);

		switch(*ah) {
		/*case 0x00: // block waiting for key
			// RETURNS: ah = scan code
			//          al = ascii character
			while(next == free) { // sloppy
				next = plug_dev->MemRead16(0x41a);
				free = plug_dev->MemRead16(0x41c);
				Piston::System::Thread::Sleep(1);
			}

			*ax = plug_dev->MemRead16(0x400 + next);
			next += 2;
			break;*/
		case 0x01: // is key available?
			// RETURNS: zf set if keystroke available
			//          ah = scan code
			//          al = ascii character
			if(next != free) {
			 	*flags &= ~flags_mask_zf;
				*ax = plug_dev->MemRead16(0x400 + next);
			} else
				*flags |= flags_mask_zf;
			break;
		case 0x02: // shift key state
			//*al = 0x20; // just numlock
			*al = plug_dev->MemRead16(0x417);
			break;
		default:
			plug->Log(plug_persist, LOG_ERROR, L"INT16 (KB): Unimpl ah value 0x" +
				Piston::String::Renderhex(*ah).PadLeft(2, L'0'));
		}

		if(next >= last) next = first;
		plug_dev->MemWrite16(0x41a, next);
	}
}}