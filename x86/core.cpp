#include "stdafx.h"
#include "cpu.h"

#include "Config.h"

namespace Tower { namespace X86 {
	SegReg seg_regs[SegRegCount];
	SegReg *const es = &seg_regs[0], *const cs = &seg_regs[1], *const ss = &seg_regs[2];
	SegReg *const ds = &seg_regs[3], *const fs = &seg_regs[4], *const gs = &seg_regs[5];
	SegReg *seg_override;
	const SegReg seg_zero = {0};

	int8 reg_heap[RegisterHeapSize];

	// fix this for endian awareness
	int32 *const eip = (int32 *)reg_heap; int32 *const eflags = eip + 1;
	int32 *const eax = eflags + 1;        int32 *const ecx = eax + 1;
	int32 *const edx = ecx + 1;           int32 *const ebx = edx + 1;
	int32 *const esp = ebx + 1;           int32 *const ebp = esp + 1;
	int32 *const esi = ebp + 1;           int32 *const edi = esi + 1;
	int32 *const cr0 = edi + 1;           int32 *const cr2 = cr0 + 1;
	int32 *const cr3 = cr2 + 1;           int32 *const cr4 = cr3 + 1;

	int16 *const ip = (int16 *)eip;       int16 *const flags = (int16 *)eflags;
	int16 *const ax = (int16 *)eax;       int16 *const cx = (int16 *)ecx;
	int16 *const dx = (int16 *)edx;       int16 *const bx = (int16 *)ebx;
	int16 *const sp = (int16 *)esp;       int16 *const bp = (int16 *)ebp;
	int16 *const si = (int16 *)esi;       int16 *const di = (int16 *)edi;

	int8 *const al = (int8 *)ax;    int8 *const ah = al + 1;
	int8 *const cl = (int8 *)cx;    int8 *const ch = cl + 1;
	int8 *const dl = (int8 *)dx;    int8 *const dh = dl + 1;
	int8 *const bl = (int8 *)bx;    int8 *const bh = bl + 1;

	int8 *const gen_regs_8[8] = {al, cl, dl, bl, ah, ch, dh, bh};
	int16 *const gen_regs_16[8] = {ax, cx, dx, bx, sp, bp, si, di};
	int32 *const gen_regs_32[8] = {eax, ecx, edx, ebx, esp, ebp, esi, edi};

	int8 modrm_byte;

	int16 this_ip;
	int32 this_eip;
	jmp_buf jmp_to_loop;

//	void FillOpcodeTables() {
//		switch(Config::CpuLevel) {
//#ifdef X86_SUPPORT_100
//		case X86_8086:
//			X86_100_FillOpcodeTables();
//			break;
//#endif
//#ifdef X86_SUPPORT_150
//		case X86_186:
//			X86_150_FillOpcodeTables();
//			break;
//#endif
//#ifdef X86_SUPPORT_200
//		case X86_286:
//			X86_200_FillOpcodeTables();
//			break;
//#endif
//#ifdef X86_SUPPORT_300
//		case X86_386:
//			X86_300_FillOpcodeTables();
//			break;
//#endif
//#ifdef X86_SUPPORT_350
//		case X86_486:
//			X86_400_FillOpcodeTables();
//			break;
//#endif
//		default:
//			throw 0; // TODO:error
//		}
//	}
}}