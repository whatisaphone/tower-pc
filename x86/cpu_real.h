// included from cpu.h
#include "real_a_o.hpp"
//#include "flags.hpp"

//	extern void (*XAO_(Ops)[256])();
//#if CPU >= X86_286
//	extern void (*XAO_(Ops_0f)[256])();
//#endif
#ifdef X86_ONCE_PER_PROCESSOR
	void X_(FillOpcodeTables)();
#endif

	void XAO_(Loop)();
	void XAO_(StepPrefix)();

#include "real_a_o_cleanup.hpp"







///* 00    */	void XAOi_(add_rm8_r8)();
///* 01    */	void XAOi_(add_rmOP_rOP)();
///* 02    */	void XAOi_(add_r8_rm8)();
///* 03    */	void XAOi_(add_rOP_rmOP)();
///* 04    */	void XAOi_(add_al_i8)();
///* 05    */	void XAOi_(add_rax_iOP)();
///* 06    */	void XAOi_(push_es)();
///* 07    */	void XAOi_(pop_es)();
///* 08    */	void XAOi_(or_rm8_r8)();
///* 09    */	void XAOi_(or_rmOP_rOP)();
///* 0a    */	void XAOi_(or_r8_rm8)();
///* 0b    */	void XAOi_(or_rOP_rmOP)();
///* 0c    */	void XAOi_(or_al_i8)();
///* 0d    */	void XAOi_(or_rax_iOP)();
///* 0e    */	void XAOi_(push_cs)();
///* 0f    */	void XAOi_(pop_cs)();
///* 10    */	void XAOi_(adc_rm8_r8)();
///* 11    */	void XAOi_(adc_rmOP_rOP)();
///* 12    */	void XAOi_(adc_r8_rm8)();
///* 13    */	void XAOi_(adc_rOP_rmOP)();
///* 14    */	void XAOi_(adc_al_i8)();
///* 15    */	void XAOi_(adc_rax_iOP)();
///* 16    */	void XAOi_(push_ss)();
///* 17    */	void XAOi_(pop_ss)();
///* 18    */	void XAOi_(sbb_rm8_r8)();
///* 19    */	void XAOi_(sbb_rmOP_rOP)();
///* 1a    */	void XAOi_(sbb_r8_rm8)();
///* 1b    */	void XAOi_(sbb_rOP_rmOP)();
///* 1c    */	void XAOi_(sbb_al_i8)();
///* 1d    */	void XAOi_(sbb_rax_iOP)();
///* 1e    */	void XAOi_(push_ds)();
///* 1f    */	void XAOi_(pop_ds)();
///* 20    */	void XAOi_(and_rm8_r8)();
///* 21    */	void XAOi_(and_rmOP_rOP)();
///* 22    */	void XAOi_(and_r8_rm8)();
///* 23    */	void XAOi_(and_rOP_rmOP)();
///* 24    */	void XAOi_(and_al_i8)();
///* 25    */	void XAOi_(and_rax_iOP)();
///* 26    */	void XAOi_(pre_es)();
///* 27    */	void XAOi_(daa)();
///* 28    */	void XAOi_(sub_rm8_r8)();
///* 29    */	void XAOi_(sub_rmOP_rOP)();
///* 2a    */	void XAOi_(sub_r8_rm8)();
///* 2b    */	void XAOi_(sub_rOP_rmOP)();
///* 2c    */	void XAOi_(sub_al_i8)();
///* 2d    */	void XAOi_(sub_rax_iOP)();
///* 2e    */	void XAOi_(pre_cs)();
///* 2f    */
///* 30    */	void XAOi_(xor_rm8_r8)();
///* 31    */	void XAOi_(xor_rmOP_rOP)();
///* 32    */	void XAOi_(xor_r8_rm8)();
///* 33    */	void XAOi_(xor_rOP_rmOP)();
///* 34    */	void XAOi_(xor_al_i8)();
///* 35    */	void XAOi_(xor_rax_iOP)();
///* 36    */	void XAOi_(pre_ss)();
///* 37    */
///* 38    */	void XAOi_(cmp_rm8_r8)();
///* 39    */	void XAOi_(cmp_rmOP_rOP)();
///* 3a    */	void XAOi_(cmp_r8_rm8)();
///* 3b    */	void XAOi_(cmp_rOP_rmOP)();
///* 3c    */	void XAOi_(cmp_al_i8)();
///* 3d    */	void XAOi_(cmp_rax_iOP)();
///* 3e    */	void XAOi_(pre_ds)();
///* 3f    */
///* 40    */	void XAOi_(inc_rax)();
///* 41    */	void XAOi_(inc_rcx)();
///* 42    */	void XAOi_(inc_rdx)();
///* 43    */	void XAOi_(inc_rbx)();
///* 44    */	void XAOi_(inc_rsp)();
///* 45    */	void XAOi_(inc_rbp)();
///* 46    */	void XAOi_(inc_rsi)();
///* 47    */	void XAOi_(inc_rdi)();
///* 48    */	void XAOi_(dec_rax)();
///* 49    */	void XAOi_(dec_rcx)();
///* 4a    */	void XAOi_(dec_rdx)();
///* 4b    */	void XAOi_(dec_rbx)();
///* 4c    */	void XAOi_(dec_rsp)();
///* 4d    */	void XAOi_(dec_rbp)();
///* 4e    */	void XAOi_(dec_rsi)();
///* 4f    */	void XAOi_(dec_rdi)();
///* 50    */	void XAOi_(push_rax)();
///* 51    */	void XAOi_(push_rcx)();
///* 52    */	void XAOi_(push_rdx)();
///* 53    */	void XAOi_(push_rbx)();
///* 54    */	void XAOi_(push_rsp)();
///* 55    */	void XAOi_(push_rbp)();
///* 56    */	void XAOi_(push_rsi)();
///* 57    */	void XAOi_(push_rdi)();
///* 58    */	void XAOi_(pop_rax)();
///* 59    */	void XAOi_(pop_rcx)();
///* 5a    */	void XAOi_(pop_rdx)();
///* 5b    */	void XAOi_(pop_rbx)();
///* 5c    */	void XAOi_(pop_rsp)();
///* 5d    */	void XAOi_(pop_rbp)();
///* 5e    */	void XAOi_(pop_rsi)();
///* 5f    */	void XAOi_(pop_rdi)();
///* 60    */	void XAOi_(pushav)();
///* 61    */	void XAOi_(popav)();
///* 62    */
///* 63    */
///* 64    */
///* 65    */
///* 66    */	void XAOi_(pre_opsize)();
///* 67    */	void XAOi_(pre_adsize)();
///* 68    */	void XAOi_(push_iOP)();
///* 69    */
///* 6a    */	void XAOi_(push_si8)();
///* 6b    */
///* 6c    */
///* 6d    */
///* 6e    */
///* 6f    */
///* 70    */	void XAOi_(jo_rel8)();
///* 71    */	void XAOi_(jno_rel8)();
///* 72    */	void XAOi_(jc_rel8)();
///* 73    */	void XAOi_(jnc_rel8)();
///* 74    */	void XAOi_(jz_rel8)();
///* 75    */	void XAOi_(jnz_rel8)();
///* 76    */	void XAOi_(jbe_rel8)();
///* 77    */	void XAOi_(jnbe_rel8)();
///* 78    */	void XAOi_(js_rel8)();
///* 79    */	void XAOi_(jns_rel8)();
///* 7a    */	void XAOi_(jp_rel8)();
///* 7b    */	void XAOi_(jnp_rel8)();
///* 7c    */	void XAOi_(jl_rel8)();
///* 7d    */	void XAOi_(jnl_rel8)();
///* 7e    */	void XAOi_(jle_rel8)();
///* 7f    */	void XAOi_(jnle_rel8)();
///* 80    */	void XAOi_(group80_rm8_i8)();
///* 81    */	void XAOi_(group81_rmOP_iOP)();
///* 82    */ // alias for 80
///* 83    */	void XAOi_(group83_rmOP_si8)();
///* 84    */	void XAOi_(test_rm8_r8)();
///* 85    */	void XAOi_(test_rmOP_rOP)();
///* 86    */	void XAOi_(xchg_rm8_r8)();
///* 87    */	void XAOi_(xchg_rmOP_rOP)();
///* 88    */	void XAOi_(mov_rm8_r8)();
///* 89    */	void XAOi_(mov_rmOP_rOP)();
///* 8a    */	void XAOi_(mov_r8_rm8)();
///* 8b    */	void XAOi_(mov_rOP_rmOP)();
///* 8c    */	void XAOi_(mov_rm16_sreg)();
///* 8d    */	void XAOi_(lea_rOP_m)();
///* 8e    */	void XAOi_(mov_sreg_rm16)();
///* 8f    */	void XAOi_(pop_mOP)();
///* 90    */	void XAOi_(nop)();
///* 91    */	void XAOi_(xchg_rax_rcx)();
///* 92    */	void XAOi_(xchg_rax_rdx)();
///* 93    */	void XAOi_(xchg_rax_rbx)();
///* 94    */	void XAOi_(xchg_rax_rsp)();
///* 95    */	void XAOi_(xchg_rax_rbp)();
///* 96    */	void XAOi_(xchg_rax_rsi)();
///* 97    */	void XAOi_(xchg_rax_rdi)();
///* 98    */	void XAOi_(cbw)();
///* 99    */	void XAOi_(cwd)();
///* 9a    */	void XAOi_(call_ptr16OP)();
///* 9b    */
///* 9c    */	void XAOi_(pushfv)();
///* 9d    */	void XAOi_(popfv)();
///* 9e    */	void XAOi_(sahf)();
///* 9f    */	void XAOi_(lahf)();
///* a0    */	void XAOi_(mov_al_moffs8)();
///* a1    */	void XAOi_(mov_rax_moffsOP)();
///* a2    */	void XAOi_(mov_moffs8_al)();
///* a3    */	void XAOi_(mov_moffsOP_rax)();
///* a4    */	void XAOi_(movsb)();
///* a5    */	void XAOi_(movsv)();
///* a6    */	void XAOi_(cmpsb)();
///* a7    */	void XAOi_(cmpsv)();
///* a8    */	void XAOi_(test_al_i8)();
///* a9    */	void XAOi_(test_rax_iOP)();
///* aa    */	void XAOi_(stosb)();
///* ab    */	void XAOi_(stosv)();
///* ac    */	void XAOi_(lodsb)();
///* ad    */	void XAOi_(lodsv)();
///* ae    */	void XAOi_(scasb)();
///* af    */	void XAOi_(scasv)();
///* b0    */	void XAOi_(mov_al_i8)();
///* b1    */	void XAOi_(mov_cl_i8)();
///* b2    */	void XAOi_(mov_dl_i8)();
///* b3    */	void XAOi_(mov_bl_i8)();
///* b4    */	void XAOi_(mov_ah_i8)();
///* b5    */	void XAOi_(mov_ch_i8)();
///* b6    */	void XAOi_(mov_dh_i8)();
///* b7    */	void XAOi_(mov_bh_i8)();
///* b8    */	void XAOi_(mov_rax_iOP)();
///* b9    */	void XAOi_(mov_rcx_iOP)();
///* ba    */	void XAOi_(mov_rdx_iOP)();
///* bb    */	void XAOi_(mov_rbx_iOP)();
///* bc    */	void XAOi_(mov_rsp_iOP)();
///* bd    */	void XAOi_(mov_rbp_iOP)();
///* be    */	void XAOi_(mov_rsi_iOP)();
///* bf    */	void XAOi_(mov_rdi_iOP)();
///* c0    */	void XAOi_(groupc0_rm8_i8)();
///* c1    */	void XAOi_(groupc1_rmOP_i8)();
///* c2    */	void XAOi_(ret_i16)();
///* c3    */	void XAOi_(ret)();
///* c4    */	void XAOi_(les_rOP_m16OP)();
///* c5    */	void XAOi_(lds_rOP_m16OP)();
///* c6    */ void XAOi_(mov_rm8_i8)();
///* c7    */	void XAOi_(mov_rmOP_iOP)();
///* c8    */	void XAOi_(enter_i16_i8)();
///* c9    */	void XAOi_(leave)();
///* ca    */	void XAOi_(retf_i16)();
///* cb    */	void XAOi_(retf)();
///* cc    */
///* cd    */	void XAOi_(int_i8)();
///* ce    */
///* cf    */	void XAOi_(iret)();
///* d0    */	void XAOi_(groupd0_rm8_1)();
///* d1    */	void XAOi_(groupd1_rmOP_1)();
///* d2    */	void XAOi_(groupd2_rm8_cl)();
///* d3    */	void XAOi_(groupd3_rmOP_cl)();
///* d4    */	void XAOi_(aam_i8)();
///* d5    */	void XAOi_(aad_i8)();
///* d6    */	void XAOi_(salc)();
///* d7    */	void XAOi_(xlatb)();
///* d8    */	void XAOi_(esc_0)();
///* d9    */	void XAOi_(esc_1)();
///* da    */	void XAOi_(esc_2)();
///* db    */	void XAOi_(esc_3)();
///* dc    */	void XAOi_(esc_4)();
///* dd    */	void XAOi_(esc_5)();
///* de    */	void XAOi_(esc_6)();
///* df    */	void XAOi_(esc_7)();
///* e0    */	void XAOi_(loopnz_rel8)();
///* e1    */	void XAOi_(loopz_rel8)();
///* e2    */	void XAOi_(loop_rel8)();
///* e3    */	void XAOi_(jrcxz_rel8)();
///* e4    */	void XAOi_(in_al_i8)();
///* e5    */	void XAOi_(in_rax_i8)();
///* e6    */	void XAOi_(out_i8_al)();
///* e7    */	void XAOi_(out_i8_rax)();
///* e8    */	void XAOi_(call_relOP)();
///* e9    */	void XAOi_(jmp_relOP)();
///* ea    */	void XAOi_(jmp_ptr16OP)();
///* eb    */	void XAOi_(jmp_rel8)();
///* ec    */	void XAOi_(in_al_dx)();
///* ed    */	void XAOi_(in_rax_dx)();
///* ee    */	void XAOi_(out_dx_al)();
///* ef    */	void XAOi_(out_dx_rax)();
///* f0    */
///* f1    */
///* f2    */	void XAOi_(repnz)();
///* f3    */	void XAOi_(rep)();
///* f4    */	void XAOi_(hlt)();
///* f5    */	void XAOi_(cmc)();
///* f6    */	void XAOi_(groupf6_rm8)();
///* f7    */	void XAOi_(groupf7_rmOP)();
///* f8    */	void XAOi_(clc)();
///* f9    */	void XAOi_(stc)();
///* fa    */	void XAOi_(cli)();
///* fb    */	void XAOi_(sti)();
///* fc    */	void XAOi_(cld)();
///* fd    */	void XAOi_(std)();
///* fe    */	void XAOi_(groupfe_rm8)();
///* ff    */	void XAOi_(groupff_rmOP)();