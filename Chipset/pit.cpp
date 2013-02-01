#include "stdafx.h"
#include "pit.h"

#include "Piston\String.h"

namespace Tower { namespace Chipset {
	Piston::Thread<void()> *Pit::Thread;
	Pit::Timer Pit::timer[3];

	int32 Pit::Init() {
		for(int num = 0; num < 3; ++num) {
			// some random defaults
			timer[num].bcd = 0;
			timer[num].counter_mode = 0;
			timer[num].rw_disp = 3;
			timer[num].counter = 0;
			timer[num].initial = 0;
			timer[num].out_latched = 0;
			timer[num].out_latch_next_msb = 0;
			timer[num].in_next_msb = 0;
			timer[num].OUT = 0;
			timer[num].running = 0;
		}

		Thread = new Piston::Thread<void()>(&PitThread);
		Thread->StartSuspended();
		return 1;
	}

	void Pit::Uninit() {
		Thread->Terminate();
		delete Thread;
	}

	int32 Pit::Run() {
		Thread->Resume();
		return 1;
	}

	void Pit::Pause() {
		Thread->Suspend();
	}

	void Pit::PitThread() {
		for(;;) { // yeah, this whole thing is a hack job for now
			int8 wants_irq[3] = {0, 0, 0};

			for(int THIS_NEEDS_CONVERSION_TO_THE_NEW_TIMING_CODE = 0; THIS_NEEDS_CONVERSION_TO_THE_NEW_TIMING_CODE < 0x800; ++THIS_NEEDS_CONVERSION_TO_THE_NEW_TIMING_CODE)
			for(int8 num = 0; num < 3; ++num) {
				if(!timer[num].running)
					continue;

				switch(timer[num].counter_mode) {
				case 0: // event counting
					if(timer[num].counter) {
						--timer[num].counter;
						if(timer[num].counter == 0)
							wants_irq[num] = timer[num].OUT = 1;
					}
					break;
				case 2: // RTC
					--timer[num].counter;
					if(timer[num].counter == 1)
						timer[num].OUT = 0;
					else if(timer[num].counter == 0) {
						wants_irq[num] = timer[num].OUT = 1;
						timer[num].counter = timer[num].initial;
					}
					break;
				case 3: // baud
					timer[num].counter -= 2;
					if(timer[num].OUT) {
						if((timer[num].counter == 0) || (timer[num].counter == (int16)-1)) {
							timer[num].OUT = 0;
							timer[num].counter = timer[num].initial;
						}
					} else
						if((timer[num].counter == 0) || (timer[num].counter == 1)) {
							wants_irq[num] = timer[num].OUT = 1;
							timer[num].counter = timer[num].initial;
						}
					break;
				default:
					plug->Log(plug_persist, LOG_ERROR, L"[PIT] Mode " +
						Piston::String::Render(timer[num].counter_mode) + L" for timer " +
						Piston::String::Render(num) + L" unhandled.");
					ZSSERT(0);
				}
			}

			if(wants_irq[0]) // only timer 0 causes interrupt
				plug_dev->RaiseIRQ(0);
			Piston::System::Thread::Sleep(2);
		}
	}

	int8 Pit::Read8(int16 port) {
		int8 num, ret;

		switch(port) {
		case 0x40:
		case 0x41:
		case 0x42:
			num = port - 0x40;

			ZSSERT(timer[num].rw_disp);
			switch(timer[num].rw_disp) {
			case 0x01: // LSB
				if(timer[num].out_latched) {
					timer[num].out_latched = 0;
					return (int8)timer[num].out_latch;
				} else
					return (int8)timer[num].counter;
			case 0x02: // MSB
				if(timer[num].out_latched) {
					timer[num].out_latched = 0;
					return (int8)(timer[num].out_latch >> 8);
				} else
					return timer[num].counter;
			case 0x03: // both LSB and MSB
				if(timer[num].out_latched) {
					if(!timer[num].out_latch_next_msb) {
						timer[num].out_latch_next_msb = 1;
						return (int8)timer[num].out_latch;
					} else {
						timer[num].out_latched = 0;
						timer[num].out_latch_next_msb = 0;
						return (int8)(timer[num].out_latch >> 8);
					}
				} else {
					if(!timer[num].out_latch_next_msb) {
						timer[num].out_latch_next_msb = 1;
						return (int8)timer[num].counter;
					} else {
						timer[num].out_latch_next_msb = 0;
						return (int8)(timer[num].counter >> 8);
					}
				}
			}
		}
		plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 8-bit read from port 0x" +
			Piston::String::Renderhex(port).PadLeft(4, L'0'));
			return 0xff;
		ZSSERT(0);
	}

	int16 Pit::Read16(int16 port) {
		//plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 16-bit read from port 0x" +
		//	Piston::String::Renderhex(port).PadLeft(4, L'0'));
		//ZSSERT(0);
		ZSSERT(port <= 0x41);
		return Read8(port) + (Read8(port + 1) << 8);
	}

	int32 Pit::Read32(int16 port) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 32-bit read from port 0x" +
			Piston::String::Renderhex(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}

	void Pit::Write8(int16 port, int8 value) {
		int8 num;

		switch(port) {
		case 0x40:
		case 0x41:
		case 0x42:
			num = port - 0x40;

			ZSSERT(timer[num].rw_disp);
			switch(timer[num].rw_disp) {
			case 0x01: // LSB
				timer[num].counter =
					timer[num].initial =
						(timer[num].counter & 0xff00) | value;
				timer[num].running = 1;

				plug->Log(plug_persist, LOG_TRACE, L"[PIT] Timer " + Piston::String::Render(num) +
					L" initial count (LSB) = 0x" + Piston::String::Renderhex(timer[num].initial).PadLeft(4, L'0'));
				break;
			case 0x02: // MSB
				timer[num].counter =
					timer[num].initial =
						(value << 8) | (int8)timer[num].counter;
				timer[num].running = 1;

				plug->Log(plug_persist, LOG_TRACE, L"[PIT] Timer " + Piston::String::Render(num) +
					L" initial count (MSB) = 0x" + Piston::String::Renderhex(timer[num].initial).PadLeft(4, L'0'));
				break;
			case 0x03: // LSB then MSB
				if(!timer[num].in_next_msb) {
					timer[num].initial = (timer[num].counter & 0xff00) | value;
					timer[num].in_next_msb = 1;
				} else {
					timer[num].counter =
						timer[num].initial =
							(value << 8) | (int8)timer[num].initial;
					timer[num].in_next_msb = 0;
					timer[num].running = 1;

					plug->Log(plug_persist, LOG_TRACE, L"[PIT] Timer " + Piston::String::Render(num) +
						L" initial count (16-bit) = 0x" + Piston::String::Renderhex(timer[num].initial).PadLeft(4, L'0'));
				}
			} break;
		case 0x43:
			num = (value & 0xc0) >> 6;
			if(!(value & 0x30)) {
				if((value & 0xc0) != 0xc0) { // latch counter
					num = (value & 0xc0) >> 6;
					if(!timer[num].out_latched) {
						timer[num].out_latched = 1;
						timer[num].out_latch = timer[num].counter;
						timer[num].out_latch_next_msb = 0;
					}
				} else { // read-back
					ZSSERT(0);
				}
			} else { // timer control word
				ZSSERT((value & 0xc) != 0xc);
				if(value & 4) value &= 0xf7; // mask out last modes 6-7

				timer[num].bcd = (value & 1);
				ZSSERT(!timer[num].bcd); // not handled yet
				timer[num].counter_mode = (value & 14) >> 1;
				ZSSERT((timer[num].counter_mode < 4) && (timer[num].counter_mode != 1)); // unhandled modes
				timer[num].rw_disp = (value & 0x30) >> 4;

				timer[num].in_next_msb = 0;
				timer[num].counter = 0;

				plug->Log(plug_persist, LOG_TRACE, L"[PIT] Timer " +
					Piston::String::Render(num) + L" reprogrammed to " +
					(timer[num].bcd ? L"BCD" : L"binary") + L", mode " +
					Piston::String::Render(timer[num].counter_mode) + L", rw_disp " +
					Piston::String::Render(timer[num].rw_disp));
			} break;
		default:
			plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 8-bit write of 0x" +
				Piston::String::Renderhex(value).PadLeft(2, L'0') + L" to port 0x" +
				Piston::String::Renderhex(port).PadLeft(4, L'0'));
			ZSSERT(0);
		}
	}

	void Pit::Write16(int16 port, int16 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 16-bit write of 0x" +
			Piston::String::Renderhex(value).PadLeft(4, L'0') + L" to port 0x" +
			Piston::String::Renderhex(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}

	void Pit::Write32(int16 port, int32 value) {
		plug->Log(plug_persist, LOG_WARNING, L"[PIT] Bad 32-bit write of 0x" +
			Piston::String::Renderhex(value).PadLeft(8, L'0') + L" to port 0x" +
			Piston::String::Renderhex(port).PadLeft(4, L'0'));
		ZSSERT(0);
	}
}}