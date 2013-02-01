#if !defined(X86_FLAGS_INCLUDED) // only do this once per mode per processor (for now)
	#define X86_FLAGS_INCLUDED
	#define intCPU int32
	//                                                    .=====================.=========.
	//                                                    |         486+        |   386+  |
	//                                                    *=====================*=========*
	//   32   31   30   29 | 11   10   9    8  || 7    6    21   20  | 19    18   17   16
	//  ----v----v----v----+----v----v----v----++----v----v----v-----+-----v----v----v----
	//      |    |    |    |    |    |    |    ||    |    | ID | VIP | VIF | AC | VM | RF
	//
	//
	// .==================.
	// |       286+       |
	// *==================*
	//   15   14   13  12 | 11   10   9    8  || 7    6    5   4  | 3   2    1   0
	// v----v----v--------+----v----v----v----++----v----v---v----+---v----v---v----
	// | 0  | NT |  IOPL  | OF | DF | IF | TF || SF | ZF | 0 | AF | 0 | PF | 1 | CF
	//
	//  0 - CF - set if carry of borrow from BSB.  (unsigned overflow)
	//  2 - PF - set if LSB contains an even number of 1's.
	//  4 - AF - set if carry or borrow from bit 3.  (BCD overflow)
	//  6 - ZF - set if zero.
	//  7 - SF - set equal to MSB.
	// 11 - OF - set if result is too many bits to fit.  (signed overflow)

	static const int8 parity_lookup[256] = {
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0, // 4 == flags_mask_pf.  slick, huh
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4,
		0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0};

#define DEFINE_FLAG(x, SHIFT)																\
	static const intCPU flags_mask_##x = 1 << SHIFT;										\
	inline int8 flags_get_##x() {return (*eflags & flags_mask_##x) ? (int8)1 : (int8)0;}	\
	inline void flags_clear_##x() {*eflags &= ~flags_mask_##x;}								\
	inline void flags_set_##x() {*eflags |= flags_mask_##x;}								\
	inline void flags_set_##x(int8 value) {if(value) *eflags |= flags_mask_##x; else *eflags &= ~flags_mask_##x;}

#define DEFINE_FLAG_WIDE(NAME, SHIFT, BITS)														\
	static const intCPU flags_mask_##NAME = (0xffffffff >> (32 - BITS)) << SHIFT;				\
	inline int8 flags_get_##NAME() {return (*eflags & flags_mask_##NAME) >> BITS;}				\
	/*inline void flags_clear_##NAME() {*eflags &= ~flags_mask_##NAME;}*/						\
	inline void flags_set_##NAME(int8 value) {													\
		ZSSERT(((value << BITS) & ~flags_mask_##NAME) == 0); /* no set extraneous bits */		\
		*eflags = *eflags & ~flags_mask_##NAME | value << BITS;									\
	}

#define USE_FLAGZ (*eflags) //PICK_CPUBITS((*flags), (*eflags))

	DEFINE_FLAG(cf, 0)
	DEFINE_FLAG(pf, 2)
	DEFINE_FLAG(af, 4)
	DEFINE_FLAG(zf, 6)
	DEFINE_FLAG(sf, 7)
	DEFINE_FLAG(tf, 8)
	DEFINE_FLAG(if, 9)
	DEFINE_FLAG(df, 10)
	DEFINE_FLAG(of, 11)
//#if CPU >= X86_286
		DEFINE_FLAG_WIDE(iopl, 12, 2)
		DEFINE_FLAG(nt, 14)
  //#if CPU >= X86_386
		DEFINE_FLAG(rf, 16)
		DEFINE_FLAG(vm, 17)
	//#if CPU >= X86_486
		DEFINE_FLAG(ac, 18)
		DEFINE_FLAG(vif, 19)
		DEFINE_FLAG(vip, 20)
		DEFINE_FLAG(id, 21)
	//#endif
  //#endif
//#endif

	static const intCPU flags_mask_cfof = flags_mask_cf | flags_mask_of;
	static const intCPU flags_mask_cao = flags_mask_cf | flags_mask_af | flags_mask_of;
	static const intCPU flags_mask_cpazso = flags_mask_cf | flags_mask_pf | flags_mask_af | flags_mask_zf | flags_mask_sf | flags_mask_of;
	static const intCPU flags_mask_pazso = flags_mask_pf | flags_mask_af | flags_mask_zf | flags_mask_sf | flags_mask_of;
	static const intCPU flags_mask_pzs = flags_mask_pf | flags_mask_zf | flags_mask_sf;

//#if CPU < X86_286
	//static const int16 flags_reserved_at_0 = 0xf008;
//#elif CPU == X86_286
	//static const int16 flags_reserved_at_0 = 0x8008;
//#elif CPU == X86_386
	//static const int32 flags_reserved_at_0 = 0xfffc8008;
//#elif CPU == X86_486
	static const int32 flags_reserved_at_0 = 0xffc08008;
//#else
	//#error flags_reserved_at_0
//#endif
	static const intCPU flags_reserved_at_1 = 2;

	inline void flags_clrOC_testSZP_8(int8 value) {
		USE_FLAGZ = USE_FLAGZ & ~flags_mask_cpazso |
			parity_lookup[value] | // pf
			(value           ? 0 : flags_mask_zf) |
			(value & 0x80);        // sf
	}

	inline void flags_clrOC_testSZP_16(int16 value) {
		USE_FLAGZ = USE_FLAGZ & ~flags_mask_cpazso |
			parity_lookup[(int8)value] | // pf
			(value                 ? 0 : flags_mask_zf) |
			(value & 0x8000            ? flags_mask_sf : 0);
	}


	inline void flags_clrOC_testSZP_32(int32 value) {
		USE_FLAGZ = USE_FLAGZ & ~flags_mask_cpazso |
			parity_lookup[(int8)value] | // pf
			(value                 ? 0 : flags_mask_zf) |
			(value & 0x80000000        ? flags_mask_sf : 0);
	}
	#undef USE_FLAGZ
	#undef intCPU
#endif