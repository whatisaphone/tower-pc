#pragma once

#include "zildjohn01.h"
#include "..\TowerGlobals.h"

namespace Tower { namespace Chipset {
	extern const PlugInitData *plug;
	extern const DevInitData *plug_dev;
	extern const PicInitData *plug_pic;
	extern const void *plug_persist;
	extern const void *plug_status_num;
	extern const void *plug_status_caps;
	extern const void *plug_status_scrl;

	extern int8 *RamBase;
	int8 TOWER_CC RomRead8(int32 addr);
	int16 TOWER_CC RomRead16(int32 addr);
	int32 TOWER_CC RomRead32(int32 addr);
	void TOWER_CC RomWrite8(int32 addr, int8 data);
	void TOWER_CC RomWrite16(int32 addr, int16 data);
	void TOWER_CC RomWrite32(int32 addr, int32 data);
}}