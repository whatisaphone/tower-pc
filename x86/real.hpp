#include "real_a_o.hpp"
#include "real_memory.hpp"
#include "real_helpers.hpp"
#include "real_modrm.hpp"
#include "math_helpers.hpp"

#ifdef _DEBUG
#define BREAKPOINT(s,o) if((cs->selector == (s)) && (PICK_CPUBITS(*ip, *eip) == (o))) __asm {int 3};
#define IN_ROM ((cs->selector & 0xc000) == 0xc000)
#define BP_ANCHOR (*bp=*bp)
#endif

namespace Tower { namespace X86 {
#if (CPU >= X86_386) && (A_O == 1616) // once per 32-bit processor
	void X_(real1616_i_rep)();
	void X_(real3216_i_rep)();
	void X_(real1632_i_rep)();
	void X_(real3232_i_rep)();
	void X_(real1616_i_repnz)();
	void X_(real3216_i_repnz)();
	void X_(real1632_i_repnz)();
	void X_(real3232_i_repnz)();
#endif

#ifdef X86_ONCE // once ever
	void (*AO_(Ops)[256])();
  #if CPU >= X86_286
	void (*AO_(Ops_0f)[256])();
  #endif
#endif

	void XAO_(Step)() {
		static int32 instr_count;
		if(++instr_count % 30000 == 0) plug_cpu->TimePassed(1);

#ifdef _DEBUG
		const int32 count = 500;
		static int32 hist[count];
		//static int32 hist_di[count];
		if(!IN_ROM) {
			for(int i = count - 1; i > 0; --i) {
				hist[i] = hist[i - 1];
				//hist_di[i] = hist_di[i - 1];
			}
			hist[0] = (cs->selector << 16) | *ip;
			//hist_di[0] = *di;
		}

		// standard breakpoint:
		//BREAKPOINT(0x1859, 0x20c); // bochs seg == 0xd98?
		BREAKPOINT(0x8000, 0x10d);

		// string breakpoint:
		ZSSERT((mem_read16(*ds, *si) != *(int32 *)"C:") ||
			(mem_read16(*ds, *si + 2) != *(int32 *)"\W") ||
			(mem_read16(*ds, *si + 4) != *(int32 *)"IN") ||
			(mem_read16(*ds, *si + 6) != *(int32 *)"DO"));
		ZSSERT((mem_read16(*es, *di) != *(int32 *)"C:") ||
			(mem_read16(*es, *di + 2) != *(int32 *)"\W") ||
			(mem_read16(*es, *di + 4) != *(int32 *)"IN") ||
			(mem_read16(*es, *di + 6) != *(int32 *)"DO"));

		// physical memory breakpoint:
		//static int16 mold;
		//ZSSERT(instr_count < 2 || plug->MemRead16(0x9c525) == mold);
		//mold = plug->MemRead16(0x9c525);

		// single step:
		if(!IN_ROM)
			BP_ANCHOR;
#endif

		seg_override = 0;
		PICK_ADSIZE(this_ip = *ip, this_eip = *eip);

		int8 opcode = mem_read8_CSIP();
		AO_(Ops)[opcode]();
	}

	inline void XAO_(StepPrefix)() {
		// TODO: the limit of 15 bytes on instruction length for 386 and on,
		// *possibly* 286 and 186 i don't know...
		// but don't put it here. put it in MemReadX_CSIP()
		AO_(Ops)[mem_read8_CSIP()]();
	}

/*00*/	void XAOi_(add_rm8_r8)() {
		modrm_decode();
		ZSSERT(modrm_byte != 0x00); // this could be bad
		modrm_write_rm8(i__add8(modrm_read_rm8(), modrm_read_r8()));
	}

/*01*/	void XAOi_(add_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__addOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*02*/	void XAOi_(add_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__add8(modrm_read_r8(), modrm_read_rm8()));
	}

/*03*/	void XAOi_(add_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__addOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*04*/	void XAOi_(add_al_i8)() {
		*al = i__add8(*al, mem_read8_CSIP());
	}

/*05*/	void XAOi_(add_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__addOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*06*/	void XAOi_(push_es)() {
		i__pushOP(es->selector);
	}

/*07*/	void XAOi_(pop_es)() {
		es->selector = i__popOP();
	}

/*08*/	void XAOi_(or_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__or8(modrm_read_rm8(), modrm_read_r8()));
	}

/*09*/	void XAOi_(or_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__orOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*0a*/	void XAOi_(or_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__or8(modrm_read_r8(), modrm_read_rm8()));
	}

/*0b*/	void XAOi_(or_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__orOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*0c*/	void XAOi_(or_al_i8)() {
		*al = i__or8(*al, mem_read8_CSIP());
	}

/*0d*/	void XAOi_(or_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__orOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*0e*/	void XAOi_(push_cs)() {
		i__pushOP(cs->selector);
	}

/*0f*/	void XAOi_(pop_cs)() {
	#if CPU == X86_8086
		cs->selector = i__popOP();
	#elif CPU == X86_186
		ZSSERT(0);
		//XAO_(raiseUD)();
		XAO_(needs286)();
	#else
		int8 next = mem_read8_CSIP();
		AO_(Ops_0f)[next]();
	#endif
	}

/*10*/	void XAOi_(adc_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__adc8(modrm_read_rm8(), modrm_read_r8()));
	}

/*11*/	void XAOi_(adc_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__adcOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*12*/	void XAOi_(adc_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__adc8(modrm_read_r8(), modrm_read_rm8()));
	}

/*13*/	void XAOi_(adc_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__adcOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*14*/	void XAOi_(adc_al_i8)() {
		*al = i__adc8(*al, mem_read8_CSIP());
	}

/*15*/	void XAOi_(adc_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__adcOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*16*/	void XAOi_(push_ss)() {
		i__pushOP(ss->selector);
	}

/*17*/	void XAOi_(pop_ss)() {
		ss->selector = i__popOP();
	}

/*18*/	void XAOi_(sbb_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__sbb8(modrm_read_rm8(), modrm_read_r8()));
	}

/*19*/	void XAOi_(sbb_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__sbbOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*1a*/	void XAOi_(sbb_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__sbb8(modrm_read_r8(), modrm_read_rm8()));
	}

/*1b*/	void XAOi_(sbb_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__sbbOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*1c*/	void XAOi_(sbb_al_i8)() {
		*al = i__sbb8(*al, mem_read8_CSIP());
	}

/*1d*/	void XAOi_(sbb_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__sbbOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*1e*/	void XAOi_(push_ds)() {
		i__pushOP(ds->selector);
	}

/*1f*/	void XAOi_(pop_ds)() {
		ds->selector = i__popOP();
	}

/*20*/	void XAOi_(and_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__and8(modrm_read_rm8(), modrm_read_r8()));
	}

/*21*/	void XAOi_(and_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__andOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*22*/	void XAOi_(and_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__and8(modrm_read_r8(), modrm_read_rm8()));
	}

/*23*/	void XAOi_(and_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__andOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*24*/	void XAOi_(and_al_i8)() {
		*al = i__and8(*al, mem_read8_CSIP());
	}

/*25*/	void XAOi_(and_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__andOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*26*/	void XAOi_(pre_es)() {
		if(seg_override)
			throw 0; // TODO: what happens here? with multiple seg prefixes?
		seg_override = es;
		XAO_(StepPrefix)();
	}

/*27*/	void XAOi_(daa)() {
		if((*al & 0xf) > 9 || flags_get_af()) {
			*al += 6;
			if(*al < 6)
				flags_set_cf();
			flags_set_af();
		}

		if(*al > 0x9f || flags_get_cf()) {
			*al += 0x60;
			flags_set_cf();
		}

		PICK_CPUBITS(*flags, *eflags) = PICK_CPUBITS(*flags, *eflags) & ~flags_mask_pzs |
			parity_lookup[*al] | // pf
			(*al           ? 0 : flags_mask_zf) |
			(*al & 0x80);        // sf
	}

/*28*/	void XAOi_(sub_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__sub8(modrm_read_rm8(), modrm_read_r8()));
	}

/*29*/	void XAOi_(sub_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__subOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*2a*/	void XAOi_(sub_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__sub8(modrm_read_r8(), modrm_read_rm8()));
	}

/*2b*/	void XAOi_(sub_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__subOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*2c*/	void XAOi_(sub_al_i8)() {
		*al = i__sub8(*al, mem_read8_CSIP());
	}

/*2d*/	void XAOi_(sub_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__subOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*2e*/	void XAOi_(pre_cs)() {
		if(seg_override)
			throw 0; // TODO: what happens here? with multiple seg prefixes?
		seg_override = cs;
		XAO_(StepPrefix)();
	}

/*2f*/	void XAOi_(das)() {
		// need to implement
		plug->Log(plug_persist, LOG_FATAL, L"unimplemented opcode: 2f (das)");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/*30*/	void XAOi_(xor_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(i__xor8(modrm_read_rm8(), modrm_read_r8()));
	}

/*31*/	void XAOi_(xor_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(i__xorOP(modrm_read_rmOP(), modrm_read_rOP()));
	}

/*32*/	void XAOi_(xor_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(i__xor8(modrm_read_r8(), modrm_read_rm8()));
	}

/*33*/	void XAOi_(xor_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(i__xorOP(modrm_read_rOP(), modrm_read_rmOP()));
	}

/*34*/	void XAOi_(xor_al_i8)() {
		*al = i__xor8(*al, mem_read8_CSIP());
	}

/*35*/	void XAOi_(xor_rax_iOP)() {
		PICK_OPSIZE(*ax, *eax) = i__xorOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*36*/	void XAOi_(pre_ss)() {
		if(seg_override)
			throw 0; // TODO: what happens here? with multiple seg prefixes?
		seg_override = ss;
		XAO_(StepPrefix)();
	}

/*37*/	void XAOi_(aaa)() {
		// need to implement
		plug->Log(plug_persist, LOG_FATAL, L"unimplemented opcode: 37 (aaa)");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/*38*/	void XAOi_(cmp_rm8_r8)() {
		modrm_decode();
		i__sub8(modrm_read_rm8(), modrm_read_r8());
	}

/*39*/	void XAOi_(cmp_rmOP_rOP)() {
		modrm_decode();
		i__subOP(modrm_read_rmOP(), modrm_read_rOP());
	}

/*3a*/	void XAOi_(cmp_r8_rm8)() {
		modrm_decode();
		i__sub8(modrm_read_r8(), modrm_read_rm8());
	}

/*3b*/	void XAOi_(cmp_rOP_rmOP)() {
		modrm_decode();
		i__subOP(modrm_read_rOP(), modrm_read_rmOP());
	}

/*3c*/	void XAOi_(cmp_al_i8)() {
		i__sub8(*al, mem_read8_CSIP());
	}

/*3d*/	void XAOi_(cmp_rax_iOP)() {
		i__subOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*3e*/	void XAOi_(pre_ds)() {
		if(seg_override)
			throw 0; // TODO: what happens here? with multiple seg prefixes?
		seg_override = ds;
		XAO_(StepPrefix)();
	}

/*3f*/	void XAOi_(aas)() {
		*al &= 0xf;
		if(*al > 9 || flags_get_af()) {
			*al = (*al - 6) & 0xf;
			--*ah;
			PICK_CPUBITS(*flags, *eflags) |= (flags_mask_cf | flags_mask_af);
		} else
			PICK_CPUBITS(*flags, *eflags) &= ~(flags_mask_cf | flags_mask_af);
	}

/*40*/	void XAOi_(inc_rax)() {PICK_OPSIZE(*ax, *eax) = i__incOP(PICK_OPSIZE(*ax, *eax));}
/*41*/	void XAOi_(inc_rcx)() {PICK_OPSIZE(*cx, *ecx) = i__incOP(PICK_OPSIZE(*cx, *ecx));}
/*42*/	void XAOi_(inc_rdx)() {PICK_OPSIZE(*dx, *edx) = i__incOP(PICK_OPSIZE(*dx, *edx));}
/*43*/	void XAOi_(inc_rbx)() {PICK_OPSIZE(*bx, *ebx) = i__incOP(PICK_OPSIZE(*bx, *ebx));}
/*44*/	void XAOi_(inc_rsp)() {ZSSERT(cs->selector == 0xc000); PICK_OPSIZE(*sp, *esp) = i__incOP(PICK_OPSIZE(*sp, *esp));}
/*45*/	void XAOi_(inc_rbp)() {PICK_OPSIZE(*bp, *ebp) = i__incOP(PICK_OPSIZE(*bp, *ebp));}
/*46*/	void XAOi_(inc_rsi)() {PICK_OPSIZE(*si, *esi) = i__incOP(PICK_OPSIZE(*si, *esi));}
/*47*/	void XAOi_(inc_rdi)() {PICK_OPSIZE(*di, *edi) = i__incOP(PICK_OPSIZE(*di, *edi));}
/*48*/	void XAOi_(dec_rax)() {PICK_OPSIZE(*ax, *eax) = i__decOP(PICK_OPSIZE(*ax, *eax));}
/*49*/	void XAOi_(dec_rcx)() {PICK_OPSIZE(*cx, *ecx) = i__decOP(PICK_OPSIZE(*cx, *ecx));}
/*4a*/	void XAOi_(dec_rdx)() {PICK_OPSIZE(*dx, *edx) = i__decOP(PICK_OPSIZE(*dx, *edx));}
/*4b*/	void XAOi_(dec_rbx)() {PICK_OPSIZE(*bx, *ebx) = i__decOP(PICK_OPSIZE(*bx, *ebx));}
/*4c*/	void XAOi_(dec_rsp)() {PICK_OPSIZE(*sp, *esp) = i__decOP(PICK_OPSIZE(*sp, *esp));}
/*4d*/	void XAOi_(dec_rbp)() {PICK_OPSIZE(*bp, *ebp) = i__decOP(PICK_OPSIZE(*bp, *ebp));}
/*4e*/	void XAOi_(dec_rsi)() {PICK_OPSIZE(*si, *esi) = i__decOP(PICK_OPSIZE(*si, *esi));}
/*4f*/	void XAOi_(dec_rdi)() {PICK_OPSIZE(*di, *edi) = i__decOP(PICK_OPSIZE(*di, *edi));}

/*50*/	void XAOi_(push_rax)() {i__pushOP(PICK_OPSIZE(*ax, *eax));}
/*51*/	void XAOi_(push_rcx)() {i__pushOP(PICK_OPSIZE(*cx, *ecx));}
/*52*/	void XAOi_(push_rdx)() {i__pushOP(PICK_OPSIZE(*dx, *edx));}
/*53*/	void XAOi_(push_rbx)() {i__pushOP(PICK_OPSIZE(*bx, *ebx));}
#if CPU < X86_286
/*54*/	void XAOi_(push_rsp)() {i__pushOP(PICK_OPSIZE(*sp, *esp) - PICK_OPSIZE(2, 4));}
#else
/*54*/	void XAOi_(push_rsp)() {i__pushOP(PICK_OPSIZE(*sp, *esp));}
#endif
/*55*/	void XAOi_(push_rbp)() {i__pushOP(PICK_OPSIZE(*bp, *ebp));}
/*56*/	void XAOi_(push_rsi)() {i__pushOP(PICK_OPSIZE(*si, *esi));}
/*57*/	void XAOi_(push_rdi)() {i__pushOP(PICK_OPSIZE(*di, *edi));}
/*58*/	void XAOi_(pop_rax)() {PICK_OPSIZE(*ax, *eax) = i__popOP();}
/*59*/	void XAOi_(pop_rcx)() {PICK_OPSIZE(*cx, *ecx) = i__popOP();}
/*5a*/	void XAOi_(pop_rdx)() {PICK_OPSIZE(*dx, *edx) = i__popOP();}
/*5b*/	void XAOi_(pop_rbx)() {PICK_OPSIZE(*bx, *ebx) = i__popOP();}
/*5c*/	void XAOi_(pop_rsp)() {PICK_OPSIZE(*sp, *esp) = i__popOP();}
/*5d*/	void XAOi_(pop_rbp)() {PICK_OPSIZE(*bp, *ebp) = i__popOP();}
/*5e*/	void XAOi_(pop_rsi)() {PICK_OPSIZE(*si, *esi) = i__popOP();}
/*5f*/	void XAOi_(pop_rdi)() {PICK_OPSIZE(*di, *edi) = i__popOP();}

/*60*/	void XAOi_(pushav)() {
		ZSSERT(CPU >= X86_186);
		i__pushOP(PICK_OPSIZE(*ax, *eax));
		i__pushOP(PICK_OPSIZE(*cx, *ecx));
		i__pushOP(PICK_OPSIZE(*dx, *edx));
		i__pushOP(PICK_OPSIZE(*bx, *ebx));
		i__pushOP(PICK_OPSIZE(*sp + 8, *esp + 16)); // sp's value at start of instruction
		i__pushOP(PICK_OPSIZE(*bp, *ebp));
		i__pushOP(PICK_OPSIZE(*si, *esi));
		i__pushOP(PICK_OPSIZE(*di, *edi));
	}

/*61*/	void XAOi_(popav)() {
		ZSSERT(CPU >= X86_186);
		PICK_OPSIZE(*di, *edi) = i__popOP();
		PICK_OPSIZE(*si, *esi) = i__popOP();
		PICK_OPSIZE(*bp, *ebp) = i__popOP();
		                         i__popOP(); // originally rsp; discard.
		PICK_OPSIZE(*bx, *ebx) = i__popOP();
		PICK_OPSIZE(*dx, *edx) = i__popOP();
		PICK_OPSIZE(*cx, *ecx) = i__popOP();
		PICK_OPSIZE(*ax, *eax) = i__popOP();
	}

/*62*/	void XAOi_(arpl_rm16_r16)() {
		ZSSERT(CPU >= X86_286);
		ZSSERT(0);
	}

/*66*/	void XAOi_(pre_opsize)() {
		ZSSERT(CPU >= X86_386);
#if CPU >= X86_386
		CONCAT(PICK_ADSIZE(X_(real16), X_(real32)), PICK_OPSIZE(32_StepPrefix, 16_StepPrefix))();
#endif
}

/*67*/	void XAOi_(pre_adsize)() {
		ZSSERT(CPU >= X86_386);
#if CPU >= X86_386
		CONCAT(PICK_ADSIZE(X_(real32), X_(real16)), PICK_OPSIZE(16_StepPrefix, 32_StepPrefix))();
#endif
}

/*68*/	void XAOi_(push_iOP)() {
		ZSSERT(CPU >= X86_186);
		i__pushOP(mem_readOP_CSIP());
	}

/*69*/	void XAOi_(imul_rOP_rmOP_iOP)() {
		ZSSERT(CPU >= X86_186);
		ZSSERT(OPSIZE == 16); // test 32-bit
		modrm_decode();
		PICK_OPSIZE(sint32, sint64) res = (sintOP)modrm_read_rmOP() * (sintOP)mem_readOP_CSIP();
		modrm_write_rOP((intOP)res);
		if(res != (sintOP)res)
			PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
		else
			PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
	}

/*6a*/	void XAOi_(push_si8)() {
		ZSSERT(CPU >= X86_186);
		i__pushOP((sint8)mem_read8_CSIP());
	}

/*6b*/	void XAOi_(imul_rOP_rmOP_si8)() {
		ZSSERT(CPU >= X86_186);
		ZSSERT(OPSIZE == 16); // need to test 32-bit
		modrm_decode();
		PICK_OPSIZE(sint32, sint64) res = (sintOP)modrm_read_rmOP() * (sint8)mem_read8_CSIP();
		modrm_write_rOP((intOP)res);
		if(res != (sintOP)res)
			PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
		else
			PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
	}

/*70*/	void XAOi_(jo_rel8)() {i__jcc_rel8(flags_get_of(), mem_read8_CSIP());}
/*71*/	void XAOi_(jno_rel8)() {i__jcc_rel8(!flags_get_of(), mem_read8_CSIP());}
/*72*/	void XAOi_(jc_rel8)() {i__jcc_rel8(flags_get_cf(), mem_read8_CSIP());}
/*73*/	void XAOi_(jnc_rel8)() {i__jcc_rel8(!flags_get_cf(), mem_read8_CSIP());}
/*74*/	void XAOi_(jz_rel8)() {i__jcc_rel8(flags_get_zf(), mem_read8_CSIP());}
/*75*/	void XAOi_(jnz_rel8)() {i__jcc_rel8(!flags_get_zf(), mem_read8_CSIP());}
/*76*/	void XAOi_(jbe_rel8)() {i__jcc_rel8(flags_get_cf() || flags_get_zf(), mem_read8_CSIP());}
/*77*/	void XAOi_(jnbe_rel8)() {i__jcc_rel8(!flags_get_cf() && !flags_get_zf(), mem_read8_CSIP());}
/*78*/	void XAOi_(js_rel8)() {i__jcc_rel8(flags_get_sf(), mem_read8_CSIP());}
/*79*/	void XAOi_(jns_rel8)() {i__jcc_rel8(!flags_get_sf(), mem_read8_CSIP());}
/*7a*/	void XAOi_(jp_rel8)() {i__jcc_rel8(flags_get_pf(), mem_read8_CSIP());}
/*7b*/	void XAOi_(jnp_rel8)() {ZSSERT(0); i__jcc_rel8(!flags_get_pf(), mem_read8_CSIP());}
/*7c*/	void XAOi_(jl_rel8)() {i__jcc_rel8(flags_get_sf() != flags_get_of(), mem_read8_CSIP());}
/*7d*/	void XAOi_(jnl_rel8)() {i__jcc_rel8(flags_get_sf() == flags_get_of(), mem_read8_CSIP());}
/*7e*/	void XAOi_(jle_rel8)() {i__jcc_rel8(flags_get_zf() || (flags_get_sf() != flags_get_of()), mem_read8_CSIP());}
/*7f*/	void XAOi_(jnle_rel8)() {i__jcc_rel8(!flags_get_zf() && (flags_get_sf() == flags_get_of()), mem_read8_CSIP());}

/*80*/	void XAOi_(group80_rm8_i8)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rm8(i__add8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_1: modrm_write_rm8(i__or8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_2: modrm_write_rm8(i__adc8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_3: ZSSERT(cs->selector == 0xc000); modrm_write_rm8(i__sbb8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_4: modrm_write_rm8(i__and8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_5: modrm_write_rm8(i__sub8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_6: modrm_write_rm8(i__xor8(modrm_read_rm8(), mem_read8_CSIP())); return;
		default    : i__sub8(modrm_read_rm8(), mem_read8_CSIP()); return;
		MRM_END_SWITCH_SLASH
	}

/*81*/	void XAOi_(group81_rmOP_iOP)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rmOP(i__addOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_1: modrm_write_rmOP(i__orOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_2: modrm_write_rmOP(i__adcOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_3: throw 0; modrm_write_rmOP(i__sbbOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_4: modrm_write_rmOP(i__andOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_5: modrm_write_rmOP(i__subOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		MRM_SLASH_6: modrm_write_rmOP(i__xorOP(modrm_read_rmOP(), mem_readOP_CSIP())); return;
		default    : i__subOP(modrm_read_rmOP(), mem_readOP_CSIP()); return;
		MRM_END_SWITCH_SLASH
	}

/*83*/	void XAOi_(group83_rmOP_si8)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rmOP(i__addOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_1: modrm_write_rmOP(i__orOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_2: modrm_write_rmOP(i__adcOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_3: modrm_write_rmOP(i__sbbOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_4: modrm_write_rmOP(i__andOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_5: modrm_write_rmOP(i__subOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		MRM_SLASH_6: modrm_write_rmOP(i__xorOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP())); return;
		default    : i__subOP(modrm_read_rmOP(), (sint8)mem_read8_CSIP()); return;
		MRM_END_SWITCH_SLASH
	}

/*84*/	void XAOi_(test_rm8_r8)() {
		modrm_decode();
		i__and8(modrm_read_rm8(), modrm_read_r8());
	}

/*85*/	void XAOi_(test_rmOP_rOP)() {
		modrm_decode();
		i__andOP(modrm_read_rmOP(), modrm_read_rOP());
	}

/*86*/	void XAOi_(xchg_rm8_r8)() {
		modrm_decode();
		int8 tmp = modrm_read_rm8();
		modrm_write_rm8(modrm_read_r8());
		modrm_write_r8(tmp);
	}

/*87*/	void XAOi_(xchg_rmOP_rOP)() {
		modrm_decode();
		intOP tmp = modrm_read_rmOP();
		modrm_write_rmOP(modrm_read_rOP());
		modrm_write_rOP(tmp);
	}

/*88*/	void XAOi_(mov_rm8_r8)() {
		modrm_decode();
		modrm_write_rm8(modrm_read_r8());
	}

/*89*/	void XAOi_(mov_rmOP_rOP)() {
		modrm_decode();
		modrm_write_rmOP(modrm_read_rOP());
	}

/*8a*/	void XAOi_(mov_r8_rm8)() {
		modrm_decode();
		modrm_write_r8(modrm_read_rm8());
	}

/*8b*/	void XAOi_(mov_rOP_rmOP)() {
		modrm_decode();
		modrm_write_rOP(modrm_read_rmOP());
	}

/*8c*/	void XAOi_(mov_rm16_sreg)() {
		modrm_decode();
		modrm_write_rm16(modrm_read_sreg());
}

/*8d*/	void XAOi_(lea_rOP_m)() {
		int16 unused;
		modrm_decode();
		modrm_write_rOP(modrm_locate_m(unused));
	}

/*8e*/	void XAOi_(mov_sreg_rm16)() {
		modrm_decode();
		modrm_write_sreg(modrm_read_rm16());
	}

/*8f*/	void XAOi_(pop_mOP)() {
		modrm_decode();
		if((modrm_byte & 0x38) != 0) throw 0; // #UD;
		modrm_write_mOP(i__popOP());
	}

/*90*/	void XAOi_(nop)() {}

/*91*/	void XAOi_(xchg_rax_rcx)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*cx, *ecx);
		PICK_OPSIZE(*cx, *ecx) = tmp;
	}

/*92*/	void XAOi_(xchg_rax_rdx)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*dx, *edx);
		PICK_OPSIZE(*dx, *edx) = tmp;
	}

/*93*/	void XAOi_(xchg_rax_rbx)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*bx, *ebx);
		PICK_OPSIZE(*bx, *ebx) = tmp;
	}

/*94*/	void XAOi_(xchg_rax_rsp)() {
		throw 0;
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*sp, *esp);
		PICK_OPSIZE(*sp, *esp) = tmp;
	}

/*95*/	void XAOi_(xchg_rax_rbp)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*bp, *ebp);
		PICK_OPSIZE(*bp, *ebp) = tmp;
	}

/*96*/	void XAOi_(xchg_rax_rsi)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*si, *esi);
		PICK_OPSIZE(*si, *esi) = tmp;
	}

/*97*/	void XAOi_(xchg_rax_rdi)() {
		intOP tmp = PICK_OPSIZE(*ax, *eax);
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE(*di, *edi);
		PICK_OPSIZE(*di, *edi) = tmp;
	}

/*98*/	void XAOi_(cbw)() { // cbw/cwde
		PICK_OPSIZE(*ax, *eax) = PICK_OPSIZE((sint8)*al, (sint16)*ax);
	}

/*99*/	void XAOi_(cwd)() { // cwd/cdq
		PICK_OPSIZE(*dx, *edx) = (PICK_OPSIZE(*ax & 0x8000, *eax & 0x80000000) ? (intOP)-1 : 0);
	}

/*9a*/	void XAOi_(call_ptr16OP)() {
		intOP new_ip = mem_readOP_CSIP();
		i__pushOP(cs->selector);
		cs->selector = mem_read16_CSIP();
		i__pushOP(PICK_OPSIZE(*ip, *eip));
		PICK_CPUBITS(*ip, *eip) = new_ip;
	}

/*9c*/	void XAOi_(pushfv)() {
		i__pushOP(PICK_OPSIZE(*flags, *eflags & ~(flags_mask_vm | flags_mask_rf)));
	}

/*9d*/	void XAOi_(popfv)() {
#if CPU >= X86_386
		int32 old_flags = *eflags;
#endif
#ifdef _DEBUG
		intOP balfka = i__popOP();
		PICK_OPSIZE(*flags, *eflags) = balfka
#else
		PICK_OPSIZE(*flags, *eflags) = i__popOP()
#endif
#if OPSIZE == 32
			& ~flags_mask_vm | (old_flags & flags_mask_vm)
	#if CPU >= X86_486
			& ~(flags_mask_vif | flags_mask_vip)
	#endif
#endif
			& ~flags_reserved_at_0 | flags_reserved_at_1;
	}

/*9e*/	void XAOi_(sahf)() {
		PICK_CPUBITS(*flags, *eflags) = PICK_CPUBITS(*flags & 0xff00, *eflags & 0xffffff00) |
			(*ah & 0xf7 | 0x02);
	}

/*9f*/	void XAOi_(lahf)() {
		*ah = (int8)PICK_CPUBITS(*flags, *eflags);
	}

/*a0*/	void XAOi_(mov_al_moffs8)() {
		*al = mem_read8(*ds, mem_readAD_CSIP());
	}

/*a1*/	void XAOi_(mov_rax_moffsOP)() {
		PICK_OPSIZE(*ax, *eax) = mem_readOP(*ds, mem_readAD_CSIP());
	}

/*a2*/	void XAOi_(mov_moffs8_al)() {
		mem_write8(*ds, mem_readAD_CSIP(), *al);
	}

/*a3*/	void XAOi_(mov_moffsOP_rax)() {
		mem_writeOP(*ds, mem_readAD_CSIP(), PICK_OPSIZE(*ax, *eax));
	}

/*a4*/	void XAOi_(movsb)() {
		mem_write8_NSO(*es, PICK_ADSIZE(*di, *edi), mem_read8(*ds, PICK_ADSIZE(*si, *esi)));
		if(flags_get_df()) {
			--PICK_ADSIZE(*si, *esi);
			--PICK_ADSIZE(*di, *edi);
		} else {
			++PICK_ADSIZE(*si, *esi);
			++PICK_ADSIZE(*di, *edi);
		}
	}

/*a5*/	void XAOi_(movsv)() {
		mem_writeOP_NSO(*es, PICK_ADSIZE(*di, *edi), mem_readOP(*ds, PICK_ADSIZE(*si, *esi)));
		if(flags_get_df()) {
			PICK_ADSIZE(*si, *esi) -= PICK_OPSIZE(2, 4);
			PICK_ADSIZE(*di, *edi) -= PICK_OPSIZE(2, 4);
		} else {
			PICK_ADSIZE(*si, *esi) += PICK_OPSIZE(2, 4);
			PICK_ADSIZE(*di, *edi) += PICK_OPSIZE(2, 4);
		}
	}

/*a6*/	void XAOi_(cmpsb)() {
		i__sub8(mem_read8(*ds, PICK_ADSIZE(*si, *esi)), mem_read8_NSO(*es, PICK_ADSIZE(*di, *edi)));
		if(flags_get_df()) {
			--PICK_ADSIZE(*si, *esi);
			--PICK_ADSIZE(*di, *edi);
		} else {
			++PICK_ADSIZE(*si, *esi);
			++PICK_ADSIZE(*di, *edi);
		}
	}

/*a7*/	void XAOi_(cmpsv)() {
		i__subOP(mem_readOP(*ds, PICK_ADSIZE(*si, *esi)), mem_readOP_NSO(*es, PICK_ADSIZE(*di, *edi)));
		if(flags_get_df()) {
			PICK_ADSIZE(*si, *esi) -= PICK_OPSIZE(2, 4);
			PICK_ADSIZE(*di, *edi) -= PICK_OPSIZE(2, 4);
		} else {
			PICK_ADSIZE(*si, *esi) += PICK_OPSIZE(2, 4);
			PICK_ADSIZE(*di, *edi) += PICK_OPSIZE(2, 4);
		}
	}

/*a8*/	void XAOi_(test_al_i8)() {
		i__and8(*al, mem_read8_CSIP());
	}

/*a9*/	void XAOi_(test_rax_iOP)() {
		i__andOP(PICK_OPSIZE(*ax, *eax), mem_readOP_CSIP());
	}

/*aa*/	void XAOi_(stosb)() {
		mem_write8_NSO(*es, PICK_ADSIZE(*di, *edi), *al);
		if(flags_get_df())
			--PICK_ADSIZE(*di, *edi);
		else
			++PICK_ADSIZE(*di, *edi);
	}

/*ab*/	void XAOi_(stosv)() {
		mem_writeOP_NSO(*es, PICK_ADSIZE(*di, *edi), PICK_OPSIZE(*ax, *eax));
		if(flags_get_df())
			PICK_ADSIZE(*di, *edi) -= PICK_OPSIZE(2, 4);
		else
			PICK_ADSIZE(*di, *edi) += PICK_OPSIZE(2, 4);
	}

/*ac*/	void XAOi_(lodsb)() {
		*al = mem_read8(*ds, PICK_ADSIZE(*si, *esi));
		if(flags_get_df())
			--PICK_ADSIZE(*si, *esi);
		else
			++PICK_ADSIZE(*si, *edi);
	}

/*ad*/	void XAOi_(lodsv)() {
		PICK_OPSIZE(*ax, *eax) = mem_readOP(*ds, PICK_ADSIZE(*si, *esi));
		if(flags_get_df())
			PICK_ADSIZE(*si, *esi) -= PICK_OPSIZE(2, 4);
		else
			PICK_ADSIZE(*si, *edi) += PICK_OPSIZE(2, 4);
	}

/*ae*/	void XAOi_(scasb)() {
		i__subOP(*al, mem_read8_NSO(*es, PICK_ADSIZE(*di, *edi)));
		if(flags_get_df())
			--PICK_ADSIZE(*di, *edi);
		else
			++PICK_ADSIZE(*di, *edi);
	}

/*af*/	void XAOi_(scasv)() {
		i__subOP(PICK_OPSIZE(*ax, *eax), mem_readOP_NSO(*es, PICK_ADSIZE(*di, *edi)));
		if(flags_get_df())
			PICK_ADSIZE(*di, *edi) -= PICK_OPSIZE(2, 4);
		else
			PICK_ADSIZE(*di, *edi) += PICK_OPSIZE(2, 4);
	}

/*b0*/	void XAOi_(mov_al_i8)() {*al = mem_read8_CSIP();}
/*b1*/	void XAOi_(mov_cl_i8)() {*cl = mem_read8_CSIP();}
/*b2*/	void XAOi_(mov_dl_i8)() {*dl = mem_read8_CSIP();}
/*b3*/	void XAOi_(mov_bl_i8)() {*bl = mem_read8_CSIP();}
/*b4*/	void XAOi_(mov_ah_i8)() {*ah = mem_read8_CSIP();}
/*b5*/	void XAOi_(mov_ch_i8)() {*ch = mem_read8_CSIP();}
/*b6*/	void XAOi_(mov_dh_i8)() {*dh = mem_read8_CSIP();}
/*b7*/	void XAOi_(mov_bh_i8)() {*bh = mem_read8_CSIP();}
/*b8*/	void XAOi_(mov_rax_iOP)() {PICK_OPSIZE(*ax, *eax) = mem_readOP_CSIP();}
/*b9*/	void XAOi_(mov_rcx_iOP)() {PICK_OPSIZE(*cx, *ecx) = mem_readOP_CSIP();}
/*ba*/	void XAOi_(mov_rdx_iOP)() {PICK_OPSIZE(*dx, *edx) = mem_readOP_CSIP();}
/*bb*/	void XAOi_(mov_rbx_iOP)() {PICK_OPSIZE(*bx, *ebx) = mem_readOP_CSIP();}
/*bc*/	void XAOi_(mov_rsp_iOP)() {PICK_OPSIZE(*sp, *esp) = mem_readOP_CSIP();}
/*bd*/	void XAOi_(mov_rbp_iOP)() {PICK_OPSIZE(*bp, *ebp) = mem_readOP_CSIP();}
/*be*/	void XAOi_(mov_rsi_iOP)() {PICK_OPSIZE(*si, *esi) = mem_readOP_CSIP();}
/*bf*/	void XAOi_(mov_rdi_iOP)() {PICK_OPSIZE(*di, *edi) = mem_readOP_CSIP();}

/*c0*/	void XAOi_(groupc0_rm8_i8)() {
		ZSSERT(CPU >= X86_186);
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rm8(i__rol8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_1: modrm_write_rm8(i__ror8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_2: ZSSERT(0); modrm_write_rm8(i__rcl8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_3: ZSSERT(0); modrm_write_rm8(i__rcr8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_4: modrm_write_rm8(i__shl8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_5: ZSSERT(0); modrm_write_rm8(i__shr8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rm8(i__shl8(modrm_read_rm8(), mem_read8_CSIP())); return;
		default    : ZSSERT(0); modrm_write_rm8(i__sar8(modrm_read_rm8(), mem_read8_CSIP())); return;
		MRM_END_SWITCH_SLASH
	}

/*c1*/	void XAOi_(groupc1_rmOP_i8)() {
		ZSSERT(CPU >= X86_186);
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: ZSSERT(0); modrm_write_rmOP(i__rolOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_1: ZSSERT(0); modrm_write_rmOP(i__rorOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_2: ZSSERT(0); modrm_write_rmOP(i__rclOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_3: ZSSERT(0); modrm_write_rmOP(i__rcrOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_4: modrm_write_rmOP(i__shlOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_5: modrm_write_rmOP(i__shrOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rmOP(i__shlOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		default    : modrm_write_rmOP(i__sarOP(modrm_read_rmOP(), mem_read8_CSIP())); return;
		MRM_END_SWITCH_SLASH
	}

/*c2*/	void XAOi_(ret_i16)() {
		int16 poppity = mem_read16_CSIP();
		PICK_CPUBITS(*ip, *eip) = i__popOP();
		PICK_ADSIZE(*sp, *esp) += poppity;
	}

/*c3*/	void XAOi_(ret)() {
		PICK_CPUBITS(*ip, *eip) = i__popOP();
	}

/*c4*/	void XAOi_(les_rOP_m16OP)() {
		modrm_decode();
		int16 new_es;
		modrm_write_rOP((intOP)modrm_read_mOP16(new_es));
		es->selector = new_es;
	}

/*c5*/	void XAOi_(lds_rOP_m16OP)() {
		modrm_decode();
		int16 new_ds;
		modrm_write_rOP((intOP)modrm_read_mOP16(new_ds));
		ds->selector = new_ds;
	}

/*c6*/	void XAOi_(mov_rm8_i8)() {
		modrm_decode();
		if((modrm_byte & 0x38) != 0) throw 0; // #UD;
		modrm_write_rm8(mem_read8_CSIP());
	}

/*c7*/	void XAOi_(mov_rmOP_iOP)() {
		modrm_decode();
		if((modrm_byte & 0x38) != 0) throw 0; // #UD;
		modrm_write_rmOP(mem_readOP_CSIP());
	}

/*c8*/	void XAOi_(enter_i16_i8)() {
		ZSSERT(CPU >= X86_186);
		int16 howbig = mem_read16_CSIP();
		int8 level = mem_read8_CSIP() & 0x31;
		i__pushOP(PICK_ADSIZE(*bp, *ebp));
		intAD frame_temp = PICK_ADSIZE(*sp, *esp);
		for(int i = 1; i < level; ++i) {
			PICK_ADSIZE(*bp, *ebp) -= OPSIZE;
			//i__pushOP(PICK_ADSIZE(*bp, *ebp)); // TODO: which one is right?
			i__pushOP(mem_readOP_NSO(*ss, PICK_ADSIZE(*bp, *ebp)));
		}
		if(level > 0)
			i__pushOP(frame_temp);
		PICK_ADSIZE(*bp, *ebp) = frame_temp;
		PICK_ADSIZE(*sp, *esp) -= howbig;
	}

/*c9*/	void XAOi_(leave)() {
		ZSSERT(CPU >= X86_186);
		PICK_ADSIZE(*sp, *esp) = (intOP)PICK_ADSIZE(*bp, *ebp);
		PICK_ADSIZE(*bp, *ebp) = i__popOP();
	}

/*ca*/	void XAOi_(retfv_i16)() {
		int16 popcorn = mem_read16_CSIP();
		PICK_CPUBITS(*ip, *eip) = i__popOP();
		cs->selector = i__popOP();
		PICK_ADSIZE(*sp, *esp) += popcorn;
	}

/*cb*/	void XAOi_(retfv)() {
		PICK_CPUBITS(*ip, *eip) = i__popOP();
		cs->selector = i__popOP();
	}

/*cd*/	void XAOi_(int_i8)() {
		int8 vector = mem_read8_CSIP();
		ZSSERT(vector != 0xcd); // that's never good...
		XAO_(interrupt)(vector);
	}

/*cf*/	void XAOi_(iretv)() {	
		PICK_CPUBITS(*ip, *eip) = i__popOP();
		cs->selector = i__popOP();
		PICK_OPSIZE(*flags, *eflags) = i__popOP() & (0xfd5
	#if CPU >= X86_286
			| flags_mask_iopl | flags_mask_nt
	  #if CPU >= X86_386 && OPSIZE == 32
			| flags_mask_rf
		#if CPU >= X86_486
			| flags_mask_ac | flags_mask_id
		#endif
	  #endif
	#endif
			)
	#if CPU >= X86_386 && OPSIZE == 32
			| (PICK_CPUBITS(*flags, *eflags) & (flags_mask_vm
	  #if CPU >= X86_486
			| flags_mask_vif | flags_mask_vip
	  #endif
			))
	#endif
			& ~flags_reserved_at_0 | flags_reserved_at_1;
	}

/*d0*/	void XAOi_(groupd0_rm8_1)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rm8(i__rol8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_1: modrm_write_rm8(i__ror8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_2: modrm_write_rm8(i__rcl8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_3: modrm_write_rm8(i__rcr8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_4: modrm_write_rm8(i__shl8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_5: modrm_write_rm8(i__shr8(modrm_read_rm8(), 1)); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rm8(i__shl8(modrm_read_rm8(), 1)); return; return;
		default    : modrm_write_rm8(i__sar8(modrm_read_rm8(), 1)); return;
		MRM_END_SWITCH_SLASH
	}

/*d1*/	void XAOi_(groupd1_rmOP_1)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rmOP(i__rolOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_1: modrm_write_rmOP(i__rorOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_2: modrm_write_rmOP(i__rclOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_3: modrm_write_rmOP(i__rcrOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_4: modrm_write_rmOP(i__shlOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_5: modrm_write_rmOP(i__shrOP(modrm_read_rmOP(), 1)); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rmOP(i__shlOP(modrm_read_rmOP(), 1)); return;
		default    : modrm_write_rmOP(i__sarOP(modrm_read_rmOP(), 1)); return;
		MRM_END_SWITCH_SLASH
	}

/*d2*/	void XAOi_(groupd2_rm8_cl)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rm8(i__rol8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_1: modrm_write_rm8(i__ror8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_2: ZSSERT(0); modrm_write_rm8(i__rcl8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_3: ZSSERT(0); modrm_write_rm8(i__rcr8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_4: modrm_write_rm8(i__shl8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_5: modrm_write_rm8(i__shr8(modrm_read_rm8(), *cl)); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rm8(i__shl8(modrm_read_rm8(), *cl)); return;
		default    : modrm_write_rm8(i__sar8(modrm_read_rm8(), *cl)); return;
		MRM_END_SWITCH_SLASH
	}

/*d3*/	void XAOi_(groupd3_rmOP_cl)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rmOP(i__rolOP(modrm_read_rmOP(), *cl)); return;
		MRM_SLASH_1: modrm_write_rmOP(i__rorOP(modrm_read_rmOP(), *cl)); return;
		MRM_SLASH_2: ZSSERT(0); modrm_write_rmOP(i__rclOP(modrm_read_rmOP(), *cl)); return;
		MRM_SLASH_3: modrm_write_rmOP(i__rcrOP(modrm_read_rmOP(), *cl)); return;
		MRM_SLASH_4: modrm_write_rmOP(i__shlOP(modrm_read_rm16(), *cl)); return;
		MRM_SLASH_5: modrm_write_rmOP(i__shrOP(modrm_read_rm16(), *cl)); return;
		MRM_SLASH_6: ZSSERT(0); modrm_write_rmOP(i__shlOP(modrm_read_rmOP(), *cl)); return;
		default    : modrm_write_rmOP(i__sarOP(modrm_read_rm16(), *cl)); return;
		MRM_END_SWITCH_SLASH
	}

/*d4*/	void XAOi_(aam_i8)() {
		int8 base = mem_read8_CSIP();
		*ax = ((*al / base) << 8) | (*al % base);
	}

/*d5*/	void XAOi_(aad_i8)() {
		*ax = *ah * mem_read8_CSIP() + *al;
	}

/*d6*/	void XAOi_(salc)() {
		ZSSERT(CPU >= X86_286); // TODO: is this really only 286+?
		ZSSERT(0);
		*al = flags_get_cf() ? 0xff : 0;
	}

/*d7*/	void XAOi_(xlatb)() {
		*al = mem_read8(*ds, PICK_ADSIZE(*bx, *ebx) + *al);
	}

/*d8*/	void XAOi_(esc_0)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 0, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*d9*/	void XAOi_(esc_1)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 1, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*da*/	void XAOi_(esc_2)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 2, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*db*/	void XAOi_(esc_3)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 3, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*dc*/	void XAOi_(esc_4)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 4, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*dd*/	void XAOi_(esc_5)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 5, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*de*/	void XAOi_(esc_6)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 6, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*df*/	void XAOi_(esc_7)() {
		modrm_decode();
		plug->Log(plug_persist, LOG_INFO, X86_RENDER_CSIP() + L"ESC 7, coprocessor not available.  #NM.");
		XAO_(raiseNM)();
	}

/*e0*/	void XAOi_(loopnz_rel8)() {
		sint8 rel = mem_read8_CSIP();
		if(--PICK_ADSIZE(*cx, *ecx) && !flags_get_zf())
			PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*e1*/	void XAOi_(loopz_rel8)() {
		sint8 rel = mem_read8_CSIP();
		if(--PICK_ADSIZE(*cx, *ecx) && flags_get_zf())
			PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*e2*/	void XAOi_(loop_rel8)() {
		sint8 rel = mem_read8_CSIP();
		if(--PICK_ADSIZE(*cx, *ecx))
			PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*e3*/	void XAOi_(jrcxz_rel8)() {i__jcc_rel8(PICK_ADSIZE(*cx, *ecx) == 0, mem_read8_CSIP());}

/*e4*/	void XAOi_(in_al_i8)() {*al = plug_cpu->PortRead8(mem_read8_CSIP());}
/*e5*/	void XAOi_(in_rax_i8)() {ZSSERT(0); PICK_OPSIZE(*ax, *eax) = plug_cpu->PICK_OPSIZE(PortRead16, PortRead32)(mem_read8_CSIP());}
/*e6*/	void XAOi_(out_i8_al)() {plug_cpu->PortWrite8(mem_read8_CSIP(), *al);}
/*e7*/	void XAOi_(out_i8_rax)() {ZSSERT(0); plug_cpu->PICK_OPSIZE(PortWrite16, PortWrite32)(mem_read8_CSIP(), PICK_OPSIZE(*ax, *eax));}

/*e8*/	void XAOi_(call_relOP)() {
		sintOP rel = mem_readOP_CSIP();
		i__pushOP(PICK_OPSIZE(*ip, *eip));
		PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*e9*/	void XAOi_(jmp_relOP)() {
		sintOP rel = mem_readOP_CSIP();
		PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*ea*/	void XAOi_(jmp_ptr16OP)() {
		intOP new_ip = mem_readOP_CSIP();
		cs->selector = mem_read16_CSIP();
		PICK_CPUBITS(*ip, *eip) = new_ip;
	}

/*eb*/	void XAOi_(jmp_rel8)() {
	// TODO: OS idle fix, detect if jmping to same instruction, then hlt
		sint8 rel = mem_read8_CSIP();
		PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + rel);
	}

/*ec*/	void XAOi_(in_al_dx)() {*al = plug_cpu->PortRead8(*dx);}
/*ed*/	void XAOi_(in_rax_dx)() {PICK_OPSIZE(*ax, *eax) = plug_cpu->PICK_OPSIZE(PortRead16, PortRead32)(*dx);}
/*ee*/	void XAOi_(out_dx_al)() {plug_cpu->PortWrite8(*dx, *al);}
/*ef*/	void XAOi_(out_dx_rax)() {plug_cpu->PICK_OPSIZE(PortWrite16(*dx, *ax), PortWrite32(*dx, *eax));}

#define I__REP(instr)	while(PICK_ADSIZE(*cx, *ecx)) {						\
							/* TODO: service pending interrupts if any*/	\
							XAOi_(instr)();									\
							--PICK_ADSIZE(*cx, *ecx);}
#define I__REPZ(instr)	while(PICK_ADSIZE(*cx, *ecx)) {						\
							/* TODO: service pending interrupts if any*/	\
							XAOi_(instr)();									\
							--PICK_ADSIZE(*cx, *ecx);						\
							if(!flags_get_zf()) break;}
#define I__REPNZ(instr)	while(PICK_ADSIZE(*cx, *ecx)) {						\
							/* TODO: service pending interrupts if any*/	\
							XAOi_(instr)();									\
							--PICK_ADSIZE(*cx, *ecx);						\
							if(flags_get_zf()) break;}

/*f2*/	void XAOi_(repnz)() {
		int8 next = mem_read8_CSIP();
		switch(next) {
		case 0x26: ZSSERT(0); seg_override = es; XAOi_(repnz)(); return;
		case 0x2e: ZSSERT(0); seg_override = cs; XAOi_(repnz)(); return;
		case 0x36: ZSSERT(0); seg_override = ss; XAOi_(repnz)(); return;
		case 0x3e: ZSSERT(0); seg_override = ds; XAOi_(repnz)(); return;
#if CPU >= X86_386
		case 0x66: ZSSERT(0); CONCAT(PICK_ADSIZE(X_(real16), X_(real32)), PICK_OPSIZE(32_i_repnz, 16_i_repnz))(); return;
		case 0x67: ZSSERT(0); CONCAT(PICK_ADSIZE(X_(real32), X_(real16)), PICK_OPSIZE(16_i_repnz, 32_i_repnz))(); return;
#endif
		case 0xa4: I__REP(movsb); return; // TODO: this is questionable...
		case 0xa5: I__REP(movsv); return; // TODO: this is questionable...
		case 0xa6: I__REPNZ(cmpsb); return;
		case 0xa7: ZSSERT(0); I__REPNZ(cmpsv); return;
		case 0xae: I__REPNZ(scasb); return;
		case 0xaf: I__REPNZ(scasv); return;
		default  :
			plug->Log(plug_persist, LOG_ERROR, X86_RENDER_CSIP() + L"bad opcode after repnz: 0x" +
				Piston::String::Renderhex(next).PadLeft(2, L'0') + L".  #UD.");
			ZSSERT(0);
			XAO_(raiseUD)();
		}
	}

/*f3*/	void XAOi_(rep)() {
		int8 next = mem_read8_CSIP();
		switch(next) {
		case 0x26: seg_override = es; XAOi_(rep)(); return;
		case 0x2e: seg_override = cs; XAOi_(rep)(); return;
		case 0x36: seg_override = ss; XAOi_(rep)(); return;
		case 0x3e: ZSSERT(0); seg_override = ds; XAOi_(rep)(); return;
#if CPU >= X86_386
		case 0x66: CONCAT(PICK_ADSIZE(X_(real16), X_(real32)), PICK_OPSIZE(32_i_rep, 16_i_rep))(); return;
		case 0x67: ZSSERT(0); CONCAT(PICK_ADSIZE(X_(real32), X_(real16)), PICK_OPSIZE(16_i_rep, 32_i_rep))(); return;
#endif
		case 0xa4: I__REP(movsb); return;
		case 0xa5: I__REP(movsv); return;
		case 0xa6: I__REPZ(cmpsb); return;
		case 0xa7: I__REPZ(cmpsv); return;
		case 0xaa: I__REP(stosb); return;
		case 0xab: I__REP(stosv); return;
		case 0xae: I__REPZ(scasb); return;
		case 0xaf: I__REPZ(scasv); return;
		default  :
			plug->Log(plug_persist, LOG_ERROR, X86_RENDER_CSIP() + L"bad opcode after rep/repe: 0x" +
				Piston::String::Renderhex(next).PadLeft(2, L'0') + L".  #UD.");
			ZSSERT(0);
			XAO_(raiseUD)();
		}
	}

#undef I__REP
#undef I__REPZ
#undef I__REPNZ

/*f4*/	void XAOi_(hlt)() {
		plug->Log(plug_persist, LOG_FATAL, L"HLT encountered -- CPU frozen.");
		ZSSERT(0);
		for(;;);
	}

/*f5*/	void XAOi_(cmc)() {
		flags_set_cf(!flags_get_cf());
	}

/*f6*/	void XAOi_(groupf6_rm8)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: i__and8(modrm_read_rm8(), mem_read8_CSIP()); return;
		MRM_SLASH_1: throw 0; return;
		MRM_SLASH_2: // not rm8
			modrm_write_rm8(~modrm_read_rm8());
			return;
		MRM_SLASH_3: { // neg rm8
			int8 res = -modrm_read_rm8();
			modrm_write_rm8(res);
			PICK_CPUBITS(*flags, *eflags) = PICK_CPUBITS(*flags, *eflags) & ~flags_mask_cpazso |
				(res                  ? flags_mask_cf : flags_mask_zf) |
				parity_lookup[res]    | // pf
				(res & 0xf        ? 0 : flags_mask_af) |
				(res & 0x80)          | // sf
				(res == 0x80          ? flags_mask_of : 0);
		} return;
		MRM_SLASH_4: { // ax = al mul rm8
			*ax = *al * modrm_read_rm8();
			if(*ah) // if upper half of result is nonzero
				PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
			else
				PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
		} return;
		MRM_SLASH_5: { // ax = al imul rm8
			*ax = (sint8)*al * (sint8)modrm_read_rm8();
			if(*ax != (sint8)*al)
				PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
			else
				PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
		} return;
		MRM_SLASH_6: { // al = ax div rm8; ah = mod
			int8 op2 = modrm_read_rm8();
			if(op2) {
				int16 res = *ax / op2;
				if(res == (int8)res) {
					*ah = *ax % op2;
					*al = (int8)res;
				} else { // too big
					ZSSERT(0);
					XAO_(raiseDE)();
				}
			} else { // divide by 0
				ZSSERT(0);
				XAO_(raiseDE)();
			}
		} return;
		default    : { // al = ax idiv rm8; ah = mod
			sint8 op2 = modrm_read_rm8();
			if(op2) {
				sint16 res = (sint16)*ax / op2;
				if(res == (sint8)res) {
					*ah = (sint16)*ax % op2;
					*al = (int8)res;
				} else { // too big
					ZSSERT(0);
					XAO_(raiseDE)();
				}
			} else { // div by 0
				ZSSERT(0);
				XAO_(raiseDE)();
			}
		} MRM_END_SWITCH_SLASH
	}

/*f7*/	void XAOi_(groupf7_rmOP)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: i__andOP(modrm_read_rmOP(), mem_readOP_CSIP()); return;
		MRM_SLASH_1: throw 0; return;
		MRM_SLASH_2: // not rmOP
			modrm_write_rmOP(~modrm_read_rmOP());
			return;
		MRM_SLASH_3: { // neg rmOP
			intOP res = -(sintOP)modrm_read_rmOP();
			modrm_write_rmOP(res);
			PICK_CPUBITS(*flags, *eflags) = PICK_CPUBITS(*flags, *eflags) & ~flags_mask_cpazso |
				(res                     ? flags_mask_cf : flags_mask_zf) |
				parity_lookup[(int8)res] | // pf
				(res & 0xf           ? 0 : flags_mask_af) |
				(res & 0x8000            ? flags_mask_sf : 0) |
				(res == 0x8000           ? flags_mask_of : 0);
		} return;
		MRM_SLASH_4: { // rdx:rax = rax mul rmOP
			PICK_OPSIZE(int32, int64) res = (PICK_OPSIZE(int32, int64))PICK_OPSIZE(*ax, *eax) * modrm_read_rmOP();
			PICK_OPSIZE(*ax, *eax) = (intOP)res;
			PICK_OPSIZE(*dx, *edx) = (intOP)(res >> OPSIZE);
			if(PICK_OPSIZE(*dx, *edx))
				PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
			else
				PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
		} return;
		MRM_SLASH_5: { // rdx:rax = rax imul rmOP
			ZSSERT(OPSIZE == 16);
			PICK_OPSIZE(sint32, sint64) res = (sintOP)PICK_OPSIZE(*ax, *eax) * (sintOP)modrm_read_rmOP();
			PICK_OPSIZE(*ax, *eax) = (intOP)res;
			PICK_OPSIZE(*dx, *edx) = (intOP)(res >> OPSIZE);
			if(res != (sintOP)res)
				PICK_CPUBITS(*flags, *eflags) |= flags_mask_cfof;
			else
				PICK_CPUBITS(*flags, *eflags) &= ~flags_mask_cfof;
		} return;
		MRM_SLASH_6: { // rax = rdx:rax div rmOP; rdx = mod
			PICK_OPSIZE(int32, int64) op1 = (((PICK_OPSIZE(int32, int64))PICK_OPSIZE(*dx, *edx) << OPSIZE) | PICK_OPSIZE(*ax, *eax));
			intOP op2 = modrm_read_rmOP();
			if(op2) {
				PICK_OPSIZE(int32, int64) res = op1 / op2;
				if(res == (intOP)res) {
					PICK_OPSIZE(*ax, *eax) = (intOP)res;
					PICK_OPSIZE(*dx, *edx) = (intOP)(op1 % op2);
				} else { // overflow
					ZSSERT(0);
					XAO_(raiseDE)();
				}
			} else { // divide by 0
				ZSSERT(0);
				XAO_(raiseDE)();
			}
		} return;
		default    : { // rax = rdx:rax idiv rmOP; rdx = mod
			ZSSERT(OPSIZE == 16); // what to do for 32-bit?
			PICK_OPSIZE(sint32, sint64) op1 = ((PICK_OPSIZE(*dx, *edx) << OPSIZE) | PICK_OPSIZE(*ax, *eax));
			sintOP op2 = modrm_read_rmOP();
			if(op2) {
				PICK_OPSIZE(sint32, sint64) res = op1 / op2;
				if(res == (sintOP)res) {
					PICK_OPSIZE(*ax, *eax) = (intOP)res;
					PICK_OPSIZE(*dx, *edx) = (intOP)(op1 % op2);
				} else { // too big
					ZSSERT(0);
					XAO_(raiseDE)();
				}
			} else { // divide by 0
				ZSSERT(0);
				XAO_(raiseDE)();
			}
		} MRM_END_SWITCH_SLASH
	}

/*f8*/	void XAOi_(clc)() {flags_clear_cf();}
/*f9*/	void XAOi_(stc)() {flags_set_cf();}
/*fa*/	void XAOi_(cli)() {flags_clear_if();}
/*fb*/	void XAOi_(sti)() {flags_set_if();} // TODO: inhibit interrupts for one instruction
/*fc*/	void XAOi_(cld)() {flags_clear_df();}
/*fd*/	void XAOi_(std)() {flags_set_df();}

/*fe*/	void XAOi_(groupfe_rm8)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rm8(i__inc8(modrm_read_rm8())); return;
		MRM_SLASH_1: modrm_write_rm8(i__dec8(modrm_read_rm8())); return;
		default    :
			plug->Log(plug_persist, LOG_ERROR, X86_RENDER_CSIP() + L"FE " +
				X86_RENDER_SLASH(modrm_byte) + L": Undefined opcode.  #UD.");
			ZSSERT(0);
			XAO_(raiseUD)();
		MRM_END_SWITCH_SLASH
	}

/*ff*/	void XAOi_(groupff_rmOP)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: modrm_write_rmOP(i__incOP(modrm_read_rmOP())); return;
		MRM_SLASH_1: modrm_write_rmOP(i__decOP(modrm_read_rmOP())); return;
		MRM_SLASH_2: { // call_rmOP
			intOP target = modrm_read_rmOP();
			i__pushOP(PICK_OPSIZE(*ip, *eip));
			PICK_CPUBITS(*ip, *eip) = target;
		} return;
		MRM_SLASH_3: { // call_m16OP
			int16 new_cs;
			intOP new_rip = modrm_read_mOP16(new_cs);
			i__pushOP(cs->selector);
			i__pushOP(PICK_OPSIZE(*ip, *eip));
			cs->selector = new_cs;
			PICK_CPUBITS(*ip, *eip) = new_rip;
		} return;
		MRM_SLASH_4: // jmp_rmOP
			PICK_CPUBITS(*ip, *eip) = modrm_read_rmOP();
			return;
		MRM_SLASH_5: { // jmp_m16OP
			int16 new_cs;
			intOP new_rip = modrm_read_mOP16(new_cs);
			cs->selector = new_cs;
			PICK_CPUBITS(*ip, *eip) = new_rip;
		} return;
		MRM_SLASH_6: i__pushOP(modrm_read_mOP()); return;
		default    :
			plug->Log(plug_persist, LOG_ERROR, X86_RENDER_CSIP() + L"FF /7: Undefined opcode.  #UD.");
			ZSSERT(0);
			XAO_(raiseUD)();
		MRM_END_SWITCH_SLASH
	}
}}

#if CPU >= X86_286
	#include "real_0f.hpp"
#endif

#include "real_epilogue.hpp"
#include "real_a_o_cleanup.hpp"