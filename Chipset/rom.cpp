#include "stdafx.h"

namespace Tower { namespace Chipset {
	int8 *RamBase;

	int8 TOWER_CC RomRead8(int32 addr) {return *(int8 *)(RamBase + addr);}
	int16 TOWER_CC RomRead16(int32 addr) {return *(int16 *)(RamBase + addr);}
	int32 TOWER_CC RomRead32(int32 addr) {return *(int32 *)(RamBase + addr);}
	void TOWER_CC RomWrite8(int32 addr, int8 data) {throw 0;}
	void TOWER_CC RomWrite16(int32 addr, int16 data) {throw 0;}
	void TOWER_CC RomWrite32(int32 addr, int32 data) {throw 0;}
}}