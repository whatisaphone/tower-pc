#pragma once

#include "zildjohn01.h"
#include "..\TowerGlobals.h"

namespace Tower { namespace Hle {
	extern const PlugInitData *plug;
	extern const DevInitData *plug_dev;
	extern const void *plug_persist;
	extern const void *plug_status_a;
	extern const void *plug_status_c;
	extern const void *plug_status_d;

	extern int32 regs[9];

	extern int32 *const eax, *const ecx, *const edx, *const ebx;
	extern int32 *const esi, *const edi, *const es, *const ds, *const eflags;

	extern int16 *const ax, *const cx, *const dx, *const bx;
	extern int16 *const si, *const di, *const flags;

	extern int8 *const al, *const cl, *const dl, *const bl;
	extern int8 *const ah, *const ch, *const dh, *const bh;

	static const int32 flags_mask_cf = (1 << 0);
	static const int32 flags_mask_pf = (1 << 2);
	static const int32 flags_mask_af = (1 << 4);
	static const int32 flags_mask_zf = (1 << 6);
	static const int32 flags_mask_sf = (1 << 7);
	static const int32 flags_mask_tf = (1 << 8);
	static const int32 flags_mask_if = (1 << 9);
	static const int32 flags_mask_df = (1 << 10);
	static const int32 flags_mask_of = (1 << 11);
}}