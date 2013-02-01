// when optimize: put slashes in array of length 256.
//                put rows in switch(00..C0) and handle regs afterwards

#define X86_MODRM_ERROR(desc) plug->Log(plug_persist, LOG_ERROR,	\
	X86_RENDER_CSIP() + desc L"(): Bad operand.  #UD.");			\
	ZSSERT(0);														\
	XAO_(raiseUD)()

namespace Tower { namespace X86 {
#if defined(X86_ONCE) && (A_O == 1616) // only once ever
	extern int8 modrm_byte;
 #if CPU >= X86_386
	static int32 modrm_sib;
 #endif
	static union {
		sint8 modrm_disp8;
		sint16 modrm_disp16;
 #if CPU >= X86_386
		sint32 modrm_disp32;
 #endif
	};
#endif

#if A_O == 1616 // once per processor, ADSIZE == 16
	void X_(modrm16_decode)() {
		modrm_byte = mem_read8_CSIP();
		if((modrm_byte & 0xc0) == 0x40)
			modrm_disp8 = (sint8)mem_read8_CSIP();
		else if((modrm_byte & 0xc0) == 0x80 || (modrm_byte & 0xc7) == 0x06)
			modrm_disp16 = (sint16)mem_read16_CSIP();
	}

	inline int8 X_(modrm16_read_r8)() {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: return *al;
		MRM_SLASH_1: return *cl;
		MRM_SLASH_2: return *dl;
		MRM_SLASH_3: return *bl;
		MRM_SLASH_4: return *ah;
		MRM_SLASH_5: return *ch;
		MRM_SLASH_6: return *dh;
		default    : return *bh;
		MRM_END_SWITCH_SLASH
	}

	int16 X_(modrm16_read_r16)() {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: return *ax;
		MRM_SLASH_1: return *cx;
		MRM_SLASH_2: return *dx;
		MRM_SLASH_3: return *bx;
		MRM_SLASH_4: return *sp;
		MRM_SLASH_5: return *bp;
		MRM_SLASH_6: return *si;
		default    : return *di;
		MRM_END_SWITCH_SLASH
	}

	inline void X_(modrm16_write_r8)(int8 value) {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: *al = value; return;
		MRM_SLASH_1: *cl = value; return;
		MRM_SLASH_2: *dl = value; return;
		MRM_SLASH_3: *bl = value; return;
		MRM_SLASH_4: *ah = value; return;
		MRM_SLASH_5: *ch = value; return;
		MRM_SLASH_6: *dh = value; return;
		default    : *bh = value; return;
		MRM_END_SWITCH_SLASH
	}

	void X_(modrm16_write_r16)(int16 value) {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: *ax = value; return;
		MRM_SLASH_1: *cx = value; return;
		MRM_SLASH_2: *dx = value; return;
		MRM_SLASH_3: *bx = value; return;
		MRM_SLASH_4: *sp = value; return;
		MRM_SLASH_5: *bp = value; return;
		MRM_SLASH_6: *si = value; return;
		default    : *di = value; return;
		MRM_END_SWITCH_SLASH
	}

#if CPU >= X86_386
	int32 X_(modrm16_read_r32)() {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: return *eax;
		MRM_SLASH_1: return *ecx;
		MRM_SLASH_2: return *edx;
		MRM_SLASH_3: return *ebx;
		MRM_SLASH_4: return *esp;
		MRM_SLASH_5: return *ebp;
		MRM_SLASH_6: return *esi;
		default    : return *edi;
		MRM_END_SWITCH_SLASH
	}

	void X_(modrm16_write_r32)(int32 value) {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: *eax = value; return;
		MRM_SLASH_1: *ecx = value; return;
		MRM_SLASH_2: *edx = value; return;
		MRM_SLASH_3: *ebx = value; return;
		MRM_SLASH_4: *esp = value; return;
		MRM_SLASH_5: *ebp = value; return;
		MRM_SLASH_6: *esi = value; return;
		default    : *edi = value; return;
		MRM_END_SWITCH_SLASH
	}
#endif

	int16 X_(modrm16_read_sreg)() {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: return es->selector;
		MRM_SLASH_1: return cs->selector;
		MRM_SLASH_2: return ss->selector;
		MRM_SLASH_3: return ds->selector;
#if CPU >= X86_386
		MRM_SLASH_4: return fs->selector;
		MRM_SLASH_5: return gs->selector;
#endif
		default    : X86_MODRM_ERROR(L"modrm_read_sreg");
		MRM_END_SWITCH_SLASH
	}

	void X_(modrm16_write_sreg)(int16 value) {
		MRM_SWITCH_SLASH(modrm_byte)
		MRM_SLASH_0: es->selector = value; return;
		MRM_SLASH_1: //cs.selector = value; return;
#if CPU < X86_186
			//ZSSERT(CPU != X86_186); // TODO: which does the 186 do here?
			cs->selector = value; return;
#else
			ZSSERT(0); XAO_(raiseUD)(); return;
#endif
		MRM_SLASH_2: ss->selector = value; return; // TODO: inhibit interrupts for one instruction
		MRM_SLASH_3: ds->selector = value; return;
#if CPU >=  X86_386
		MRM_SLASH_4: fs->selector = value; return;
		MRM_SLASH_5: gs->selector = value; return;
#endif
		default    : X86_MODRM_ERROR(L"modrm_write_sreg");
		MRM_END_SWITCH_SLASH
	}

	int16 X_(modrm16_locate_m)(int16 &seg) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: seg = RESOLVE_SEG(*ds); return *bx + *si;
		MRM_ROW_01: seg = RESOLVE_SEG(*ds); return *bx + *di;
		MRM_ROW_02: seg = RESOLVE_SEG(*ss); return *bp + *si;
		MRM_ROW_03: seg = RESOLVE_SEG(*ss); return *bp + *di;
		MRM_ROW_04: seg = RESOLVE_SEG(*ds); return *si;
		MRM_ROW_05: seg = RESOLVE_SEG(*ds); return *di;
		MRM_ROW_06: seg = RESOLVE_SEG(*ds); return modrm_disp16;
		MRM_ROW_07: seg = RESOLVE_SEG(*ds); return *bx;
		MRM_ROW_40: seg = RESOLVE_SEG(*ds); return *bx + *si + modrm_disp8;
		MRM_ROW_41: seg = RESOLVE_SEG(*ds); return *bx + *di + modrm_disp8;
		MRM_ROW_42: seg = RESOLVE_SEG(*ss); return *bp + *si + modrm_disp8;
		MRM_ROW_43: seg = RESOLVE_SEG(*ss); return *bp + *di + modrm_disp8;
		MRM_ROW_44: seg = RESOLVE_SEG(*ds); return *si + modrm_disp8;
		MRM_ROW_45: seg = RESOLVE_SEG(*ds); return *di + modrm_disp8;
		MRM_ROW_46: seg = RESOLVE_SEG(*ss); return *bp + modrm_disp8;
		MRM_ROW_47: seg = RESOLVE_SEG(*ds); return *bx + modrm_disp8;
		MRM_ROW_80: seg = RESOLVE_SEG(*ds); return *bx + *si + modrm_disp16;
		MRM_ROW_81: seg = RESOLVE_SEG(*ds); return *bx + *di + modrm_disp16;
		MRM_ROW_82: seg = RESOLVE_SEG(*ss); return *bp + *si + modrm_disp16;
		MRM_ROW_83: seg = RESOLVE_SEG(*ss); return *bp + *di + modrm_disp16;
		MRM_ROW_84: seg = RESOLVE_SEG(*ds); return *si + modrm_disp16;
		MRM_ROW_85: seg = RESOLVE_SEG(*ds); return *di + modrm_disp16;
		MRM_ROW_86: seg = RESOLVE_SEG(*ss); return *bp + modrm_disp16;
		MRM_ROW_87: seg = RESOLVE_SEG(*ds); return *bx + modrm_disp16;
		default   : X86_MODRM_ERROR(L"modrm16_locate_m");
		MRM_END_SWITCH_ROW
	}

	int16 X_(modrm16_read_m16)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read16(*ds, *bx + *si);
		MRM_ROW_01: return mem_read16(*ds, *bx + *di);
		MRM_ROW_02: return mem_read16(*ss, *bp + *si);
		MRM_ROW_03: return mem_read16(*ss, *bp + *di);
		MRM_ROW_04: return mem_read16(*ds, *si);
		MRM_ROW_05: return mem_read16(*ds, *di);
		MRM_ROW_06: return mem_read16(*ds, modrm_disp16);
		MRM_ROW_07: return mem_read16(*ds, *bx);
		MRM_ROW_40: return mem_read16(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: return mem_read16(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: return mem_read16(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: return mem_read16(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: return mem_read16(*ds, *si + modrm_disp8);
		MRM_ROW_45: return mem_read16(*ds, *di + modrm_disp8);
		MRM_ROW_46: return mem_read16(*ss, *bp + modrm_disp8);
		MRM_ROW_47: return mem_read16(*ds, *bx + modrm_disp8);
		MRM_ROW_80: return mem_read16(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: return mem_read16(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: return mem_read16(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: return mem_read16(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: return mem_read16(*ds, *si + modrm_disp16);
		MRM_ROW_85: return mem_read16(*ds, *di + modrm_disp16);
		MRM_ROW_86: return mem_read16(*ss, *bp + modrm_disp16);
		MRM_ROW_87: return mem_read16(*ds, *bx + modrm_disp16);
		default   : X86_MODRM_ERROR(L"modrm16_read_m16");
		MRM_END_SWITCH_ROW
	}

	int16 X_(modrm16_read_m1616)(int16 &word) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: word = mem_read16(*ds, *bx + *si + 2); return mem_read16(*ds, *bx + *si);
		MRM_ROW_01: word = mem_read16(*ds, *bx + *di + 2); return mem_read16(*ds, *bx + *di);
		MRM_ROW_02: word = mem_read16(*ss, *bp + *si + 2); return mem_read16(*ss, *bp + *si);
		MRM_ROW_03: word = mem_read16(*ss, *bp + *di + 2); return mem_read16(*ss, *bp + *di);
		MRM_ROW_04: word = mem_read16(*ds, *si + 2); return mem_read16(*ds, *si);
		MRM_ROW_05: word = mem_read16(*ds, *di + 2); return mem_read16(*ds, *di);
		MRM_ROW_06: word = mem_read16(*ds, modrm_disp16 + 2); return mem_read16(*ds, modrm_disp16);
		MRM_ROW_07: word = mem_read16(*ds, *bx + 2); return mem_read16(*ds, *bx);
		MRM_ROW_40: word = mem_read16(*ds, *bx + *si + modrm_disp8 + 2); return mem_read16(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: word = mem_read16(*ds, *bx + *di + modrm_disp8 + 2); return mem_read16(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: word = mem_read16(*ss, *bp + *si + modrm_disp8 + 2); return mem_read16(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: word = mem_read16(*ss, *bp + *di + modrm_disp8 + 2); return mem_read16(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: word = mem_read16(*ds, *si + modrm_disp8 + 2); return mem_read16(*ds, *si + modrm_disp8);
		MRM_ROW_45: word = mem_read16(*ds, *di + modrm_disp8 + 2); return mem_read16(*ds, *di + modrm_disp8);
		MRM_ROW_46: word = mem_read16(*ss, *bp + modrm_disp8 + 2); return mem_read16(*ss, *bp + modrm_disp8);
		MRM_ROW_47: word = mem_read16(*ds, *bx + modrm_disp8 + 2); return mem_read16(*ds, *bx + modrm_disp8);
		MRM_ROW_80: word = mem_read16(*ds, *bx + *si + modrm_disp16 + 2); return mem_read16(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: word = mem_read16(*ds, *bx + *di + modrm_disp16 + 2); return mem_read16(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: word = mem_read16(*ss, *bp + *si + modrm_disp16 + 2); return mem_read16(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: word = mem_read16(*ss, *bp + *di + modrm_disp16 + 2); return mem_read16(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: word = mem_read16(*ds, *si + modrm_disp16 + 2); return mem_read16(*ds, *si + modrm_disp16);
		MRM_ROW_85: word = mem_read16(*ds, *di + modrm_disp16 + 2); return mem_read16(*ds, *di + modrm_disp16);
		MRM_ROW_86: word = mem_read16(*ss, *bp + modrm_disp16 + 2); return mem_read16(*ss, *bp + modrm_disp16);
		MRM_ROW_87: word = mem_read16(*ds, *bx + modrm_disp16 + 2); return mem_read16(*ds, *bx + modrm_disp16);
		default   : X86_MODRM_ERROR(L"modrm16_read_m1616");
		MRM_END_SWITCH_ROW
	}

	void X_(modrm16_write_m16)(int16 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write16(*ds, *bx + *si, value); return;
		MRM_ROW_01: mem_write16(*ds, *bx + *di, value); return;
		MRM_ROW_02: mem_write16(*ss, *bp + *si, value); return;
		MRM_ROW_03: mem_write16(*ss, *bp + *di, value); return;
		MRM_ROW_04: mem_write16(*ds, *si, value); return;
		MRM_ROW_05: mem_write16(*ds, *di, value); return;
		MRM_ROW_06: mem_write16(*ds, modrm_disp16, value); return;
		MRM_ROW_07: mem_write16(*ds, *bx, value); return;
		MRM_ROW_40: mem_write16(*ds, *bx + *si + modrm_disp8, value); return;
		MRM_ROW_41: mem_write16(*ds, *bx + *di + modrm_disp8, value); return;
		MRM_ROW_42: mem_write16(*ss, *bp + *si + modrm_disp8, value); return;
		MRM_ROW_43: mem_write16(*ss, *bp + *di + modrm_disp8, value); return;
		MRM_ROW_44: mem_write16(*ds, *si + modrm_disp8, value); return;
		MRM_ROW_45: mem_write16(*ds, *di + modrm_disp8, value); return;
		MRM_ROW_46: mem_write16(*ss, *bp + modrm_disp8, value); return;
		MRM_ROW_47: mem_write16(*ds, *bx + modrm_disp8, value); return;
		MRM_ROW_80: mem_write16(*ds, *bx + *si + modrm_disp16, value); return;
		MRM_ROW_81: mem_write16(*ds, *bx + *di + modrm_disp16, value); return;
		MRM_ROW_82: mem_write16(*ss, *bp + *si + modrm_disp16, value); return;
		MRM_ROW_83: mem_write16(*ss, *bp + *di + modrm_disp16, value); return;
		MRM_ROW_84: mem_write16(*ds, *si + modrm_disp16, value); return;
		MRM_ROW_85: mem_write16(*ds, *di + modrm_disp16, value); return;
		MRM_ROW_86: mem_write16(*ss, *bp + modrm_disp16, value); return;
		MRM_ROW_87: mem_write16(*ds, *bx + modrm_disp16, value); return;
		default   : X86_MODRM_ERROR(L"modrm16_write_m16");
		MRM_END_SWITCH_ROW
	}

	int8 X_(modrm16_read_rm8)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read8(*ds, *bx + *si);
		MRM_ROW_01: return mem_read8(*ds, *bx + *di);
		MRM_ROW_02: return mem_read8(*ss, *bp + *si);
		MRM_ROW_03: return mem_read8(*ss, *bp + *di);
		MRM_ROW_04: return mem_read8(*ds, *si);
		MRM_ROW_05: return mem_read8(*ds, *di);
		MRM_ROW_06: return mem_read8(*ds, modrm_disp16);
		MRM_ROW_07: return mem_read8(*ds, *bx);
		MRM_ROW_40: return mem_read8(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: return mem_read8(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: return mem_read8(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: return mem_read8(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: return mem_read8(*ds, *si + modrm_disp8);
		MRM_ROW_45: return mem_read8(*ds, *di + modrm_disp8);
		MRM_ROW_46: return mem_read8(*ss, *bp + modrm_disp8);
		MRM_ROW_47: return mem_read8(*ds, *bx + modrm_disp8);
		MRM_ROW_80: return mem_read8(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: return mem_read8(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: return mem_read8(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: return mem_read8(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: return mem_read8(*ds, *si + modrm_disp16);
		MRM_ROW_85: return mem_read8(*ds, *di + modrm_disp16);
		MRM_ROW_86: return mem_read8(*ss, *bp + modrm_disp16);
		MRM_ROW_87: return mem_read8(*ds, *bx + modrm_disp16);
		MRM_ROW_C0: return *al;
		MRM_ROW_C1: return *cl;
		MRM_ROW_C2: return *dl;
		MRM_ROW_C3: return *bl;
		MRM_ROW_C4: return *ah;
		MRM_ROW_C5: return *ch;
		MRM_ROW_C6: return *dh;
		default   : return *bh;
		MRM_END_SWITCH_ROW
	}

	int16 X_(modrm16_read_rm16)() {
		// {try this}
		if(modrm_byte < 0xc0) {
			int16 seg;
			int16 off = X_(modrm16_locate_m)(seg);
			return mem_read16(*(SegReg *)&seg, off);
		} else
			// also see if this is ok:
			return *gen_regs_16[modrm_byte & 7];
		// {vs}
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read16(*ds, *bx + *si);
		MRM_ROW_01: return mem_read16(*ds, *bx + *di);
		MRM_ROW_02: return mem_read16(*ss, *bp + *si);
		MRM_ROW_03: return mem_read16(*ss, *bp + *di);
		MRM_ROW_04: return mem_read16(*ds, *si);
		MRM_ROW_05: return mem_read16(*ds, *di);
		MRM_ROW_06: return mem_read16(*ds, modrm_disp16);
		MRM_ROW_07: return mem_read16(*ds, *bx);
		MRM_ROW_40: return mem_read16(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: return mem_read16(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: return mem_read16(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: return mem_read16(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: return mem_read16(*ds, *si + modrm_disp8);
		MRM_ROW_45: return mem_read16(*ds, *di + modrm_disp8);
		MRM_ROW_46: return mem_read16(*ss, *bp + modrm_disp8);
		MRM_ROW_47: return mem_read16(*ds, *bx + modrm_disp8);
		MRM_ROW_80: return mem_read16(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: return mem_read16(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: return mem_read16(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: return mem_read16(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: return mem_read16(*ds, *si + modrm_disp16);
		MRM_ROW_85: return mem_read16(*ds, *di + modrm_disp16);
		MRM_ROW_86: return mem_read16(*ss, *bp + modrm_disp16);
		MRM_ROW_87: return mem_read16(*ds, *bx + modrm_disp16);
		MRM_ROW_C0: return *ax;
		MRM_ROW_C1: return *cx;
		MRM_ROW_C2: return *dx;
		MRM_ROW_C3: return *bx;
		MRM_ROW_C4: return *sp;
		MRM_ROW_C5: return *bp;
		MRM_ROW_C6: return *si;
		default   : return *di;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm16_write_rm8)(int8 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write8(*ds, *bx + *si, value); return;
		MRM_ROW_01: mem_write8(*ds, *bx + *di, value); return;
		MRM_ROW_02: mem_write8(*ss, *bp + *si, value); return;
		MRM_ROW_03: mem_write8(*ss, *bp + *di, value); return;
		MRM_ROW_04: mem_write8(*ds, *si, value); return;
		MRM_ROW_05: mem_write8(*ds, *di, value); return;
		MRM_ROW_06: mem_write8(*ds, modrm_disp16, value); return;
		MRM_ROW_07: mem_write8(*ds, *bx, value); return;
		MRM_ROW_40: mem_write8(*ds, *bx + *si + modrm_disp8, value); return;
		MRM_ROW_41: mem_write8(*ds, *bx + *di + modrm_disp8, value); return;
		MRM_ROW_42: mem_write8(*ss, *bp + *si + modrm_disp8, value); return;
		MRM_ROW_43: mem_write8(*ss, *bp + *di + modrm_disp8, value); return;
		MRM_ROW_44: mem_write8(*ds, *si + modrm_disp8, value); return;
		MRM_ROW_45: mem_write8(*ds, *di + modrm_disp8, value); return;
		MRM_ROW_46: mem_write8(*ss, *bp + modrm_disp8, value); return;
		MRM_ROW_47: mem_write8(*ds, *bx + modrm_disp8, value); return;
		MRM_ROW_80: mem_write8(*ds, *bx + *si + modrm_disp16, value); return;
		MRM_ROW_81: mem_write8(*ds, *bx + *di + modrm_disp16, value); return;
		MRM_ROW_82: mem_write8(*ss, *bp + *si + modrm_disp16, value); return;
		MRM_ROW_83: mem_write8(*ss, *bp + *di + modrm_disp16, value); return;
		MRM_ROW_84: mem_write8(*ds, *si + modrm_disp16, value); return;
		MRM_ROW_85: mem_write8(*ds, *di + modrm_disp16, value); return;
		MRM_ROW_86: mem_write8(*ss, *bp + modrm_disp16, value); return;
		MRM_ROW_87: mem_write8(*ds, *bx + modrm_disp16, value); return;
		MRM_ROW_C0: *al = value; return;
		MRM_ROW_C1: *cl = value; return;
		MRM_ROW_C2: *dl = value; return;
		MRM_ROW_C3: *bl = value; return;
		MRM_ROW_C4: *ah = value; return;
		MRM_ROW_C5: *ch = value; return;
		MRM_ROW_C6: *dh = value; return;
		default   : *bh = value; return;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm16_write_rm16)(int16 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write16(*ds, *bx + *si, value); return;
		MRM_ROW_01: mem_write16(*ds, *bx + *di, value); return;
		MRM_ROW_02: mem_write16(*ss, *bp + *si, value); return;
		MRM_ROW_03: mem_write16(*ss, *bp + *di, value); return;
		MRM_ROW_04: mem_write16(*ds, *si, value); return;
		MRM_ROW_05: mem_write16(*ds, *di, value); return;
		MRM_ROW_06: mem_write16(*ds, modrm_disp16, value); return;
		MRM_ROW_07: mem_write16(*ds, *bx, value); return;
		MRM_ROW_40: mem_write16(*ds, *bx + *si + modrm_disp8, value); return;
		MRM_ROW_41: mem_write16(*ds, *bx + *di + modrm_disp8, value); return;
		MRM_ROW_42: mem_write16(*ss, *bp + *si + modrm_disp8, value); return;
		MRM_ROW_43: mem_write16(*ss, *bp + *di + modrm_disp8, value); return;
		MRM_ROW_44: mem_write16(*ds, *si + modrm_disp8, value); return;
		MRM_ROW_45: mem_write16(*ds, *di + modrm_disp8, value); return;
		MRM_ROW_46: mem_write16(*ss, *bp + modrm_disp8, value); return;
		MRM_ROW_47: mem_write16(*ds, *bx + modrm_disp8, value); return;
		MRM_ROW_80: mem_write16(*ds, *bx + *si + modrm_disp16, value); return;
		MRM_ROW_81: mem_write16(*ds, *bx + *di + modrm_disp16, value); return;
		MRM_ROW_82: mem_write16(*ss, *bp + *si + modrm_disp16, value); return;
		MRM_ROW_83: mem_write16(*ss, *bp + *di + modrm_disp16, value); return;
		MRM_ROW_84: mem_write16(*ds, *si + modrm_disp16, value); return;
		MRM_ROW_85: mem_write16(*ds, *di + modrm_disp16, value); return;
		MRM_ROW_86: mem_write16(*ss, *bp + modrm_disp16, value); return;
		MRM_ROW_87: mem_write16(*ds, *bx + modrm_disp16, value); return;
		MRM_ROW_C0: *ax = value; return;
		MRM_ROW_C1: *cx = value; return;
		MRM_ROW_C2: *dx = value; return;
		MRM_ROW_C3: *bx = value; return;
		MRM_ROW_C4: *sp = value; return;
		MRM_ROW_C5: *bp = value; return;
		MRM_ROW_C6: *si = value; return;
		default   : *di = value; return;
		MRM_END_SWITCH_ROW
	}

#if CPU >= X86_386
	int32 X_(modrm16_read_m32)() {
		ZSSERT(0);
	}

	int32 X_(modrm16_read_m3216)(int16 &word) {
		ZSSERT(0);
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: word = mem_read16(*ds, *bx + *si + 4); return mem_read32(*ds, *bx + *si);
		MRM_ROW_01: word = mem_read16(*ds, *bx + *di + 4); return mem_read32(*ds, *bx + *di);
		MRM_ROW_02: word = mem_read16(*ss, *bp + *si + 4); return mem_read32(*ss, *bp + *si);
		MRM_ROW_03: word = mem_read16(*ss, *bp + *di + 4); return mem_read32(*ss, *bp + *di);
		MRM_ROW_04: word = mem_read16(*ds, *si + 4); return mem_read32(*ds, *si);
		MRM_ROW_05: word = mem_read16(*ds, *di + 4); return mem_read32(*ds, *di);
		MRM_ROW_06: word = mem_read16(*ds, modrm_disp16 + 4); return mem_read32(*ds, modrm_disp16);
		MRM_ROW_07: word = mem_read16(*ds, *bx + 4); return mem_read32(*ds, *bx);
		MRM_ROW_40: word = mem_read16(*ds, *bx + *si + modrm_disp8 + 4); return mem_read32(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: word = mem_read16(*ds, *bx + *di + modrm_disp8 + 4); return mem_read32(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: word = mem_read16(*ss, *bp + *si + modrm_disp8 + 4); return mem_read32(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: word = mem_read16(*ss, *bp + *di + modrm_disp8 + 4); return mem_read32(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: word = mem_read16(*ds, *si + modrm_disp8 + 4); return mem_read32(*ds, *si + modrm_disp8);
		MRM_ROW_45: word = mem_read16(*ds, *di + modrm_disp8 + 4); return mem_read32(*ds, *di + modrm_disp8);
		MRM_ROW_46: word = mem_read16(*ss, *bp + modrm_disp8 + 4); return mem_read32(*ss, *bp + modrm_disp8);
		MRM_ROW_47: word = mem_read16(*ds, *bx + modrm_disp8 + 4); return mem_read32(*ds, *bx + modrm_disp8);
		MRM_ROW_80: word = mem_read16(*ds, *bx + *si + modrm_disp16 + 4); return mem_read32(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: word = mem_read16(*ds, *bx + *di + modrm_disp16 + 4); return mem_read32(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: word = mem_read16(*ss, *bp + *si + modrm_disp16 + 4); return mem_read32(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: word = mem_read16(*ss, *bp + *di + modrm_disp16 + 4); return mem_read32(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: word = mem_read16(*ds, *si + modrm_disp16 + 4); return mem_read32(*ds, *si + modrm_disp16);
		MRM_ROW_85: word = mem_read16(*ds, *di + modrm_disp16 + 4); return mem_read32(*ds, *di + modrm_disp16);
		MRM_ROW_86: word = mem_read16(*ss, *bp + modrm_disp16 + 4); return mem_read32(*ss, *bp + modrm_disp16);
		MRM_ROW_87: word = mem_read16(*ds, *bx + modrm_disp16 + 4); return mem_read32(*ds, *bx + modrm_disp16);
		default   : X86_MODRM_ERROR(L"modrm16_read_m1616");
		MRM_END_SWITCH_ROW
	}

	void X_(modrm16_write_m32)(int32 value) {
		ZSSERT(0);
	}

	int32 X_(modrm16_read_rm32)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read32(*ds, *bx + *si);
		MRM_ROW_01: return mem_read32(*ds, *bx + *di);
		MRM_ROW_02: return mem_read32(*ss, *bp + *si);
		MRM_ROW_03: return mem_read32(*ss, *bp + *di);
		MRM_ROW_04: return mem_read32(*ds, *si);
		MRM_ROW_05: return mem_read32(*ds, *di);
		MRM_ROW_06: return mem_read32(*ds, modrm_disp16);
		MRM_ROW_07: return mem_read32(*ds, *bx);
		MRM_ROW_40: return mem_read32(*ds, *bx + *si + modrm_disp8);
		MRM_ROW_41: return mem_read32(*ds, *bx + *di + modrm_disp8);
		MRM_ROW_42: return mem_read32(*ss, *bp + *si + modrm_disp8);
		MRM_ROW_43: return mem_read32(*ss, *bp + *di + modrm_disp8);
		MRM_ROW_44: return mem_read32(*ds, *si + modrm_disp8);
		MRM_ROW_45: return mem_read32(*ds, *di + modrm_disp8);
		MRM_ROW_46: return mem_read32(*ss, *bp + modrm_disp8);
		MRM_ROW_47: return mem_read32(*ds, *bx + modrm_disp8);
		MRM_ROW_80: return mem_read32(*ds, *bx + *si + modrm_disp16);
		MRM_ROW_81: return mem_read32(*ds, *bx + *di + modrm_disp16);
		MRM_ROW_82: return mem_read32(*ss, *bp + *si + modrm_disp16);
		MRM_ROW_83: return mem_read32(*ss, *bp + *di + modrm_disp16);
		MRM_ROW_84: return mem_read32(*ds, *si + modrm_disp16);
		MRM_ROW_85: return mem_read32(*ds, *di + modrm_disp16);
		MRM_ROW_86: return mem_read32(*ss, *bp + modrm_disp16);
		MRM_ROW_87: return mem_read32(*ds, *bx + modrm_disp16);
		MRM_ROW_C0: return *eax;
		MRM_ROW_C1: return *ecx;
		MRM_ROW_C2: return *edx;
		MRM_ROW_C3: return *ebx;
		MRM_ROW_C4: return *esp;
		MRM_ROW_C5: return *ebp;
		MRM_ROW_C6: return *esi;
		default   : return *edi;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm16_write_rm32)(int32 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write32(*ds, *bx + *si, value); return;
		MRM_ROW_01: mem_write32(*ds, *bx + *di, value); return;
		MRM_ROW_02: mem_write32(*ss, *bp + *si, value); return;
		MRM_ROW_03: mem_write32(*ss, *bp + *di, value); return;
		MRM_ROW_04: mem_write32(*ds, *si, value); return;
		MRM_ROW_05: mem_write32(*ds, *di, value); return;
		MRM_ROW_06: mem_write32(*ds, modrm_disp16, value); return;
		MRM_ROW_07: mem_write32(*ds, *bx, value); return;
		MRM_ROW_40: mem_write32(*ds, *bx + *si + modrm_disp8, value); return;
		MRM_ROW_41: mem_write32(*ds, *bx + *di + modrm_disp8, value); return;
		MRM_ROW_42: mem_write32(*ss, *bp + *si + modrm_disp8, value); return;
		MRM_ROW_43: mem_write32(*ss, *bp + *di + modrm_disp8, value); return;
		MRM_ROW_44: mem_write32(*ds, *si + modrm_disp8, value); return;
		MRM_ROW_45: mem_write32(*ds, *di + modrm_disp8, value); return;
		MRM_ROW_46: mem_write32(*ss, *bp + modrm_disp8, value); return;
		MRM_ROW_47: mem_write32(*ds, *bx + modrm_disp8, value); return;
		MRM_ROW_80: mem_write32(*ds, *bx + *si + modrm_disp16, value); return;
		MRM_ROW_81: mem_write32(*ds, *bx + *di + modrm_disp16, value); return;
		MRM_ROW_82: mem_write32(*ss, *bp + *si + modrm_disp16, value); return;
		MRM_ROW_83: mem_write32(*ss, *bp + *di + modrm_disp16, value); return;
		MRM_ROW_84: mem_write32(*ds, *si + modrm_disp16, value); return;
		MRM_ROW_85: mem_write32(*ds, *di + modrm_disp16, value); return;
		MRM_ROW_86: mem_write32(*ss, *bp + modrm_disp16, value); return;
		MRM_ROW_87: mem_write32(*ds, *bx + modrm_disp16, value); return;
		MRM_ROW_C0: *eax = value; return;
		MRM_ROW_C1: *ecx = value; return;
		MRM_ROW_C2: *edx = value; return;
		MRM_ROW_C3: *ebx = value; return;
		MRM_ROW_C4: *esp = value; return;
		MRM_ROW_C5: *ebp = value; return;
		MRM_ROW_C6: *esi = value; return;
		default   : *edi = value; return;
		MRM_END_SWITCH_ROW
	}
#endif
#endif

	/********************************   32-BIT   **********************************/
#if A_O == 3216 // once per processor, ADSIZE == 32
	void X_(modrm32_decode_sib)() {
		int8 sib_byte = mem_read8_CSIP();

		MRM_SWITCH_SLASH(sib_byte)
		MRM_SLASH_0: modrm_sib = *eax; break;
		MRM_SLASH_1: modrm_sib = *ecx; break;
		MRM_SLASH_2: modrm_sib = *edx; break;
		MRM_SLASH_3: modrm_sib = *ebx; break;
		MRM_SLASH_4: modrm_sib = *esp; break;
		MRM_SLASH_5: __asm {int 3}; /* sandpile.org/ia32/opc_sib.htm   --  read only one signed byte when modrm_sib == 0x80 ????? */ modrm_sib = (modrm_byte & 0xc0) ? *ebp : mem_read32_CSIP(); break;
		MRM_SLASH_6: modrm_sib = *esi; break;
		MRM_SLASH_7: modrm_sib = *edi; break;
		MRM_END_SWITCH_SLASH

		MRM_SWITCH_ROW(sib_byte)
		MRM_ROW_00: modrm_sib += *eax * 1;
		MRM_ROW_01: modrm_sib += *ecx * 1;
		MRM_ROW_02: modrm_sib += *edx * 1;
		MRM_ROW_03: modrm_sib += *ebx * 1;
		MRM_ROW_04: modrm_sib +=   0  * 1;
		MRM_ROW_05: modrm_sib += *ebp * 1;
		MRM_ROW_06: modrm_sib += *esi * 1;
		MRM_ROW_07: modrm_sib += *edi * 1;
		MRM_ROW_40: modrm_sib += *eax * 2;
		MRM_ROW_41: modrm_sib += *ecx * 2;
		MRM_ROW_42: modrm_sib += *edx * 2;
		MRM_ROW_43: modrm_sib += *ebx * 2;
		MRM_ROW_44: modrm_sib +=   0  * 2;
		MRM_ROW_45: modrm_sib += *ebp * 2;
		MRM_ROW_46: modrm_sib += *esi * 2;
		MRM_ROW_47: modrm_sib += *edi * 2;
		MRM_ROW_80: modrm_sib += *eax * 4;
		MRM_ROW_81: modrm_sib += *ecx * 4;
		MRM_ROW_82: modrm_sib += *edx * 4;
		MRM_ROW_83: modrm_sib += *ebx * 4;
		MRM_ROW_84: modrm_sib +=   0  * 4;
		MRM_ROW_85: modrm_sib += *ebp * 4;
		MRM_ROW_86: modrm_sib += *esi * 4;
		MRM_ROW_87: modrm_sib += *edi * 4;
		MRM_ROW_C0: modrm_sib += *eax * 8;
		MRM_ROW_C1: modrm_sib += *ecx * 8;
		MRM_ROW_C2: modrm_sib += *edx * 8;
		MRM_ROW_C3: modrm_sib += *ebx * 8;
		MRM_ROW_C4: modrm_sib +=   0  * 8;
		MRM_ROW_C5: modrm_sib += *ebp * 8;
		MRM_ROW_C6: modrm_sib += *esi * 8;
		default   : modrm_sib += *edi * 8;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm32_decode)() {
		modrm_byte = mem_read8_CSIP();
		if((modrm_byte & 0xc0) == 0x40)
			modrm_disp8 = (sint8)mem_read8_CSIP();
		__asm {int 3} // verify that next change below
		else if((modrm_byte & 0x40) == 0x00) // on 0x00, or 0x80
			modrm_disp32 = (sint32)mem_read32_CSIP();

		if((modrm_byte & 0xc0 != 0xc0) && (modrm_byte & 0x7 == 4))
			X_(modrm32_decode_sib)();
	}

	inline int8 X_(modrm32_read_r8)() {return X_(modrm16_read_r8)();}
	inline int16 X_(modrm32_read_r16)() {return X_(modrm16_read_r16)();}
	inline int32 X_(modrm32_read_r32)() {return X_(modrm16_read_r32)();}
	inline void X_(modrm32_write_r8)(int8 value) {X_(modrm16_write_r8)(value);}
	inline void X_(modrm32_write_r16)(int16 value) {X_(modrm16_write_r16)(value);}
	inline void X_(modrm32_write_r32)(int32 value) {X_(modrm16_write_r32)(value);}
	inline int16 X_(modrm32_read_sreg)() {return X_(modrm16_read_sreg)();}
	inline void X_(modrm32_write_sreg)(int16 value) {X_(modrm16_write_sreg)(value);}

	int32 X_(modrm32_locate_m)(int16 &return_seg) {
		throw 0;
	}

	int16 X_(modrm32_read_m16)() {
		throw 0;
	}

	int32 X_(modrm32_read_m32)() {
		throw 0;
	}

	int16 X_(modrm32_read_m1616)(int16 &word) {
		throw 0;
	}

	int32 X_(modrm32_read_m3216)(int16 &word) {
		throw 0;
	}

	void X_(modrm32_write_m16)(int16 value) {
		throw 0;
	}

	void X_(modrm32_write_m32)(int32 value) {
		throw 0;
	}

	int8 X_(modrm32_read_rm8)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read8(*ds, *eax);
		MRM_ROW_01: return mem_read8(*ds, *ecx);
		MRM_ROW_02: return mem_read8(*ds, *edx);
		MRM_ROW_03: return mem_read8(*ds, *ebx);
		MRM_ROW_04: return mem_read8(*ds, modrm_sib);
		MRM_ROW_05: return mem_read8(*ds, modrm_disp32);
		MRM_ROW_06: return mem_read8(*ds, *esi);
		MRM_ROW_07: return mem_read8(*ds, *edi);
		MRM_ROW_40: return mem_read8(*ds, *eax + modrm_disp8);
		MRM_ROW_41: return mem_read8(*ds, *ecx + modrm_disp8);
		MRM_ROW_42: return mem_read8(*ds, *edx + modrm_disp8);
		MRM_ROW_43: return mem_read8(*ds, *ebx + modrm_disp8);
		MRM_ROW_44: return mem_read8(*ds, modrm_sib + modrm_disp8);
		MRM_ROW_45: return mem_read8(*ds, *ebp +  + modrm_disp8);
		MRM_ROW_46: return mem_read8(*ds, *esi + modrm_disp8);
		MRM_ROW_47: return mem_read8(*ds, *edi + modrm_disp8);
		MRM_ROW_80: return mem_read8(*ds, *eax + modrm_disp32);
		MRM_ROW_81: return mem_read8(*ds, *ecx + modrm_disp32);
		MRM_ROW_82: return mem_read8(*ds, *edx + modrm_disp32);
		MRM_ROW_83: return mem_read8(*ds, *ebx + modrm_disp32);
		MRM_ROW_84: return mem_read8(*ds, modrm_sib + modrm_disp32);
		MRM_ROW_85: return mem_read8(*ds, *ebp +  + modrm_disp32);
		MRM_ROW_86: return mem_read8(*ds, *esi + modrm_disp32);
		MRM_ROW_87: return mem_read8(*ds, *edi + modrm_disp32);
		MRM_ROW_C0: return *al;
		MRM_ROW_C1: return *cl;
		MRM_ROW_C2: return *dl;
		MRM_ROW_C3: return *bl;
		MRM_ROW_C4: return *ah;
		MRM_ROW_C5: return *ch;
		MRM_ROW_C6: return *dh;
		default   : return *bh;
		MRM_END_SWITCH_ROW
	}

	int16 X_(modrm32_read_rm16)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read16(*ds, *eax);
		MRM_ROW_01: return mem_read16(*ds, *ecx);
		MRM_ROW_02: return mem_read16(*ds, *edx);
		MRM_ROW_03: return mem_read16(*ds, *ebx);
		MRM_ROW_04: return mem_read16(*ds, modrm_sib);
		MRM_ROW_05: return mem_read16(*ds, modrm_disp32);
		MRM_ROW_06: return mem_read16(*ds, *esi);
		MRM_ROW_07: return mem_read16(*ds, *edi);
		MRM_ROW_40: return mem_read16(*ds, *eax + modrm_disp8);
		MRM_ROW_41: return mem_read16(*ds, *ecx + modrm_disp8);
		MRM_ROW_42: return mem_read16(*ds, *edx + modrm_disp8);
		MRM_ROW_43: return mem_read16(*ds, *ebx + modrm_disp8);
		MRM_ROW_44: return mem_read16(*ds, modrm_sib + modrm_disp8);
		MRM_ROW_45: return mem_read16(*ds, *ebp +  + modrm_disp8);
		MRM_ROW_46: return mem_read16(*ds, *esi + modrm_disp8);
		MRM_ROW_47: return mem_read16(*ds, *edi + modrm_disp8);
		MRM_ROW_80: return mem_read16(*ds, *eax + modrm_disp32);
		MRM_ROW_81: return mem_read16(*ds, *ecx + modrm_disp32);
		MRM_ROW_82: return mem_read16(*ds, *edx + modrm_disp32);
		MRM_ROW_83: return mem_read16(*ds, *ebx + modrm_disp32);
		MRM_ROW_84: return mem_read16(*ds, modrm_sib + modrm_disp32);
		MRM_ROW_85: return mem_read16(*ds, *ebp +  + modrm_disp32);
		MRM_ROW_86: return mem_read16(*ds, *esi + modrm_disp32);
		MRM_ROW_87: return mem_read16(*ds, *edi + modrm_disp32);
		MRM_ROW_C0: return *ax;
		MRM_ROW_C1: return *cx;
		MRM_ROW_C2: return *dx;
		MRM_ROW_C3: return *bx;
		MRM_ROW_C4: return *sp;
		MRM_ROW_C5: return *bp;
		MRM_ROW_C6: return *si;
		default   : return *di;
		MRM_END_SWITCH_ROW
	}

	int32 X_(modrm32_read_rm32)() {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: return mem_read32(*ds, *eax);
		MRM_ROW_01: return mem_read32(*ds, *ecx);
		MRM_ROW_02: return mem_read32(*ds, *edx);
		MRM_ROW_03: return mem_read32(*ds, *ebx);
		MRM_ROW_04: return mem_read32(*ds, modrm_sib);
		MRM_ROW_05: return mem_read32(*ds, modrm_disp32);
		MRM_ROW_06: return mem_read32(*ds, *esi);
		MRM_ROW_07: return mem_read32(*ds, *edi);
		MRM_ROW_40: return mem_read32(*ds, *eax + modrm_disp8);
		MRM_ROW_41: return mem_read32(*ds, *ecx + modrm_disp8);
		MRM_ROW_42: return mem_read32(*ds, *edx + modrm_disp8);
		MRM_ROW_43: return mem_read32(*ds, *ebx + modrm_disp8);
		MRM_ROW_44: return mem_read32(*ds, modrm_sib + modrm_disp8);
		MRM_ROW_45: return mem_read32(*ds, *ebp +  + modrm_disp8);
		MRM_ROW_46: return mem_read32(*ds, *esi + modrm_disp8);
		MRM_ROW_47: return mem_read32(*ds, *edi + modrm_disp8);
		MRM_ROW_80: return mem_read32(*ds, *eax + modrm_disp32);
		MRM_ROW_81: return mem_read32(*ds, *ecx + modrm_disp32);
		MRM_ROW_82: return mem_read32(*ds, *edx + modrm_disp32);
		MRM_ROW_83: return mem_read32(*ds, *ebx + modrm_disp32);
		MRM_ROW_84: return mem_read32(*ds, modrm_sib + modrm_disp32);
		MRM_ROW_85: return mem_read32(*ds, *ebp +  + modrm_disp32);
		MRM_ROW_86: return mem_read32(*ds, *esi + modrm_disp32);
		MRM_ROW_87: return mem_read32(*ds, *edi + modrm_disp32);
		MRM_ROW_C0: return *eax;
		MRM_ROW_C1: return *ecx;
		MRM_ROW_C2: return *edx;
		MRM_ROW_C3: return *ebx;
		MRM_ROW_C4: return *esp;
		MRM_ROW_C5: return *ebp;
		MRM_ROW_C6: return *esi;
		default   : return *edi;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm32_write_rm8)(int8 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write8(*ds, *eax, value); return;
		MRM_ROW_01: mem_write8(*ds, *ecx, value); return;
		MRM_ROW_02: mem_write8(*ds, *edx, value); return;
		MRM_ROW_03: mem_write8(*ds, *ebx, value); return;
		MRM_ROW_04: mem_write8(*ds, modrm_sib, value); return;
		MRM_ROW_05: mem_write8(*ds, modrm_disp32, value); return;
		MRM_ROW_06: mem_write8(*ds, *esi, value); return;
		MRM_ROW_07: mem_write8(*ds, *edi, value); return;
		MRM_ROW_40: mem_write8(*ds, *eax + modrm_disp8, value); return;
		MRM_ROW_41: mem_write8(*ds, *ecx + modrm_disp8, value); return;
		MRM_ROW_42: mem_write8(*ds, *edx + modrm_disp8, value); return;
		MRM_ROW_43: mem_write8(*ds, *ebx + modrm_disp8, value); return;
		MRM_ROW_44: mem_write8(*ds, modrm_sib + modrm_disp8, value); return;
		MRM_ROW_45: mem_write8(*ds, *ebp +  + modrm_disp8, value); return;
		MRM_ROW_46: mem_write8(*ds, *esi + modrm_disp8, value); return;
		MRM_ROW_47: mem_write8(*ds, *edi + modrm_disp8, value); return;
		MRM_ROW_80: mem_write8(*ds, *eax + modrm_disp32, value); return;
		MRM_ROW_81: mem_write8(*ds, *ecx + modrm_disp32, value); return;
		MRM_ROW_82: mem_write8(*ds, *edx + modrm_disp32, value); return;
		MRM_ROW_83: mem_write8(*ds, *ebx + modrm_disp32, value); return;
		MRM_ROW_84: mem_write8(*ds, modrm_sib + modrm_disp32, value); return;
		MRM_ROW_85: mem_write8(*ds, *ebp +  + modrm_disp32, value); return;
		MRM_ROW_86: mem_write8(*ds, *esi + modrm_disp32, value); return;
		MRM_ROW_87: mem_write8(*ds, *edi + modrm_disp32, value); return;
		MRM_ROW_C0: *al = value; return;
		MRM_ROW_C1: *cl = value; return;
		MRM_ROW_C2: *dl = value; return;
		MRM_ROW_C3: *bl = value; return;
		MRM_ROW_C4: *ah = value; return;
		MRM_ROW_C5: *ch = value; return;
		MRM_ROW_C6: *dh = value; return;
		default   : *bh = value; return;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm32_write_rm16)(int16 value) {
		ZSSERT(0);
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write16(*ds, *eax, value); return;
		MRM_ROW_01: mem_write16(*ds, *ecx, value); return;
		MRM_ROW_02: mem_write16(*ds, *edx, value); return;
		MRM_ROW_03: mem_write16(*ds, *ebx, value); return;
		MRM_ROW_04: mem_write16(*ds, modrm_sib, value); return;
		MRM_ROW_05: mem_write16(*ds, modrm_disp32, value); return;
		MRM_ROW_06: mem_write16(*ds, *esi, value); return;
		MRM_ROW_07: mem_write16(*ds, *edi, value); return;
		MRM_ROW_40: mem_write16(*ds, *eax + modrm_disp8, value); return;
		MRM_ROW_41: mem_write16(*ds, *ecx + modrm_disp8, value); return;
		MRM_ROW_42: mem_write16(*ds, *edx + modrm_disp8, value); return;
		MRM_ROW_43: mem_write16(*ds, *ebx + modrm_disp8, value); return;
		MRM_ROW_44: mem_write16(*ds, modrm_sib + modrm_disp8, value); return;
		MRM_ROW_45: mem_write16(*ds, *ebp +  + modrm_disp8, value); return;
		MRM_ROW_46: mem_write16(*ds, *esi + modrm_disp8, value); return;
		MRM_ROW_47: mem_write16(*ds, *edi + modrm_disp8, value); return;
		MRM_ROW_80: mem_write16(*ds, *eax + modrm_disp32, value); return;
		MRM_ROW_81: mem_write16(*ds, *ecx + modrm_disp32, value); return;
		MRM_ROW_82: mem_write16(*ds, *edx + modrm_disp32, value); return;
		MRM_ROW_83: mem_write16(*ds, *ebx + modrm_disp32, value); return;
		MRM_ROW_84: mem_write16(*ds, modrm_sib + modrm_disp32, value); return;
		MRM_ROW_85: mem_write16(*ds, *ebp +  + modrm_disp32, value); return;
		MRM_ROW_86: mem_write16(*ds, *esi + modrm_disp32, value); return;
		MRM_ROW_87: mem_write16(*ds, *edi + modrm_disp32, value); return;
		MRM_ROW_C0: *ax = value; return;
		MRM_ROW_C1: *cx = value; return;
		MRM_ROW_C2: *dx = value; return;
		MRM_ROW_C3: *bx = value; return;
		MRM_ROW_C4: *sp = value; return;
		MRM_ROW_C5: *bp = value; return;
		MRM_ROW_C6: *si = value; return;
		default   : *di = value; return;
		MRM_END_SWITCH_ROW
	}

	void X_(modrm32_write_rm32)(int32 value) {
		MRM_SWITCH_ROW(modrm_byte)
		MRM_ROW_00: mem_write32(*ds, *eax, value); return;
		MRM_ROW_01: mem_write32(*ds, *ecx, value); return;
		MRM_ROW_02: mem_write32(*ds, *edx, value); return;
		MRM_ROW_03: mem_write32(*ds, *ebx, value); return;
		MRM_ROW_04: mem_write32(*ds, modrm_sib, value); return;
		MRM_ROW_05: mem_write32(*ds, modrm_disp32, value); return;
		MRM_ROW_06: mem_write32(*ds, *esi, value); return;
		MRM_ROW_07: mem_write32(*ds, *edi, value); return;
		MRM_ROW_40: mem_write32(*ds, *eax + modrm_disp8, value); return;
		MRM_ROW_41: mem_write32(*ds, *ecx + modrm_disp8, value); return;
		MRM_ROW_42: mem_write32(*ds, *edx + modrm_disp8, value); return;
		MRM_ROW_43: mem_write32(*ds, *ebx + modrm_disp8, value); return;
		MRM_ROW_44: mem_write32(*ds, modrm_sib + modrm_disp8, value); return;
		MRM_ROW_45: mem_write32(*ds, *ebp +  + modrm_disp8, value); return;
		MRM_ROW_46: mem_write32(*ds, *esi + modrm_disp8, value); return;
		MRM_ROW_47: mem_write32(*ds, *edi + modrm_disp8, value); return;
		MRM_ROW_80: mem_write32(*ds, *eax + modrm_disp32, value); return;
		MRM_ROW_81: mem_write32(*ds, *ecx + modrm_disp32, value); return;
		MRM_ROW_82: mem_write32(*ds, *edx + modrm_disp32, value); return;
		MRM_ROW_83: mem_write32(*ds, *ebx + modrm_disp32, value); return;
		MRM_ROW_84: mem_write32(*ds, modrm_sib + modrm_disp32, value); return;
		MRM_ROW_85: mem_write32(*ds, *ebp +  + modrm_disp32, value); return;
		MRM_ROW_86: mem_write32(*ds, *esi + modrm_disp32, value); return;
		MRM_ROW_87: mem_write32(*ds, *edi + modrm_disp32, value); return;
		MRM_ROW_C0: *eax = value; return;
		MRM_ROW_C1: *ecx = value; return;
		MRM_ROW_C2: *edx = value; return;
		MRM_ROW_C3: *ebx = value; return;
		MRM_ROW_C4: *esp = value; return;
		MRM_ROW_C5: *ebp = value; return;
		MRM_ROW_C6: *esi = value; return;
		default   : *edi = value; return;
		MRM_END_SWITCH_ROW
	}
#endif
}}

#undef X86_MODRM_ERROR

#ifdef X86_ONCE
	#define modrm_decode CONCAT(X_(modrm), ADSIZE)##_decode
	#define modrm_read_r8 CONCAT(X_(modrm), ADSIZE)##_read_r8
	#define modrm_read_r16 CONCAT(X_(modrm), ADSIZE)##_read_r16
	#define modrm_read_r32 CONCAT(X_(modrm), ADSIZE)##_read_r32
	#define modrm_write_r8 CONCAT(X_(modrm), ADSIZE)##_write_r8
	#define modrm_write_r16 CONCAT(X_(modrm), ADSIZE)##_write_r16
	#define modrm_write_r32 CONCAT(X_(modrm), ADSIZE)##_write_r32
	#define modrm_read_sreg CONCAT(X_(modrm), ADSIZE)##_read_sreg
	#define modrm_write_sreg CONCAT(X_(modrm), ADSIZE)##_write_sreg
	#define modrm_locate_m CONCAT(X_(modrm), ADSIZE)##_locate_m
	#define modrm_read_m16 CONCAT(X_(modrm), ADSIZE)##_read_m16
	#define modrm_read_m32 CONCAT(X_(modrm), ADSIZE)##_read_m32
	#define modrm_read_m1616 CONCAT(X_(modrm), ADSIZE)##_read_m1616
	#define modrm_read_m3216 CONCAT(X_(modrm), ADSIZE)##_read_m3216
	#define modrm_write_m16 CONCAT(X_(modrm), ADSIZE)##_write_m16
	#define modrm_write_m32 CONCAT(X_(modrm), ADSIZE)##_write_m32
	#define modrm_read_rm8 CONCAT(X_(modrm), ADSIZE)##_read_rm8
	#define modrm_read_rm16 CONCAT(X_(modrm), ADSIZE)##_read_rm16
	#define modrm_read_rm32 CONCAT(X_(modrm), ADSIZE)##_read_rm32
	#define modrm_write_rm8 CONCAT(X_(modrm), ADSIZE)##_write_rm8
	#define modrm_write_rm16 CONCAT(X_(modrm), ADSIZE)##_write_rm16
	#define modrm_write_rm32 CONCAT(X_(modrm), ADSIZE)##_write_rm32

	#define modrm_read_rOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_read_r, OPSIZE)
	#define modrm_read_mOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_read_m, OPSIZE)
	#define modrm_read_mOP16 CONCAT(X_(modrm), ADSIZE)##CONCAT(_read_m, OPSIZE)##16
	#define modrm_read_rmOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_read_rm, OPSIZE)
	#define modrm_write_rOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_write_r, OPSIZE)
	#define modrm_write_mOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_write_m, OPSIZE)
	#define modrm_write_rmOP CONCAT(X_(modrm), ADSIZE)##CONCAT(_write_rm, OPSIZE)
#endif