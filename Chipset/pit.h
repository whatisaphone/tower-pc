#pragma once
#include "stdafx.h"

#include "Piston\Delegate.h"

namespace Tower { namespace Chipset {
	class Pit {
	private:
		Pit();
		Pit(const Pit &copy);
		Pit &operator=(const Pit &copy);

		static Piston::Thread<void()> *Thread;

		static struct Timer {
			int8 bcd : 1;
			int8 counter_mode : 3;
			int8 rw_disp : 2;

			int16 counter;
			int16 out_latch;
			int16 initial;
			int8 out_latched : 1;
			int8 out_latch_next_msb : 1;
			int8 in_next_msb : 1;
			int8 OUT : 1;
			int8 running : 1;
		} timer[3];

		static void PitThread();

	public:
		static int8 TOWER_CC Read8(int16 port);
		static int16 TOWER_CC Read16(int16 port);
		static int32 TOWER_CC Read32(int16 port);
		static void TOWER_CC Write8(int16 port, int8 value);
		static void TOWER_CC Write16(int16 port, int16 value);
		static void TOWER_CC Write32(int16 port, int32 value);

		static int32 Init();
		static int32 Run();
		static void Pause();
		static void Uninit();
	};
}}