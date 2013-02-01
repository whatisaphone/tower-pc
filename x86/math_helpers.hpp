// all thanks to debug.exe

#if A_O == 1616 // once per processor
namespace Tower { namespace X86 {
	inline int8 Xi__(add8)(int8 op1, int8 op2) {
		int8 res = op1 + op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res < op1                        ? flags_mask_cf : 0) |
			parity_lookup[res]                | // pf
			((res ^ op1 ^ op2) & 0x10)        | // af
			(res                          ? 0 : flags_mask_zf) |
			(res & 0x80)                      | // sf
			((res ^ op1) & (res ^ op2) & 0x80 ? flags_mask_of : 0);
		return res;
	}

	inline int16 Xi__(add16)(int16 op1, int16 op2) {
		int16 res = op1 + op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res < op1                          ? flags_mask_cf : 0) |
			parity_lookup[(int8)res]            | // pf
			((res ^ op1 ^ op2) & 0x10)          | // af
			(res                            ? 0 : flags_mask_zf) |
			(res & 0x8000                       ? flags_mask_sf : 0) |
			((res ^ op1) & (res ^ op2) & 0x8000 ? flags_mask_of : 0);
		return res;
	}

	inline int32 Xi__(add32)(int32 op1, int32 op2) {
		int32 res = op1 + op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res < op1                              ? flags_mask_cf : 0) |
			parity_lookup[(int8)res]                | // pf
			((res ^ op1 ^ op2) & 0x10)              | // af
			(res                                ? 0 : flags_mask_zf) |
			(res & 0x80000000                       ? flags_mask_sf : 0) |
			((res ^ op1) & (res ^ op2) & 0x80000000 ? flags_mask_of : 0);
		return res;
	}

	inline int8 Xi__(adc8)(int8 op1, int8 op2) {
		if(flags_get_cf()) {
			int8 res = Xi__(add8)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(add8)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(add8)(op1, op2);
	}

	inline int16 Xi__(adc16)(int16 op1, int16 op2) {
		if(flags_get_cf()) {
			int16 res = Xi__(add16)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(add16)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(add16)(op1, op2);
	}

	inline int32 Xi__(adc32)(int32 op1, int32 op2) {
		throw 0;
		if(flags_get_cf()) {
			int32 res = Xi__(add32)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(add32)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(add32)(op1, op2);
	}

	inline int8 Xi__(and8)(int8 op1, int8 op2) {
		int8 res = op1 & op2;
		flags_clrOC_testSZP_8(res);
		return res;
	}

	inline int16 Xi__(and16)(int16 op1, int16 op2) {
		int16 res = op1 & op2;
		flags_clrOC_testSZP_16(res);
		return res;
	}

	inline int32 Xi__(and32)(int32 op1, int32 op2) {
		int32 res = op1 & op2;
		flags_clrOC_testSZP_32(res);
		return res;
	}

	inline int8 Xi__(dec8)(int8 op) {
		int8 res = op - 1;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[res] | // pf
			(op & 0xf      ? 0 : flags_mask_af) |
			(res           ? 0 : flags_mask_zf) |
			(res & 0x80)       | // sf
			(op == 0x80        ? flags_mask_of : 0);
		return res;
	}

	inline int16 Xi__(dec16)(int16 op) {
		int16 res = op - 1;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[(int8)res] | // pf
			(op & 0xf            ? 0 : flags_mask_af) |
			(res                 ? 0 : flags_mask_zf) |
			(res & 0x8000            ? flags_mask_sf : 0) |
			(op == 0x8000            ? flags_mask_of : 0);
		return res;
	}

	inline int32 Xi__(dec32)(int32 op) {
		int32 res = op - 1;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[(int8)res] | // pf
			(op & 0xf            ? 0 : flags_mask_af) |
			(res                 ? 0 : flags_mask_zf) |
			(res & 0x80000000        ? flags_mask_sf : 0) |
			(op == 0x80000000        ? flags_mask_of : 0);
		return res;
	}

	inline int8 Xi__(inc8)(int8 op) {
		++op;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[op] | // pf
			(op & 0xf     ? 0 : flags_mask_af) |
			(op           ? 0 : flags_mask_zf) |
			(op & 0x80)       | // sf
			(op == 0x80       ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(inc16)(int16 op) {
		++op;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[(int8)op] | // pf
			(op & 0xf           ? 0 : flags_mask_af) |
			(op                 ? 0 : flags_mask_zf) |
			(op & 0x8000            ? flags_mask_sf : 0) |
			(op == 0x8000           ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(inc32)(int32 op) {
		++op;
		*eflags = *eflags & ~flags_mask_pazso |
			parity_lookup[(int8)op] | // pf
			(op & 0xf           ? 0 : flags_mask_af) |
			(op                 ? 0 : flags_mask_zf) |
			(op & 0x80000000        ? flags_mask_sf : 0) |
			(op == 0x80000000       ? flags_mask_of : 0);
		return op;
	}

	inline int8 Xi__(or8)(int8 op1, int8 op2) {
		int8 res = op1 | op2;
		flags_clrOC_testSZP_8(res);
		return res;
	}

	inline int16 Xi__(or16)(int16 op1, int16 op2) {
		int16 res = op1 | op2;
		flags_clrOC_testSZP_16(res);
		return res;
	}

	inline int32 Xi__(or32)(int32 op1, int32 op2) {
		int32 res = op1 | op2;
		flags_clrOC_testSZP_32(res);
		return res;
	}

	inline int8 Xi__(sub8)(int8 op1, int8 op2) {
		int8 res = op1 - op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res > op1                        ? flags_mask_cf : 0) |
			parity_lookup[res]                | // pf
			((res ^ op1 ^ op2) & 0x10)        | // af
			(res ?                          0 : flags_mask_zf) |
			(res & 0x80)                      | // sf
			((op1 ^ op2) & (op1 ^ res) & 0x80 ? flags_mask_of : 0);
		return res;
	}

	inline int16 Xi__(sub16)(int16 op1, int16 op2) {
		int16 res = op1 - op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res > op1                          ? flags_mask_cf : 0) |
			parity_lookup[(int8)res]            | // pf
			((res ^ op1 ^ op2) & 0x10)          | // af
			(res                            ? 0 : flags_mask_zf) |
			(res & 0x8000                       ? flags_mask_sf : 0) |
			((op1 ^ op2) & (op1 ^ res) & 0x8000 ? flags_mask_of : 0);
		return res;
	}

	inline int32 Xi__(sub32)(int32 op1, int32 op2) {
		int32 res = op1 - op2;
		*eflags = *eflags & ~flags_mask_cpazso |
			(res > op1                              ? flags_mask_cf : 0) |
			parity_lookup[(int8)res]                | // pf
			((res ^ op1 ^ op2) & 0x10)              | // af
			(res                                ? 0 : flags_mask_zf) |
			(res & 0x80000000                       ? flags_mask_sf : 0) |
			((op1 ^ op2) & (op1 ^ res) & 0x80000000 ? flags_mask_of : 0);
		return res;
	}

	inline int8 Xi__(sbb8)(int8 op1, int8 op2) {
		if(flags_get_cf()) {
			int8 res = Xi__(sub8)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(sub8)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(sub8)(op1, op2);
	}

	inline int16 Xi__(sbb16)(int16 op1, int16 op2) {
		if(flags_get_cf()) {
			int16 res = Xi__(sub16)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(sub16)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(sub16)(op1, op2);
	}

	inline int32 Xi__(sbb32)(int32 op1, int32 op2) {
		if(flags_get_cf()) {
			int32 res = Xi__(sub32)(op1, op2);
			int32 cao = *eflags & flags_mask_cao;
			res = Xi__(sub32)(res, 1);
			*eflags |= cao;
			return res;
		} else
			return Xi__(sub32)(op1, op2);
	}

	inline int8 Xi__(xor8)(int8 op1, int8 op2) {
		int8 res = op1 ^ op2;
		flags_clrOC_testSZP_8(res);
		return res;
	}

	inline int16 Xi__(xor16)(int16 op1, int16 op2) {
		int16 res = op1 ^ op2;
		flags_clrOC_testSZP_16(res);
		return res;
	}

	inline int32 Xi__(xor32)(int32 op1, int32 op2) {
		int32 res = op1 ^ op2;
		flags_clrOC_testSZP_32(res);
		return res;
	}

	/***********************************   R O T A T E S   *************************************/

	inline int8 Xi__(rol8)(int8 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		count &= 7;
		op = ((op & (0xff >> count)) << count) |
			((op & (0xff << (8 - count))) >> (8 - count));
		*eflags = *eflags & ~flags_mask_cfof |
			(op & 1)                        | // cf
			((op & 0x80 ? 1 : 0) ^ (op & 1) ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(rol16)(int16 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		count &= 15;
		op = ((op & (0xffff >> count)) << count) |
			((op & (0xffff << (16 - count))) >> (16 - count));
		*eflags = *eflags & ~flags_mask_cfof |
			(op & 1)                          | // cf
			((op & 0x8000 ? 1 : 0) ^ (op & 1) ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(rol32)(int32 op, int8 count) {
		throw 0;
	}

	inline int8 Xi__(ror8)(int8 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		count &= 7;
		op = ((op & (0xff << count)) >> count) |
			((op & (0xff >> (8 - count))) << (8 - count));
		*eflags = *eflags & ~flags_mask_cfof |
			(op & 0x80                ? flags_mask_cf : 0) |
			(parity_lookup[op & 0xc0] ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(ror16)(int16 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		count &= 15;
		op = ((op & (0xffff << count)) >> count) |
			((op & (0xffff >> (16 - count))) << (16 - count));
		*eflags = *eflags & ~flags_mask_cfof |
			(op & 0x8000             ? flags_mask_cf : 0) |
			(parity_lookup[op >> 14] ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(ror32)(int32 op, int8 count) {
		throw 0;
	}

	/******************************   R O T A T E S   &   C F   ********************************/

	inline int8 Xi__(rcl8)(int8 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		if(count >= 9) {count -= 9; if(count >= 9) {count -= 9; if(count >= 9) count -= 9;}}
		int32 new_cf = op & (1 << (8 - count));
		op = ((*eflags & flags_mask_cf) << (count - 1)) |
			((op << count) & (0xff << count)) |
			((op >> (9 - count)) & (0xff >> (9 - count)));
		*eflags = *eflags & ~flags_mask_cfof |
			(new_cf                       ? flags_mask_cf : 0) |
			((op & 0x80 ? 1 : 0) ^ (new_cf ? 1 : 0) ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(rcl16)(int16 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		if(count >= 17) count -= 17;
		int32 new_cf = op & (1 << (16 - count));
		op = ((*eflags & flags_mask_cf) << (count - 1)) |
			((op << count) & (0xffff << count)) |
			((op >> (17 - count)) & (0xffff >> (17 - count)));
		*eflags = *eflags & ~flags_mask_cfof |
			(new_cf                                   ? flags_mask_cf : 0) |
			((op & 0x8000 ? 1 : 0) ^ (new_cf ? 1 : 0) ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(rcl32)(int32 op, int8 count) {
		throw 0;
	}

	inline int8 Xi__(rcr8)(int8 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		if(count >= 9) {count -= 9; if(count >= 9) {count -= 9; if(count >= 9) count -= 9;}}
		int32 new_cf = op & (1 << (count - 1));
		op = ((*eflags & flags_mask_cf) << (8 - count)) |
			((op & (0xff >> (9 - count))) << (9 - count)) |
			((op & (0xff << count)) >> count);
		*eflags = *eflags & ~flags_mask_cfof |
			(new_cf                   ? flags_mask_cf : 0) |
			(parity_lookup[op & 0xc0] ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(rcr16)(int16 op, int8 count) {
#if CPU < X86_286
		if(!count) return op;
#else
		if(!(count & 31)) return op;
#endif
		if(count >= 17) count -= 17;
		int32 new_cf = op & (1 << (count - 1));
		op = ((*eflags & flags_mask_cf) << (16 - count)) |
			((op & (0xffff >> (17 - count))) << (17 - count)) |
			((op & (0xffff << count)) >> count);
		*eflags = *eflags & ~flags_mask_cfof |
			(new_cf                  ? flags_mask_cf : 0) |
			(parity_lookup[op >> 14] ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(rcr32)(int32 op, int8 count) {
		throw 0;
	}

	/**********************************   S H I F T S   *************************************/

	inline int8 Xi__(shl8)(int8 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (8 - count));
		op <<= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                                 ? flags_mask_cf : 0) |
			parity_lookup[op]                       | // pf
			(op                                 ? 0 : flags_mask_zf) |
			(op & 0x80)                             | // sf
			((op & 0x80 ? 1 : 0) ^ (new_cf ? 1 : 0) ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(shl16)(int16 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (16 - count));
		op <<= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                                   ? flags_mask_cf : 0) |
			parity_lookup[(int8)op]                   | // pf
			(op                                   ? 0 : flags_mask_zf) |
			(op & 0x8000                              ? flags_mask_sf : 0) |
			((op & 0x8000 ? 1 : 0) ^ (new_cf ? 1 : 0) ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(shl32)(int32 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (32 - count));
		op <<= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                                       ? flags_mask_cf : 0) |
			parity_lookup[(int8)op]                       | // pf
			(op                                       ? 0 : flags_mask_zf) |
			(op & 0x80000000                              ? flags_mask_sf : 0) |
			((op & 0x80000000 ? 1 : 0) ^ (new_cf ? 1 : 0) ? flags_mask_of : 0);
		return op;
	}

	inline int8 Xi__(shr8)(int8 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (count - 1));
		op >>= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf           ? flags_mask_cf : 0) |
			parity_lookup[op] | // pf
			(op               ? 0 : flags_mask_zf) |
			(op & 0x80)       | // sf
			(op & 0x40        ? flags_mask_of : 0);
		return op;
	}

	inline int16 Xi__(shr16)(int16 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (count - 1));
		op >>= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                 ? flags_mask_cf : 0) |
			parity_lookup[(int8)op] | // pf
			(op                 ? 0 : flags_mask_zf) |
			(op & 0x8000            ? flags_mask_sf : 0) |
			(op & 0x4000            ? flags_mask_of : 0);
		return op;
	}

	inline int32 Xi__(shr32)(int32 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf = op & (1 << (count - 1));
		op >>= count;
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                 ? flags_mask_cf : 0) |
			parity_lookup[(int8)op] | // pf
			(op                 ? 0 : flags_mask_zf) |
			(op & 0x80000000        ? flags_mask_sf : 0) |
			(op & 0x40000000        ? flags_mask_of : 0);
		return op;
	}

	/***************************   S I G N E D   S H I F T S   ******************************/

	inline int8 Xi__(sar8)(int8 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf;
		if(count < 8) {
			new_cf = op & (1 << (count - 1));
			op = (op & 0x80) ?
				(op >> count) | (0xff << (8 - count)) :
				(op >> count);
		} else {
			new_cf = (op & 0x80);
			op = new_cf ? (int8)-1 : 0;
		}

		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf           ? flags_mask_cf : 0) |
			parity_lookup[op] | // pf
			(op           ? 0 : flags_mask_zf) |
			(op & 0x80);        // sf
		return op;
	}

	inline int16 Xi__(sar16)(int16 op, int8 count) {
#if CPU >= X86_286
		count &= 31;
#endif
		if(!count) return op;
		int32 new_cf;
		if(count < 16) {
			new_cf = op & (1 << (count - 1));
			op = (op & 0x8000) ?
				(op >> count) | (0xffff << (16 - count)) :
				(op >> count);
		} else {
			new_cf = (op & 0x8000);
			op = new_cf ? (int16)-1 : 0;
		}
		*eflags = *eflags & ~flags_mask_cpazso |
			(new_cf                 ? flags_mask_cf : 0) |
			parity_lookup[(int8)op] | // pf
			(op                 ? 0 : flags_mask_zf) |
			(op & 0x8000            ? flags_mask_sf : 0);
		return op;
	}

	inline int32 Xi__(sar32)(int32 op, int8 count) {
		throw 0;
	}
}}
#endif

#ifdef X86_ONCE
	#define i__adc8 Xi__(adc8)
	#define i__adc16 Xi__(adc16)
	#define i__adc32 Xi__(adc32)
	#define i__add8 Xi__(add8)
	#define i__add16 Xi__(add16)
	#define i__add32 Xi__(add32)
	#define i__and8 Xi__(and8)
	#define i__and16 Xi__(and16)
	#define i__and32 Xi__(and32)
	#define i__dec8 Xi__(dec8)
	#define i__dec16 Xi__(dec16)
	#define i__dec32 Xi__(dec32)
	#define i__inc8 Xi__(inc8)
	#define i__inc16 Xi__(inc16)
	#define i__inc32 Xi__(inc32)
	#define i__or8 Xi__(or8)
	#define i__or16 Xi__(or16)
	#define i__or32 Xi__(or32)
	#define i__sbb8 Xi__(sbb8)
	#define i__sbb16 Xi__(sbb16)
	#define i__sbb32 Xi__(sbb32)
	#define i__sub8 Xi__(sub8)
	#define i__sub16 Xi__(sub16)
	#define i__sub32 Xi__(sub32)
	#define i__xor8 Xi__(xor8)
	#define i__xor16 Xi__(xor16)
	#define i__xor32 Xi__(xor32)
	#define i__rol8 Xi__(rol8)
	#define i__rol16 Xi__(rol16)
	#define i__rol32 Xi__(rol32)
	#define i__ror8 Xi__(ror8)
	#define i__ror16 Xi__(ror16)
	#define i__ror32 Xi__(ror32)
	#define i__rcl8 Xi__(rcl8)
	#define i__rcl16 Xi__(rcl16)
	#define i__rcl32 Xi__(rcl32)
	#define i__rcr8 Xi__(rcr8)
	#define i__rcr16 Xi__(rcr16)
	#define i__rcr32 Xi__(rcr32)
	#define i__shl8 Xi__(shl8)
	#define i__shl16 Xi__(shl16)
	#define i__shl32 Xi__(shl32)
	#define i__shr8 Xi__(shr8)
	#define i__shr16 Xi__(shr16)
	#define i__shr32 Xi__(shr32)
	#define i__sar8 Xi__(sar8)
	#define i__sar16 Xi__(sar16)
	#define i__sar32 Xi__(sar32)

	#define i__adcOP CONCAT(Xi__(adc), OPSIZE)
	#define i__addOP CONCAT(Xi__(add), OPSIZE)
	#define i__andOP CONCAT(Xi__(and), OPSIZE)
	#define i__decOP CONCAT(Xi__(dec), OPSIZE)
	#define i__incOP CONCAT(Xi__(inc), OPSIZE)
	#define i__orOP CONCAT(Xi__(or), OPSIZE)
	#define i__sbbOP CONCAT(Xi__(sbb), OPSIZE)
	#define i__subOP CONCAT(Xi__(sub), OPSIZE)
	#define i__xorOP CONCAT(Xi__(xor), OPSIZE)
	#define i__rolOP CONCAT(Xi__(rol), OPSIZE)
	#define i__rorOP CONCAT(Xi__(ror), OPSIZE)
	#define i__rclOP CONCAT(Xi__(rcl), OPSIZE)
	#define i__rcrOP CONCAT(Xi__(rcr), OPSIZE)
	#define i__shlOP CONCAT(Xi__(shl), OPSIZE)
	#define i__shrOP CONCAT(Xi__(shr), OPSIZE)
	#define i__sarOP CONCAT(Xi__(sar), OPSIZE)
#endif