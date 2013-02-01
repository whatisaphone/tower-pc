#pragma once

namespace Tower { namespace Chipset {
	TOWER_EXPORT int8 TOWER_CC tower_pic_INTA();
	TOWER_EXPORT void tower_pic_RaiseIRQ(int8 irq);

	class Pic {
		friend int8 TOWER_CC tower_pic_INTA();
		friend void tower_pic_RaiseIRQ(int8 irq);
	private:
		Pic();
		Pic(const Pic &copy);
		Pic &operator=(const Pic &copy);

		static struct PicChip {
			int8 init_stage;
			int8 highest_priority;
			int8 irr; // int request reg
			int8 isr; // in-service reg

			// icw 1
			int8 needs_icw4 : 1;
			int8 /*padding*/ : 1;
			int8 only_pic : 1;
			int8 call_addr_interval_4 : 1;
			int8 level_triggered : 1;
			int8 msc_vect : 3;

			int8 vector_offset; // icw2

			int8 icw3; // master/slaves

			// icw 4
			int8 mode8086 : 1;
			int8 auto_eoi : 1;
			int8 buf_ismaster : 1;
			int8 buf_enabled : 1;
			int8 special_nested : 1;
			int8 /*padding*/ : 3;

			int8 mask; // ocw1

			// ocw2
			int8 rotate_on_auto_eoi : 1;

			// ocw3
			int8 next_read_isr : 1;
		} m, s;

		static void CheckPendingInts(PicChip &chip);

	public:
		static int8 TOWER_CC Read8(int16 port);
		static int16 TOWER_CC Read16(int16 port);
		static int32 TOWER_CC Read32(int16 port);
		static void TOWER_CC Write8(int16 port, int8 value);
		static void TOWER_CC Write16(int16 port, int16 value);
		static void TOWER_CC Write32(int16 port, int32 value);
	};
}}