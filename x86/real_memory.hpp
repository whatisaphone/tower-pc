/*#undef mem_read8
#undef mem_read16
#undef mem_read32
#undef mem_write8
#undef mem_write16
#undef mem_write32
#undef mem_read8_NSO
#undef mem_read16_NSO
#undef mem_read32_NSO
#undef mem_write8_NSO
#undef mem_write16_NSO
#undef mem_write32_NSO
#undef mem_read8_CSIP
#undef mem_read16_CSIP
#undef mem_read32_CSIP*/

#if OPSIZE == 16 // only do this once for each address size

#if CPU < X86_286
	#define WRAP_ADDR & (int32)0xfffff
#elif CPU == X86_286
	#define WRAP_ADDR & (int32)0xffffff
#elif CPU <= X86_486
	#define WRAP_ADDR /*& (int32)0xffffffff*/
#else
	#error
#endif

#define RESOLVE_SEG(seg) (seg_override ? seg_override->selector : (seg).selector)
#define RESOLVE_SEG_OFF(seg, off) (((RESOLVE_SEG(seg) << 4) + (off)) WRAP_ADDR)
#define SEG_OFF(seg, off) ((((seg).selector << 4) + (off)) WRAP_ADDR)

//#define MZSRT() ZSSERT(off <= 0xffff) // check for overflow of 16-bit
#define MZSRT()

namespace Tower { namespace X86 {
	// TODO: strictness: 8086 bridges 0xffff gap to 0x0000, 386 throws #12 for SS or #13 for other segs, 186-286 do what?
	inline int8 XA_(mem_read8)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead8(RESOLVE_SEG_OFF(seg, off));}
	inline int16 XA_(mem_read16)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead16(RESOLVE_SEG_OFF(seg, off));}
	inline void XA_(mem_write8)(const SegReg &seg, intAD off, int8 data) {MZSRT(); plug_cpu->MemWrite8(RESOLVE_SEG_OFF(seg, off), data);}
	inline void XA_(mem_write16)(const SegReg &seg, intAD off, int16 data) {MZSRT(); plug_cpu->MemWrite16(RESOLVE_SEG_OFF(seg, off), data);}

	inline int8 XA_(mem_read8_NSO)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead8(SEG_OFF(seg, off));}
	inline int16 XA_(mem_read16_NSO)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead16(SEG_OFF(seg, off));}
	inline void XA_(mem_write8_NSO)(const SegReg &seg, intAD off, int8 data) {MZSRT(); plug_cpu->MemWrite8(SEG_OFF(seg, off), data);}
	inline void XA_(mem_write16_NSO)(const SegReg &seg, intAD off, int16 data) {MZSRT(); plug_cpu->MemWrite16(SEG_OFF(seg, off), data);}

	inline int8 XA_(mem_read8_CSIP)() {int8 ret = XA_(mem_read8_NSO)(*cs, PICK_ADSIZE(*ip, *eip)); ++PICK_ADSIZE(*ip, *eip); return ret;}
	inline int16 XA_(mem_read16_CSIP)() {int16 ret = XA_(mem_read16_NSO)(*cs, PICK_ADSIZE(*ip, *eip)); PICK_ADSIZE(*ip, *eip) += 2; return ret;}

#if CPU >= X86_386
	inline int32 XA_(mem_read32)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead32(RESOLVE_SEG_OFF(seg, off));}
	inline void XA_(mem_write32)(const SegReg &seg, intAD off, int32 data) {MZSRT(); plug_cpu->MemWrite32(RESOLVE_SEG_OFF(seg, off), data);}
	inline int32 XA_(mem_read32_NSO)(const SegReg &seg, intAD off) {MZSRT(); return plug_cpu->MemRead32(SEG_OFF(seg, off));}
	inline void XA_(mem_write32_NSO)(const SegReg &seg, intAD off, int32 data) {MZSRT(); plug_cpu->MemWrite32(SEG_OFF(seg, off), data);}
	inline int32 XA_(mem_read32_CSIP)() {int32 ret = XA_(mem_read32_NSO)(*cs, PICK_ADSIZE(*ip, *eip)); PICK_ADSIZE(*ip, *eip) += 4; return ret;}
#endif

#undef MZSRT
#undef WRAP_ADDR
#undef RESOLVE_SEG_OFF
#undef SEG_OFF
}}

#endif

/*#define mem_read8 XA_(mem_read8)
#define mem_read16 XA_(mem_read16)
#define mem_write8 XA_(mem_write8)
#define mem_write16 XA_(mem_write16)
#define mem_read8_NSO XA_(mem_read8_NSO)
#define mem_read16_NSO XA_(mem_read16_NSO)
#define mem_write8_NSO XA_(mem_write8_NSO)
#define mem_write16_NSO XA_(mem_write16_NSO)
#define mem_read8_CSIP XA_(mem_read8_CSIP)
#define mem_read16_CSIP XA_(mem_read16_CSIP)

#if CPU >= X86_386
#define mem_read32 XA_(mem_read32)
#define mem_write32 XA_(mem_write32)
#define mem_read32_NSO XA_(mem_read32_NSO)
#define mem_write32_NSO XA_(mem_write32_NSO)
#define mem_read32_CSIP XA_(mem_read32_CSIP)
#endif*/

#ifdef X86_ONCE
	#define mem_read8 XA_(mem_read8)
	#define mem_read16 XA_(mem_read16)
	#define mem_read32 XA_(mem_read32)
	#define mem_write8 XA_(mem_write8)
	#define mem_write16 XA_(mem_write16)
	#define mem_write32 XA_(mem_write32)
	#define mem_read8_NSO XA_(mem_read8_NSO)
	#define mem_read16_NSO XA_(mem_read16_NSO)
	#define mem_read32_NSO XA_(mem_read32_NSO)
	#define mem_write8_NSO XA_(mem_write8_NSO)
	#define mem_write16_NSO XA_(mem_write16_NSO)
	#define mem_write32_NSO XA_(mem_write32_NSO)
	#define mem_read8_CSIP XA_(mem_read8_CSIP)
	#define mem_read16_CSIP XA_(mem_read16_CSIP)
	#define mem_read32_CSIP XA_(mem_read32_CSIP)

	#define mem_readOP CONCAT(XA_(mem_read), OPSIZE)
	#define mem_writeOP CONCAT(XA_(mem_write), OPSIZE)
	#define mem_readOP_NSO CONCAT(XA_(mem_read), OPSIZE)##_NSO
	#define mem_writeOP_NSO CONCAT(XA_(mem_write), OPSIZE)##_NSO
	#define mem_readAD_CSIP CONCAT(XA_(mem_read), ADSIZE)##_CSIP
	#define mem_readOP_CSIP CONCAT(XA_(mem_read), OPSIZE)##_CSIP
#endif