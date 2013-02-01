#pragma once
#include "stdafx.h"

#include <setjmp.h>
#include "Piston\System\Event.h"

namespace Tower { namespace X86 {
	struct SegReg {
		int16 selector;
		int16 access; // (?)
		int32 base;
		int32 limit;
	};

	const int SegRegCount = 6;
	const int RegisterHeapSize = 14 * sizeof(int32);

	extern SegReg seg_regs[SegRegCount];
	extern SegReg *const es, *const cs, *const ss, *const ds, *const fs, *const gs;
	extern SegReg *seg_override;
	extern const SegReg seg_zero;

	extern int8 *const al, *const cl, *const dl, *const bl;
	extern int8 *const ah, *const ch, *const dh, *const bh;
	extern int16 *const ax, *const cx, *const dx, *const bx;
	extern int16 *const sp, *const bp, *const si, *const di;
	extern int16 *const ip; extern int16 *const flags;
	extern int32 *const eax, *const ecx, *const edx, *const ebx;
	extern int32 *const esp, *const ebp, *const esi, *const edi;
	extern int32 *const eip, *const eflags;
	extern int32 *const cr0, *const cr2, *const cr3, *const cr4;

	extern int8 *const gen_regs_8[8];
	extern int16 *const gen_regs_16[8];
	extern int32 *const gen_regs_32[8];

	#include "cpu_flags.h"
	extern int8 modrm_byte;

	extern int16 this_ip;
	extern int32 this_eip;
	extern jmp_buf jmp_to_loop; // used with longjmp() and exceptions

	extern unsigned int AsyncEventCount;
	extern unsigned int TowerWantsPause, TowerWantsQuit;
	extern unsigned int INTPIN;
	extern Piston::System::Event *CpuPaused, *CanContinueRunning;

	void FillOpcodeTables();

	#define X86_INCLUDE_MASTER "cpu_real.h"
		#include "the_include_master.h"
}}