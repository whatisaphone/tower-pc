namespace Tower { namespace X86 {
/* 0f 00 */	void XAOi_(group0f00_rm16)() {
		XAO_(raiseUD)(); // these not recognized in real mode
	}

/* 0f 01 */	void XAOi_(group0f01)() {
		modrm_decode();
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: // sgdt m16OP
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		MRM_SLASH_1: // sidt m16OP
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		MRM_SLASH_2: // lgdt m16OP
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		MRM_SLASH_3: // lidt m16OP
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		MRM_SLASH_4: // smsw rm16
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		MRM_SLASH_6: // lmsw rm16
			ZSSERT(0);
			XAO_(raiseUD)();
			break;
		default    :
			ZSSERT(0);
			XAO_(raiseUD)();
		MRM_END_SWITCH_SLASH
	}

/* 0f 20 */	void XAOi_(mov_r32_crx)() { // TODO: verify 0f20-0f27 all start at 386
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 21 */	void XAOi_(mov_r32_drx)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 22 */	void XAOi_(mov_crx_r32)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 23 */	void XAOi_(mov_drx_r32)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 24 */	void XAOi_(mov_r32_trx)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 26 */	void XAOi_(mov_trx_r32)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 31 */	void XAOi_(rdtsc)() {
		ZSSERT(CPU >= X86_P1);
		ZSSERT(0);
		XAO_(raiseUD)();
	}

/* 0f 80 */	void XAOi_(jo_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_of(), mem_readOP_CSIP());}
/* 0f 81 */	void XAOi_(jno_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_of(), mem_readOP_CSIP());}
/* 0f 82 */	void XAOi_(jc_relOP)() {ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_cf(), mem_readOP_CSIP());}
/* 0f 83 */	void XAOi_(jnc_relOP)() {ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_cf(), mem_readOP_CSIP());}
/* 0f 84 */	void XAOi_(jz_relOP)() {ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_zf(), mem_readOP_CSIP());}
/* 0f 85 */	void XAOi_(jnz_relOP)() {ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_zf(), mem_readOP_CSIP());}
/* 0f 86 */	void XAOi_(jbe_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_cf() || flags_get_zf(), mem_readOP_CSIP());}
/* 0f 87 */	void XAOi_(jnbe_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_cf() && !flags_get_zf(), mem_readOP_CSIP());}
/* 0f 88 */	void XAOi_(js_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_sf(), mem_readOP_CSIP());}
/* 0f 89 */	void XAOi_(jns_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_sf(), mem_readOP_CSIP());}
/* 0f 8a */	void XAOi_(jp_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_pf(), mem_readOP_CSIP());}
/* 0f 8b */	void XAOi_(jnp_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_pf(), mem_readOP_CSIP());}
/* 0f 8c */	void XAOi_(jl_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_sf() != flags_get_of(), mem_readOP_CSIP());}
/* 0f 8d */	void XAOi_(jnl_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_sf() == flags_get_of(), mem_readOP_CSIP());}
/* 0f 8e */	void XAOi_(jle_relOP)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__jcc_relOP(flags_get_zf() || (flags_get_sf() != flags_get_of()), mem_readOP_CSIP());}
/* 0f 8f */	void XAOi_(jnle_relOP)() {ZSSERT(CPU >= X86_386); i__jcc_relOP(!flags_get_zf() && (flags_get_sf() == flags_get_of()), mem_readOP_CSIP());}

/* 0f a0 */	void XAOi_(push_fs)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__pushOP(fs->selector);}
/* 0f a1 */	void XAOi_(pop_fs)() {ZSSERT(CPU >= X86_386); i__popOP();}

/* 0f a2 */ void XAOi_(cpuid)() {
		ZSSERT(CPU >= X86_486);
		ZSSERT(CPU >= X86_P1); // impl on later 486's and all 586-n-up
		XAO_(raiseUD)();
	}

/* 0f a4 */	void XAOi_(shld_rmOP_rOP_i8)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0); // impl
		XAO_(raiseUD)();
	}

/* 0f a5 */	void XAOi_(shld_rmOP_rOP_cl)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0); // impl
		XAO_(raiseUD)();
	}

/* 0f a8 */	void XAOi_(push_gs)() {ZSSERT(0); ZSSERT(CPU >= X86_386); i__pushOP(gs->selector);}
/* 0f a9 */	void XAOi_(pop_gs)() {ZSSERT(0); ZSSERT(CPU >= X86_386); gs->selector = i__popOP();}

/* 0f ac */	void XAOi_(shrd_rmOP_rOP_i8)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0); // impl
		XAO_(raiseUD)();
	}

/* 0f ad */	void XAOi_(shrd_rmOP_rOP_cl)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0); // impl
		XAO_(raiseUD)();
	}

/* 0f b6 */	void XAOi_(movzx_rOP_rm8)() {
		ZSSERT(CPU >= X86_386);
		modrm_decode();
		modrm_write_rOP(modrm_read_rm8());
	}

/* 0f b7 */	void XAOi_(movzx_rOP_rm16)() {
		ZSSERT(CPU >= X86_386);
		modrm_decode();
		modrm_write_rOP(modrm_read_rm16());
	}

/* 0f bc */	void XAOi_(bsf_rOP_rmOP)() {
		ZSSERT(CPU >= X86_386);
		modrm_decode();
		intOP src = modrm_read_rmOP();
		for(int8 bit = 0; bit < OPSIZE; ++bit)
			if(src & (1 << bit)) {
				flags_clear_zf();
				modrm_write_rOP(bit);
				return;
			}
		flags_set_zf(); // bit not found
	}

/* 0f bd */	void XAOi_(bsr_rOP_rmOP)() {
		ZSSERT(CPU >= X86_386);
		ZSSERT(0);
		modrm_decode();
		intOP src = modrm_read_rmOP();
		for(int8 bit = OPSIZE - 1; !(bit & 0x80); --bit)
			if(src & (1 << bit)) {
				flags_clear_zf();
				modrm_write_rOP(bit);
				return;
			}
		flags_set_zf(); // bit not found
	}
}}