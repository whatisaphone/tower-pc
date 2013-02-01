// called from real.hpp

namespace Tower { namespace X86 {
	bool XAO_(HandleAsyncEvents()) {
		ZSSERT(AsyncEventCount > 0); // assumed

		if(INTPIN) if(flags_get_if()) {
			--INTPIN;
			--AsyncEventCount;

			int8 vector = plug_cpu->INTA();
			XAO_(interrupt)(vector);
		}

		if(TowerWantsPause) {
			--TowerWantsPause;
			--AsyncEventCount;

			CpuPaused->Signal();
			CanContinueRunning->Wait();
		}

		if(TowerWantsQuit)
			return false; // false means exit thread

		return true;
	}

	void XAO_(Loop)() {
		setjmp(jmp_to_loop);

		for(;;) {
			if(AsyncEventCount)
				if(!XAO_(HandleAsyncEvents)())
					break; // breaks back to loop.hpp

			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)(); // unrolled loop?
			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)();
			XAO_(Step)();
		}
	}

	/*void (*const XAO_(Ops)[256])() = {
		// 0x0_
		&XAOi_(add_rm8_r8),
		&XAOi_(add_rmOP_rOP),
		&XAOi_(add_r8_rm8),
		&XAOi_(add_rOP_rmOP),
		&XAOi_(add_al_i8),
		&XAOi_(add_rax_iOP),
		&XAOi_(push_es),
		&XAOi_(pop_es),
		&XAOi_(or_rm8_r8),
		&XAOi_(or_rmOP_rOP),
		&XAOi_(or_r8_rm8),
		&XAOi_(or_rOP_rmOP),
		&XAOi_(or_al_i8),
		&XAOi_(or_rax_iOP),
		&XAOi_(push_cs),
		&XAOi_(pop_cs),

		// 0x1_
		&XAOi_(adc_rm8_r8),
		&XAOi_(adc_rmOP_rOP),
		&XAOi_(adc_r8_rm8),
		&XAOi_(adc_rOP_rmOP),
		&XAOi_(adc_al_i8),
		&XAOi_(adc_rax_iOP),
		&XAOi_(push_ss),
		&XAOi_(pop_ss),
		&XAOi_(sbb_rm8_r8),
		&XAOi_(sbb_rmOP_rOP),
		&XAOi_(sbb_r8_rm8),
		&XAOi_(sbb_rOP_rmOP),
		&XAOi_(sbb_al_i8),
		&XAOi_(sbb_rax_iOP),
		&XAOi_(push_ds),
		&XAOi_(pop_ds),

		// 0x2_
		&XAOi_(and_rm8_r8),
		&XAOi_(and_rmOP_rOP),
		&XAOi_(and_r8_rm8),
		&XAOi_(and_rOP_rmOP),
		&XAOi_(and_al_i8),
		&XAOi_(and_rax_iOP),
		&XAOi_(pre_es),
		&XAOi_(daa),
		&XAOi_(sub_rm8_r8),
		&XAOi_(sub_rmOP_rOP),
		&XAOi_(sub_r8_rm8),
		&XAOi_(sub_rOP_rmOP),
		&XAOi_(sub_al_i8),
		&XAOi_(sub_rax_iOP),
		&XAOi_(pre_cs),
		&i_unimpl, // das

		// 0x3_
		&XAOi_(xor_rm8_r8),
		&XAOi_(xor_rmOP_rOP),
		&XAOi_(xor_r8_rm8),
		&XAOi_(xor_rOP_rmOP),
		&XAOi_(xor_al_i8),
		&XAOi_(xor_rax_iOP),
		&XAOi_(pre_ss),
		&i_unimpl, // aaa
		&XAOi_(cmp_rm8_r8),
		&XAOi_(cmp_rmOP_rOP),
		&XAOi_(cmp_r8_rm8),
		&XAOi_(cmp_rOP_rmOP),
		&XAOi_(cmp_al_i8),
		&XAOi_(cmp_rax_iOP),
		&XAOi_(pre_ds),
		&XAOi_(aas),

		// 0x4_
		&XAOi_(inc_rax),
		&XAOi_(inc_rcx),
		&XAOi_(inc_rdx),
		&XAOi_(inc_rbx),
		&XAOi_(inc_rsp),
		&XAOi_(inc_rbp),
		&XAOi_(inc_rsi),
		&XAOi_(inc_rdi),
		&XAOi_(dec_rax),
		&XAOi_(dec_rcx),
		&XAOi_(dec_rdx),
		&XAOi_(dec_rbx),
		&XAOi_(dec_rsp),
		&XAOi_(dec_rbp),
		&XAOi_(dec_rsi),
		&XAOi_(dec_rdi),

		// 0x5_
		&XAOi_(push_rax),
		&XAOi_(push_rcx),
		&XAOi_(push_rdx),
		&XAOi_(push_rbx),
		&XAOi_(push_rsp),
		&XAOi_(push_rbp),
		&XAOi_(push_rsi),
		&XAOi_(push_rdi),
		&XAOi_(pop_rax),
		&XAOi_(pop_rcx),
		&XAOi_(pop_rdx),
		&XAOi_(pop_rbx),
		&XAOi_(pop_rsp),
		&XAOi_(pop_rbp),
		&XAOi_(pop_rsi),
		&XAOi_(pop_rdi),

		// 0x6_
#if CPU < X86_186
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs286),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
		&XAO_(needs186),
#else
		&XAOi_(pushav),
		&XAOi_(popav),
		&i_unimpl, // bound
  #if CPU < X86_286
		&XAO_(needs286),
  #else
		&i_unimpl, // arpl
  #endif
  #if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
  #else
		&i_unimpl, // fs:
		&i_unimpl, // gs:
		&XAOi_(pre_opsize),
		&XAOi_(pre_adsize),
  #endif
		&XAOi_(push_iOP),
		&XAOi_(imul_rOP_rmOP_iOP),
		&XAOi_(push_si8),
		&XAOi_(imul_rOP_rmOP_si8),
		&i_unimpl, // ins
		&i_unimpl, // ins
		&i_unimpl, // outs
		&i_unimpl, // outs
#endif

		// 0x7_
		&XAOi_(jo_rel8),
		&XAOi_(jno_rel8),
		&XAOi_(jc_rel8),
		&XAOi_(jnc_rel8),
		&XAOi_(jz_rel8),
		&XAOi_(jnz_rel8),
		&XAOi_(jbe_rel8),
		&XAOi_(jnbe_rel8),
		&XAOi_(js_rel8),
		&XAOi_(jns_rel8),
		&XAOi_(jp_rel8),
		&XAOi_(jnp_rel8),
		&XAOi_(jl_rel8),
		&XAOi_(jnl_rel8),
		&XAOi_(jle_rel8),
		&XAOi_(jnle_rel8),

		// 0x8_
		&XAOi_(group80_rm8_i8),
		&XAOi_(group81_rmOP_iOP),
		&i_unimpl, // alias for 0x80? VERIFY!!
		&XAOi_(group83_rmOP_si8),
		&XAOi_(test_rm8_r8),
		&XAOi_(test_rmOP_rOP),
		&XAOi_(xchg_rm8_r8),
		&XAOi_(xchg_rmOP_rOP),
		&XAOi_(mov_rm8_r8),
		&XAOi_(mov_rmOP_rOP),
		&XAOi_(mov_r8_rm8),
		&XAOi_(mov_rOP_rmOP),
		&XAOi_(mov_rm16_sreg),
		&XAOi_(lea_rOP_m),
		&XAOi_(mov_sreg_rm16),
		&XAOi_(pop_mOP),

		// 0x9_
		&XAOi_(nop),
		&XAOi_(xchg_rax_rcx),
		&XAOi_(xchg_rax_rdx),
		&XAOi_(xchg_rax_rbx),
		&XAOi_(xchg_rax_rsp),
		&XAOi_(xchg_rax_rbp),
		&XAOi_(xchg_rax_rsi),
		&XAOi_(xchg_rax_rdi),
		&XAOi_(cbw),
		&XAOi_(cwd),
		&XAOi_(call_ptr16OP),
		&i_unimpl, // wait
		&XAOi_(pushfv),
		&XAOi_(popfv),
		&XAOi_(sahf),
		&XAOi_(lahf),

		// 0xa_
		&XAOi_(mov_al_moffs8),
		&XAOi_(mov_rax_moffsOP),
		&XAOi_(mov_moffs8_al),
		&XAOi_(mov_moffsOP_rax),
		&XAOi_(movsb),
		&XAOi_(movsv),
		&XAOi_(cmpsb),
		&XAOi_(cmpsv),
		&XAOi_(test_al_i8),
		&XAOi_(test_rax_iOP),
		&XAOi_(stosb),
		&XAOi_(stosv),
		&XAOi_(lodsb),
		&XAOi_(lodsv),
		&XAOi_(scasb),
		&XAOi_(scasv),

		// 0xb_
		&XAOi_(mov_al_i8),
		&XAOi_(mov_cl_i8),
		&XAOi_(mov_dl_i8),
		&XAOi_(mov_bl_i8),
		&XAOi_(mov_ah_i8),
		&XAOi_(mov_ch_i8),
		&XAOi_(mov_dh_i8),
		&XAOi_(mov_bh_i8),
		&XAOi_(mov_rax_iOP),
		&XAOi_(mov_rcx_iOP),
		&XAOi_(mov_rdx_iOP),
		&XAOi_(mov_rbx_iOP),
		&XAOi_(mov_rsp_iOP),
		&XAOi_(mov_rbp_iOP),
		&XAOi_(mov_rsi_iOP),
		&XAOi_(mov_rdi_iOP),

		// 0xc_
#if CPU < X86_186
		&XAO_(needs186),
		&XAO_(needs186),
#else
		&XAOi_(groupc0_rm8_i8),
		&XAOi_(groupc1_rmOP_i8),
#endif
		&XAOi_(ret_i16),
		&XAOi_(ret),
		&XAOi_(les_rOP_m16OP),
		&XAOi_(lds_rOP_m16OP),
		&XAOi_(mov_rm8_i8),
		&XAOi_(mov_rmOP_iOP),
#if CPU < X86_186
		&XAO_(needs186),
		&XAO_(needs186),
#else
		&XAOi_(enter_i16_i8),
		&XAOi_(leave),
#endif
		&XAOi_(retf_i16),
		&XAOi_(retf),
		&i_unimpl, // int3
		&XAOi_(int_i8),
		&i_unimpl, // into
		&XAOi_(iret),

		// 0xd_
		&XAOi_(groupd0_rm8_1),
		&XAOi_(groupd1_rmOP_1),
		&XAOi_(groupd2_rm8_cl),
		&XAOi_(groupd3_rmOP_cl),
		&XAOi_(aam_i8),
		&XAOi_(aad_i8),
#if CPU >= X86_286
		&XAOi_(salc),
#else
		&XAO_(needs286),
#endif
		&XAOi_(xlatb),
		&XAOi_(esc_0),
		&XAOi_(esc_1),
		&XAOi_(esc_2),
		&XAOi_(esc_3),
		&XAOi_(esc_4),
		&XAOi_(esc_5),
		&XAOi_(esc_6),
		&XAOi_(esc_7),

		// 0xe_
		&XAOi_(loopnz_rel8),
		&XAOi_(loopz_rel8),
		&XAOi_(loop_rel8),
		&XAOi_(jrcxz_rel8),
		&XAOi_(in_al_i8),
		&XAOi_(in_rax_i8),
		&XAOi_(out_i8_al),
		&XAOi_(out_i8_rax),
		&XAOi_(call_relOP),
		&XAOi_(jmp_relOP),
		&XAOi_(jmp_ptr16OP),
		&XAOi_(jmp_rel8),
		&XAOi_(in_al_dx),
		&XAOi_(in_rax_dx),
		&XAOi_(out_dx_al),
		&XAOi_(out_dx_rax),

		// 0xf_
		&i_unimpl, // lock:
		&i_unimpl, // int1/icebp
		&XAOi_(repnz),
		&XAOi_(rep),
		&XAOi_(hlt),
		&XAOi_(cmc),
		&XAOi_(groupf6_rm8),
		&XAOi_(groupf7_rmOP),
		&XAOi_(clc),
		&XAOi_(stc),
		&XAOi_(cli),
		&XAOi_(sti),
		&XAOi_(cld),
		&XAOi_(std),
		&XAOi_(groupfe_rm8),
		&XAOi_(groupff_rmOP)
	};

#if CPU >= X86_286
	void (*const XAO_(Ops_0f)[256])() = {
		// 0x0f 0x0_
		&XAOi_(group0f00),
		&XAOi_(group0f01),
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x1_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x2_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x3_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x4_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x5_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x6_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x7_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0x8_
#if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
		&XAO_(needs386),
#else
		&XAOi_(jo_relOP),
		&XAOi_(jno_relOP),
		&XAOi_(jc_relOP),
		&XAOi_(jnc_relOP),
		&XAOi_(jz_relOP),
		&XAOi_(jnz_relOP),
		&XAOi_(jbe_relOP),
		&XAOi_(jnbe_relOP),
		&XAOi_(js_relOP),
		&XAOi_(jns_relOP),
		&XAOi_(jp_relOP),
		&XAOi_(jnp_relOP),
		&XAOi_(jl_relOP),
		&XAOi_(jnl_relOP),
		&XAOi_(jle_relOP),
		&XAOi_(jnle_relOP),
#endif

		// 0x0f 0x9_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xa_
#if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
#else
		&XAOi_(push_fs),
		&XAOi_(pop_fs),
#endif
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
#if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
#else
		&XAOi_(push_gs),
		&XAOi_(pop_gs),
#endif
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xb_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
#if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
#else
		&XAOi_(movzx_rOP_rm8),
		&XAOi_(movzx_rOP_rm16),
#endif
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
#if CPU < X86_386
		&XAO_(needs386),
		&XAO_(needs386),
#else
		&XAOi_(bsf_rOP_rmOP),
		&XAOi_(bsr_rOP_rmOP),
#endif
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xc_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xd_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xe_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,

		// 0x0f 0xf_
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
		&i_unimpl,
	};
#endif*/

	void XAO_(FillOpcodeTables)() {
		ZSSERT(Config::CpuLevel == CPU);

		AO_(Ops)[0x00] = &XAOi_(add_rm8_r8);
		AO_(Ops)[0x01] = &XAOi_(add_rmOP_rOP);
		AO_(Ops)[0x02] = &XAOi_(add_r8_rm8);
		AO_(Ops)[0x03] = &XAOi_(add_rOP_rmOP);
		AO_(Ops)[0x04] = &XAOi_(add_al_i8);
		AO_(Ops)[0x05] = &XAOi_(add_rax_iOP);
		AO_(Ops)[0x06] = &XAOi_(push_es);
		AO_(Ops)[0x07] = &XAOi_(pop_es);
		AO_(Ops)[0x08] = &XAOi_(or_rm8_r8);
		AO_(Ops)[0x09] = &XAOi_(or_rmOP_rOP);
		AO_(Ops)[0x0a] = &XAOi_(or_r8_rm8);
		AO_(Ops)[0x0b] = &XAOi_(or_rOP_rmOP);
		AO_(Ops)[0x0c] = &XAOi_(or_al_i8);
		AO_(Ops)[0x0d] = &XAOi_(or_rax_iOP);
		AO_(Ops)[0x0e] = &XAOi_(push_cs);
		AO_(Ops)[0x0f] = &XAOi_(pop_cs);
		AO_(Ops)[0x10] = &XAOi_(adc_rm8_r8);
		AO_(Ops)[0x11] = &XAOi_(adc_rmOP_rOP);
		AO_(Ops)[0x12] = &XAOi_(adc_r8_rm8);
		AO_(Ops)[0x13] = &XAOi_(adc_rOP_rmOP);
		AO_(Ops)[0x14] = &XAOi_(adc_al_i8);
		AO_(Ops)[0x15] = &XAOi_(adc_rax_iOP);
		AO_(Ops)[0x16] = &XAOi_(push_ss);
		AO_(Ops)[0x17] = &XAOi_(pop_ss);
		AO_(Ops)[0x18] = &XAOi_(sbb_rm8_r8);
		AO_(Ops)[0x19] = &XAOi_(sbb_rmOP_rOP);
		AO_(Ops)[0x1a] = &XAOi_(sbb_r8_rm8);
		AO_(Ops)[0x1b] = &XAOi_(sbb_rOP_rmOP);
		AO_(Ops)[0x1c] = &XAOi_(sbb_al_i8);
		AO_(Ops)[0x1d] = &XAOi_(sbb_rax_iOP);
		AO_(Ops)[0x1e] = &XAOi_(push_ds);
		AO_(Ops)[0x1f] = &XAOi_(pop_ds);
		AO_(Ops)[0x20] = &XAOi_(and_rm8_r8);
		AO_(Ops)[0x21] = &XAOi_(and_rmOP_rOP);
		AO_(Ops)[0x22] = &XAOi_(and_r8_rm8);
		AO_(Ops)[0x23] = &XAOi_(and_rOP_rmOP);
		AO_(Ops)[0x24] = &XAOi_(and_al_i8);
		AO_(Ops)[0x25] = &XAOi_(and_rax_iOP);
		AO_(Ops)[0x26] = &XAOi_(pre_es);
		AO_(Ops)[0x27] = &XAOi_(daa);
		AO_(Ops)[0x28] = &XAOi_(sub_rm8_r8);
		AO_(Ops)[0x29] = &XAOi_(sub_rmOP_rOP);
		AO_(Ops)[0x2a] = &XAOi_(sub_r8_rm8);
		AO_(Ops)[0x2b] = &XAOi_(sub_rOP_rmOP);
		AO_(Ops)[0x2c] = &XAOi_(sub_al_i8);
		AO_(Ops)[0x2d] = &XAOi_(sub_rax_iOP);
		AO_(Ops)[0x2e] = &XAOi_(pre_cs);
		AO_(Ops)[0x2f] = &XAOi_(das);
		AO_(Ops)[0x30] = &XAOi_(xor_rm8_r8);
		AO_(Ops)[0x31] = &XAOi_(xor_rmOP_rOP);
		AO_(Ops)[0x32] = &XAOi_(xor_r8_rm8);
		AO_(Ops)[0x33] = &XAOi_(xor_rOP_rmOP);
		AO_(Ops)[0x34] = &XAOi_(xor_al_i8);
		AO_(Ops)[0x35] = &XAOi_(xor_rax_iOP);
		AO_(Ops)[0x36] = &XAOi_(pre_ss);
		AO_(Ops)[0x37] = &XAOi_(aaa);
		AO_(Ops)[0x38] = &XAOi_(cmp_rm8_r8);
		AO_(Ops)[0x39] = &XAOi_(cmp_rmOP_rOP);
		AO_(Ops)[0x3a] = &XAOi_(cmp_r8_rm8);
		AO_(Ops)[0x3b] = &XAOi_(cmp_rOP_rmOP);
		AO_(Ops)[0x3c] = &XAOi_(cmp_al_i8);
		AO_(Ops)[0x3d] = &XAOi_(cmp_rax_iOP);
		AO_(Ops)[0x3e] = &XAOi_(pre_ds);
		AO_(Ops)[0x3f] = &XAOi_(aas);
		AO_(Ops)[0x40] = &XAOi_(inc_rax);
		AO_(Ops)[0x41] = &XAOi_(inc_rcx);
		AO_(Ops)[0x42] = &XAOi_(inc_rdx);
		AO_(Ops)[0x43] = &XAOi_(inc_rbx);
		AO_(Ops)[0x44] = &XAOi_(inc_rsp);
		AO_(Ops)[0x45] = &XAOi_(inc_rbp);
		AO_(Ops)[0x46] = &XAOi_(inc_rsi);
		AO_(Ops)[0x47] = &XAOi_(inc_rdi);
		AO_(Ops)[0x48] = &XAOi_(dec_rax);
		AO_(Ops)[0x49] = &XAOi_(dec_rcx);
		AO_(Ops)[0x4a] = &XAOi_(dec_rdx);
		AO_(Ops)[0x4b] = &XAOi_(dec_rbx);
		AO_(Ops)[0x4c] = &XAOi_(dec_rsp);
		AO_(Ops)[0x4d] = &XAOi_(dec_rbp);
		AO_(Ops)[0x4e] = &XAOi_(dec_rsi);
		AO_(Ops)[0x4f] = &XAOi_(dec_rdi);
		AO_(Ops)[0x50] = &XAOi_(push_rax);
		AO_(Ops)[0x51] = &XAOi_(push_rcx);
		AO_(Ops)[0x52] = &XAOi_(push_rdx);
		AO_(Ops)[0x53] = &XAOi_(push_rbx);
		AO_(Ops)[0x54] = &XAOi_(push_rsp);
		AO_(Ops)[0x55] = &XAOi_(push_rbp);
		AO_(Ops)[0x56] = &XAOi_(push_rsi);
		AO_(Ops)[0x57] = &XAOi_(push_rdi);
		AO_(Ops)[0x58] = &XAOi_(pop_rax);
		AO_(Ops)[0x59] = &XAOi_(pop_rcx);
		AO_(Ops)[0x5a] = &XAOi_(pop_rdx);
		AO_(Ops)[0x5b] = &XAOi_(pop_rbx);
		AO_(Ops)[0x5c] = &XAOi_(pop_rsp);
		AO_(Ops)[0x5d] = &XAOi_(pop_rbp);
		AO_(Ops)[0x5e] = &XAOi_(pop_rsi);
		AO_(Ops)[0x5f] = &XAOi_(pop_rdi);
		AO_(Ops)[0x60] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(pushav);
		AO_(Ops)[0x61] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(popav);
		AO_(Ops)[0x62] = CPU < X86_186 ? XAO_(needs186) : &XAO_(raiseUD_Msg); // bound
		AO_(Ops)[0x63] = CPU < X86_286 ? XAO_(needs286) : &XAOi_(arpl_rm16_r16);
		AO_(Ops)[0x64] = CPU < X86_386 ? XAO_(needs386) : &XAO_(raiseUD_Msg); // fs:
		AO_(Ops)[0x65] = CPU < X86_386 ? XAO_(needs386) : &XAO_(raiseUD_Msg); // gs:
		AO_(Ops)[0x66] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(pre_opsize);
		AO_(Ops)[0x67] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(pre_adsize);
		AO_(Ops)[0x68] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(push_iOP);
		AO_(Ops)[0x69] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(imul_rOP_rmOP_iOP);
		AO_(Ops)[0x6a] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(push_si8);
		AO_(Ops)[0x6b] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(imul_rOP_rmOP_si8);
		AO_(Ops)[0x6c] = CPU < X86_186 ? XAO_(needs186) : &XAO_(raiseUD_Msg); // ins
		AO_(Ops)[0x6d] = CPU < X86_186 ? XAO_(needs186) : &XAO_(raiseUD_Msg); // ins
		AO_(Ops)[0x6e] = CPU < X86_186 ? XAO_(needs186) : &XAO_(raiseUD_Msg); // outs
		AO_(Ops)[0x6f] = CPU < X86_186 ? XAO_(needs186) : &XAO_(raiseUD_Msg); // outs
		AO_(Ops)[0x70] = &XAOi_(jo_rel8);
		AO_(Ops)[0x71] = &XAOi_(jno_rel8);
		AO_(Ops)[0x72] = &XAOi_(jc_rel8);
		AO_(Ops)[0x73] = &XAOi_(jnc_rel8);
		AO_(Ops)[0x74] = &XAOi_(jz_rel8);
		AO_(Ops)[0x75] = &XAOi_(jnz_rel8);
		AO_(Ops)[0x76] = &XAOi_(jbe_rel8);
		AO_(Ops)[0x77] = &XAOi_(jnbe_rel8);
		AO_(Ops)[0x78] = &XAOi_(js_rel8);
		AO_(Ops)[0x79] = &XAOi_(jns_rel8);
		AO_(Ops)[0x7a] = &XAOi_(jp_rel8);
		AO_(Ops)[0x7b] = &XAOi_(jnp_rel8);
		AO_(Ops)[0x7c] = &XAOi_(jl_rel8);
		AO_(Ops)[0x7d] = &XAOi_(jnl_rel8);
		AO_(Ops)[0x7e] = &XAOi_(jle_rel8);
		AO_(Ops)[0x7f] = &XAOi_(jnle_rel8);
		AO_(Ops)[0x80] = &XAOi_(group80_rm8_i8);
		AO_(Ops)[0x81] = &XAOi_(group81_rmOP_iOP);
		AO_(Ops)[0x82] = &XAO_(raiseUD_Msg); // alias for 80? VERIFY!!
		AO_(Ops)[0x83] = &XAOi_(group83_rmOP_si8);
		AO_(Ops)[0x84] = &XAOi_(test_rm8_r8);
		AO_(Ops)[0x85] = &XAOi_(test_rmOP_rOP);
		AO_(Ops)[0x86] = &XAOi_(xchg_rm8_r8);
		AO_(Ops)[0x87] = &XAOi_(xchg_rmOP_rOP);
		AO_(Ops)[0x88] = &XAOi_(mov_rm8_r8);
		AO_(Ops)[0x89] = &XAOi_(mov_rmOP_rOP);
		AO_(Ops)[0x8a] = &XAOi_(mov_r8_rm8);
		AO_(Ops)[0x8b] = &XAOi_(mov_rOP_rmOP);
		AO_(Ops)[0x8c] = &XAOi_(mov_rm16_sreg);
		AO_(Ops)[0x8d] = &XAOi_(lea_rOP_m);
		AO_(Ops)[0x8e] = &XAOi_(mov_sreg_rm16);
		AO_(Ops)[0x8f] = &XAOi_(pop_mOP);
		AO_(Ops)[0x90] = &XAOi_(nop);
		AO_(Ops)[0x91] = &XAOi_(xchg_rax_rcx);
		AO_(Ops)[0x92] = &XAOi_(xchg_rax_rdx);
		AO_(Ops)[0x93] = &XAOi_(xchg_rax_rbx);
		AO_(Ops)[0x94] = &XAOi_(xchg_rax_rsp);
		AO_(Ops)[0x95] = &XAOi_(xchg_rax_rbp);
		AO_(Ops)[0x96] = &XAOi_(xchg_rax_rsi);
		AO_(Ops)[0x97] = &XAOi_(xchg_rax_rdi);
		AO_(Ops)[0x98] = &XAOi_(cbw);
		AO_(Ops)[0x99] = &XAOi_(cwd);
		AO_(Ops)[0x9a] = &XAOi_(call_ptr16OP);
		AO_(Ops)[0x9b] = &XAO_(raiseUD_Msg); // wait
		AO_(Ops)[0x9c] = &XAOi_(pushfv);
		AO_(Ops)[0x9d] = &XAOi_(popfv);
		AO_(Ops)[0x9e] = &XAOi_(sahf);
		AO_(Ops)[0x9f] = &XAOi_(lahf);
		AO_(Ops)[0xa0] = &XAOi_(mov_al_moffs8);
		AO_(Ops)[0xa1] = &XAOi_(mov_rax_moffsOP);
		AO_(Ops)[0xa2] = &XAOi_(mov_moffs8_al);
		AO_(Ops)[0xa3] = &XAOi_(mov_moffsOP_rax);
		AO_(Ops)[0xa4] = &XAOi_(movsb);
		AO_(Ops)[0xa5] = &XAOi_(movsv);
		AO_(Ops)[0xa6] = &XAOi_(cmpsb);
		AO_(Ops)[0xa7] = &XAOi_(cmpsv);
		AO_(Ops)[0xa8] = &XAOi_(test_al_i8);
		AO_(Ops)[0xa9] = &XAOi_(test_rax_iOP);
		AO_(Ops)[0xaa] = &XAOi_(stosb);
		AO_(Ops)[0xab] = &XAOi_(stosv);
		AO_(Ops)[0xac] = &XAOi_(lodsb);
		AO_(Ops)[0xad] = &XAOi_(lodsv);
		AO_(Ops)[0xae] = &XAOi_(scasb);
		AO_(Ops)[0xaf] = &XAOi_(scasv);
		AO_(Ops)[0xb0] = &XAOi_(mov_al_i8);
		AO_(Ops)[0xb1] = &XAOi_(mov_cl_i8);
		AO_(Ops)[0xb2] = &XAOi_(mov_dl_i8);
		AO_(Ops)[0xb3] = &XAOi_(mov_bl_i8);
		AO_(Ops)[0xb4] = &XAOi_(mov_ah_i8);
		AO_(Ops)[0xb5] = &XAOi_(mov_ch_i8);
		AO_(Ops)[0xb6] = &XAOi_(mov_dh_i8);
		AO_(Ops)[0xb7] = &XAOi_(mov_bh_i8);
		AO_(Ops)[0xb8] = &XAOi_(mov_rax_iOP);
		AO_(Ops)[0xb9] = &XAOi_(mov_rcx_iOP);
		AO_(Ops)[0xba] = &XAOi_(mov_rdx_iOP);
		AO_(Ops)[0xbb] = &XAOi_(mov_rbx_iOP);
		AO_(Ops)[0xbc] = &XAOi_(mov_rsp_iOP);
		AO_(Ops)[0xbd] = &XAOi_(mov_rbp_iOP);
		AO_(Ops)[0xbe] = &XAOi_(mov_rsi_iOP);
		AO_(Ops)[0xbf] = &XAOi_(mov_rdi_iOP);
		AO_(Ops)[0xc0] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(groupc0_rm8_i8);
		AO_(Ops)[0xc1] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(groupc1_rmOP_i8);
		AO_(Ops)[0xc2] = &XAOi_(ret_i16);
		AO_(Ops)[0xc3] = &XAOi_(ret);
		AO_(Ops)[0xc4] = &XAOi_(les_rOP_m16OP);
		AO_(Ops)[0xc5] = &XAOi_(lds_rOP_m16OP);
		AO_(Ops)[0xc6] = &XAOi_(mov_rm8_i8);
		AO_(Ops)[0xc7] = &XAOi_(mov_rmOP_iOP);
		AO_(Ops)[0xc8] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(enter_i16_i8);
		AO_(Ops)[0xc9] = CPU < X86_186 ? XAO_(needs186) : &XAOi_(leave);
		AO_(Ops)[0xca] = &XAOi_(retfv_i16);
		AO_(Ops)[0xcb] = &XAOi_(retfv);
		AO_(Ops)[0xcc] = &XAO_(raiseUD_Msg); // int3
		AO_(Ops)[0xcd] = &XAOi_(int_i8);
		AO_(Ops)[0xce] = &XAO_(raiseUD_Msg); // into
		AO_(Ops)[0xcf] = &XAOi_(iretv);
		AO_(Ops)[0xd0] = &XAOi_(groupd0_rm8_1);
		AO_(Ops)[0xd1] = &XAOi_(groupd1_rmOP_1);
		AO_(Ops)[0xd2] = &XAOi_(groupd2_rm8_cl);
		AO_(Ops)[0xd3] = &XAOi_(groupd3_rmOP_cl);
		AO_(Ops)[0xd4] = &XAOi_(aam_i8);
		AO_(Ops)[0xd5] = &XAOi_(aad_i8);
		AO_(Ops)[0xd6] = CPU < X86_286 ? XAO_(needs286) : &XAOi_(salc);
		AO_(Ops)[0xd7] = &XAOi_(xlatb);
		AO_(Ops)[0xd8] = &XAOi_(esc_0);
		AO_(Ops)[0xd9] = &XAOi_(esc_1);
		AO_(Ops)[0xda] = &XAOi_(esc_2);
		AO_(Ops)[0xdb] = &XAOi_(esc_3);
		AO_(Ops)[0xdc] = &XAOi_(esc_4);
		AO_(Ops)[0xdd] = &XAOi_(esc_5);
		AO_(Ops)[0xde] = &XAOi_(esc_6);
		AO_(Ops)[0xdf] = &XAOi_(esc_7);
		AO_(Ops)[0xe0] = &XAOi_(loopnz_rel8);
		AO_(Ops)[0xe1] = &XAOi_(loopz_rel8);
		AO_(Ops)[0xe2] = &XAOi_(loop_rel8);
		AO_(Ops)[0xe3] = &XAOi_(jrcxz_rel8);
		AO_(Ops)[0xe4] = &XAOi_(in_al_i8);
		AO_(Ops)[0xe5] = &XAOi_(in_rax_i8);
		AO_(Ops)[0xe6] = &XAOi_(out_i8_al);
		AO_(Ops)[0xe7] = &XAOi_(out_i8_rax);
		AO_(Ops)[0xe8] = &XAOi_(call_relOP);
		AO_(Ops)[0xe9] = &XAOi_(jmp_relOP);
		AO_(Ops)[0xea] = &XAOi_(jmp_ptr16OP);
		AO_(Ops)[0xeb] = &XAOi_(jmp_rel8);
		AO_(Ops)[0xec] = &XAOi_(in_al_dx);
		AO_(Ops)[0xed] = &XAOi_(in_rax_dx);
		AO_(Ops)[0xee] = &XAOi_(out_dx_al);
		AO_(Ops)[0xef] = &XAOi_(out_dx_rax);
		AO_(Ops)[0xf0] = &XAO_(raiseUD_Msg); // lock
		AO_(Ops)[0xf1] = &XAO_(raiseUD_Msg); // int1/icebp
		AO_(Ops)[0xf2] = &XAOi_(repnz);
		AO_(Ops)[0xf3] = &XAOi_(rep);
		AO_(Ops)[0xf4] = &XAOi_(hlt);
		AO_(Ops)[0xf5] = &XAOi_(cmc);
		AO_(Ops)[0xf6] = &XAOi_(groupf6_rm8);
		AO_(Ops)[0xf7] = &XAOi_(groupf7_rmOP);
		AO_(Ops)[0xf8] = &XAOi_(clc);
		AO_(Ops)[0xf9] = &XAOi_(stc);
		AO_(Ops)[0xfa] = &XAOi_(cli);
		AO_(Ops)[0xfb] = &XAOi_(sti);
		AO_(Ops)[0xfc] = &XAOi_(cld);
		AO_(Ops)[0xfd] = &XAOi_(std);
		AO_(Ops)[0xfe] = &XAOi_(groupfe_rm8);
		AO_(Ops)[0xff] = &XAOi_(groupff_rmOP);

#if CPU >= X86_286
		AO_(Ops_0f)[0x00] = &XAOi_(group0f00_rm16);
		AO_(Ops_0f)[0x01] = &XAOi_(group0f01);
		AO_(Ops_0f)[0x02] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x03] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x04] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x05] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x06] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x07] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x08] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x09] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x0f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x10] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x11] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x12] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x13] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x14] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x15] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x16] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x17] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x18] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x19] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x1f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x20] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_r32_crx);
		AO_(Ops_0f)[0x21] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_r32_drx);
		AO_(Ops_0f)[0x22] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_crx_r32);
		AO_(Ops_0f)[0x23] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_drx_r32);
		AO_(Ops_0f)[0x24] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_r32_trx);
		AO_(Ops_0f)[0x25] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x26] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(mov_trx_r32);
		AO_(Ops_0f)[0x27] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x28] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x29] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x2f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x30] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x31] = CPU < X86_P1 ? XAO_(needsp1) : &XAOi_(rdtsc);
		AO_(Ops_0f)[0x32] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x33] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x34] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x35] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x36] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x37] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x38] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x39] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x3f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x40] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x41] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x42] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x43] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x44] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x45] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x46] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x47] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x48] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x49] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x4f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x50] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x51] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x52] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x53] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x54] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x55] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x56] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x57] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x58] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x59] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x5f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x60] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x61] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x62] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x63] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x64] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x65] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x66] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x67] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x68] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x69] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x6f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x70] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x71] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x72] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x73] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x74] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x75] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x76] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x77] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x78] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x79] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x7f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x80] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jo_relOP);
		AO_(Ops_0f)[0x81] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jno_relOP);
		AO_(Ops_0f)[0x82] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jc_relOP);
		AO_(Ops_0f)[0x83] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnc_relOP);
		AO_(Ops_0f)[0x84] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jz_relOP);
		AO_(Ops_0f)[0x85] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnz_relOP);
		AO_(Ops_0f)[0x86] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jbe_relOP);
		AO_(Ops_0f)[0x87] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnbe_relOP);
		AO_(Ops_0f)[0x88] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(js_relOP);
		AO_(Ops_0f)[0x89] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jns_relOP);
		AO_(Ops_0f)[0x8a] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jp_relOP);
		AO_(Ops_0f)[0x8b] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnp_relOP);
		AO_(Ops_0f)[0x8c] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jl_relOP);
		AO_(Ops_0f)[0x8d] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnl_relOP);
		AO_(Ops_0f)[0x8e] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jle_relOP);
		AO_(Ops_0f)[0x8f] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(jnle_relOP);
		AO_(Ops_0f)[0x90] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x91] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x92] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x93] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x94] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x95] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x96] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x97] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x98] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x99] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9a] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9b] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9c] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9d] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9e] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0x9f] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xa0] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(push_fs);
		AO_(Ops_0f)[0xa1] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(pop_fs);
		AO_(Ops_0f)[0xa2] = CPU < X86_486 ? XAO_(raiseUD) : &XAOi_(cpuid);
		AO_(Ops_0f)[0xa3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xa4] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(shld_rmOP_rOP_i8);
		AO_(Ops_0f)[0xa5] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(shld_rmOP_rOP_cl);
		AO_(Ops_0f)[0xa6] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xa7] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xa8] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(push_gs);
		AO_(Ops_0f)[0xa9] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(pop_gs);
		AO_(Ops_0f)[0xaa] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xab] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xac] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(shrd_rmOP_rOP_i8);
		AO_(Ops_0f)[0xad] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(shrd_rmOP_rOP_cl);
		AO_(Ops_0f)[0xae] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xaf] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb0] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb1] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb2] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb4] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb5] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb6] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(movzx_rOP_rm8);
		AO_(Ops_0f)[0xb7] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(movzx_rOP_rm16);
		AO_(Ops_0f)[0xb8] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xb9] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xba] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xbb] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xbc] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(bsf_rOP_rmOP);
		AO_(Ops_0f)[0xbd] = CPU < X86_386 ? XAO_(needs386) : &XAOi_(bsr_rOP_rmOP);
		AO_(Ops_0f)[0xbe] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xbf] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc0] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc1] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc2] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc4] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc5] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc6] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc7] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc8] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xc9] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xca] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xcb] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xcc] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xcd] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xce] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xcf] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd0] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd1] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd2] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd4] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd5] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd6] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd7] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd8] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xd9] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xda] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xdb] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xdc] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xdd] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xde] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xdf] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe0] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe1] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe2] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe4] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe5] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe6] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe7] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe8] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xe9] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xea] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xeb] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xec] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xed] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xee] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xef] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf0] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf1] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf2] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf3] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf4] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf5] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf6] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf7] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf8] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xf9] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xfa] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xfb] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xfc] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xfd] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xfe] = &XAO_(raiseUD_Msg);
		AO_(Ops_0f)[0xff] = &XAO_(raiseUD_Msg);
#endif
	}

#ifdef X86_ONCE_PER_PROCESSOR
	void X_(FillOpcodeTables)() {
		X_(real1616_FillOpcodeTables)();
  #if CPU >= X86_386
		X_(real3216_FillOpcodeTables)();
		X_(real1632_FillOpcodeTables)();
		X_(real3232_FillOpcodeTables)();
  #endif
	}
#endif
}}