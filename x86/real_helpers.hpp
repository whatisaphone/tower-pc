#undef X86_RENDER_CSIP
#define X86_RENDER_CSIP() L"[" + Piston::String::Renderhex(cs->selector).PadLeft(4, L'0') + \
	L":" + Piston::String::Renderhex(PICK_ADSIZE(*ip, *eip)).PadLeft(ADSIZE / 4, L'0') + L"] "

namespace Tower { namespace X86 {
	inline void XAOi__(jcc_rel8)(int8 do_it, sint8 where) {
		if(do_it) PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + where);
	}

	inline void XAOi__(jcc_rel16)(int8 do_it, sint16 where) {
		if(do_it) PICK_CPUBITS(*ip, *eip) = (intOP)(PICK_CPUBITS(*ip, *eip) + where);
	}

	inline void XAOi__(push16)(int16 value) {
#ifndef X86_BLAZING
		if(PICK_ADSIZE(*sp, *esp) == 1)
			throw 0; // processor shuts down due to lack of stack space
#endif
		PICK_ADSIZE(*sp, *esp) -= 2;
		mem_write16_NSO(*ss, PICK_ADSIZE(*sp, *esp), value);
	}

	inline int16 XAOi__(pop16)() {
		int16 ret = mem_read16_NSO(*ss, PICK_ADSIZE(*sp, *esp));
		PICK_ADSIZE(*sp, *esp) += 2;
		return ret;
	}

#if CPU >= X86_386
	inline void XAOi__(jcc_rel32)(int8 do_it, sint32 where) {
		if(do_it) *eip += where;
	}

	inline void XAOi__(push32)(int32 value) {
		ZSSERT(OPSIZE == 32);
#ifndef X86_BLAZING
		if(PICK_ADSIZE(*sp, *esp) == 1)
			throw 0; // processor shuts down due to lack of stack space
#endif
		PICK_ADSIZE(*sp, *esp) -= 4;
		mem_write32_NSO(*ss, PICK_ADSIZE(*sp, *esp), value);
	}

	inline int32 XAOi__(pop32)() {
		ZSSERT(OPSIZE == 32);
		int32 ret = mem_read32_NSO(*ss, PICK_ADSIZE(*sp, *esp));
		PICK_ADSIZE(*sp, *esp) += 4;
		return ret;
	}
#endif

	inline void XAO_(interrupt)(int8 vector) {
		XAOi__(push16)(*flags);
#if CPU < X86_486
		PICK_CPUBITS(*flags, *eflags) &= ~(flags_mask_if | flags_mask_tf);
#else
		PICK_CPUBITS(*flags, *eflags) &= ~(flags_mask_if | flags_mask_tf | flags_mask_ac);
#endif
//#ifdef _DEBUG
//		if(vector != 0xff && vector != 0x10 && vector != 0x13)
//			plug->Log(plug_persist, 9, L"INT 0x" + Piston::String::Renderhex(vector).PadLeft(2, L'0') + L", ax = " + Piston::String::Renderhex(*ax).PadLeft(4, L'0'));
//#endif
		XAOi__(push16)(cs->selector);
		XAOi__(push16)(PICK_OPSIZE(*ip, *eip));
		PICK_CPUBITS(*ip, *eip) = mem_read16_NSO(seg_zero, vector * 4);
		cs->selector = mem_read16_NSO(seg_zero, vector * 4 + 2);
	}

	inline void XAO_(exception)(int8 vector) throw() {
		XAO_(interrupt)(vector);
		longjmp(jmp_to_loop, 1);
	}

	inline void XAO_(raiseDE)() {
		plug->Log(plug_persist, LOG_ERROR, L"Divide over/underflow.  #DE");
		PICK_ADSIZE(*ip = this_ip, *eip = this_eip);
		XAO_(exception)(0);
	}

	inline void XAO_(raiseNM)() {
		//plug->Log(plug_persist, LOG_ERROR, L"No FPU.  #NM");
		PICK_ADSIZE(*ip = this_ip, *eip = this_eip);
		XAO_(exception)(7);
	}

	inline void XAO_(raiseUD)() {
#if CPU < X86_186
		plug->Log(plug_persist, LOG_FATAL, L"#UD.  Processor halted.");
		for(;;);
#else
		PICK_ADSIZE(*ip = this_ip, *eip = this_eip);
		XAO_(exception)(6);
#endif
	}
	inline void XAO_(raiseUD_Msg)() {
#if CPU < X86_186
		plug->Log(plug_persist, LOG_FATAL, L"Undefined opcode, processor halted.");
		ZSSERT(0);
		for(;;);
#else
		plug->Log(plug_persist, LOG_ERROR, L"Warning: undefined opcode.  #UD");
		ZSSERT(0);
		PICK_ADSIZE(*ip = this_ip, *eip = this_eip);
		XAO_(exception)(6);
#endif
	}

	//  v  |     |  cs:eip  | source
	// ----+-----+----------
	//   0 | #DE | offender | div/idiv
	//   1 | #DB |  either  | any instruction, while debugging is on
	//   2 | nmi |   next   | external
	//   3 | #BP |   next   | int3
	//   4 | #OF |   next   | into
	//   5 | #BR | offender | bound
	//   6 | #UD | offender | invalid opcode
	//   7 | #NM | offender | no coprocessor
	//   8 | #DF | undefind | double fault
	//   9 |     | offender | coprocessor segment overrun (386 and lower)
	//  10 | #TS |  ......  | invalid task switch segment
	//  11 | #NP | offender | segment not present
	//  12 | #SS | offender | stack fault
	//  13 | #GP | offender | general protection fault
	//  14 | #PF | offender | page fault
	//  15 |     |          | reserved
	//  16 | #MF | next fpu | coprocessor error
	//  17 | #AC | offender | alignment check (486+)
	//  18 | #MC |    N/A   | machine check (pentium+)

	void XAO_(needs186)() {
		plug->Log(plug_persist, LOG_ERROR, L"Software appears to require at least a 186.  #UD");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

	void XAO_(needs286)() {
		plug->Log(plug_persist, LOG_ERROR, L"Software appears to require at least a 286.  #UD");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

	void XAO_(needs386)() {
		plug->Log(plug_persist, LOG_ERROR, L"Software appears to require at least a 386.  #UD");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

	void XAO_(needs486)() {
		plug->Log(plug_persist, LOG_ERROR, L"Software appears to require at least a 486.  #UD");
		ZSSERT(0);
		XAO_(raiseUD)();
	}

	void XAO_(needsp1)() {
		plug->Log(plug_persist, LOG_ERROR, L"Software appears to require at least a Pentium I.  #UD");
		ZSSERT(0);
		XAO_(raiseUD)();
	}
}}