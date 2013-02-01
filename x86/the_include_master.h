#define X86_ONCE

#ifdef X86_SUPPORT_PENTIUM
	#define CPU X86_486
	#define A_O 1616
		#include X86_INCLUDE_MASTER
	#define A_O 3216
		#include X86_INCLUDE_MASTER
	#define A_O 1632
		#include X86_INCLUDE_MASTER
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 3232
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif
#ifdef X86_SUPPORT_486
	#define CPU X86_486
	#define A_O 1616
		#include X86_INCLUDE_MASTER
	#define A_O 3216
		#include X86_INCLUDE_MASTER
	#define A_O 1632
		#include X86_INCLUDE_MASTER
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 3232
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif
#ifdef X86_SUPPORT_386
	#define CPU X86_386
	#define A_O 1616
		#include X86_INCLUDE_MASTER
	#define A_O 3216
		#include X86_INCLUDE_MASTER
	#define A_O 1632
		#include X86_INCLUDE_MASTER
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 3232
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif
#ifdef X86_SUPPORT_286
	#define CPU X86_286
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 1616
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif
#ifdef X86_SUPPORT_186
	#define CPU X86_186
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 1616
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif
#ifdef X86_SUPPORT_8086
	#define CPU X86_8086
  #define X86_ONCE_PER_PROCESSOR
	#define A_O 1616
		#include X86_INCLUDE_MASTER
  #undef X86_ONCE_PER_PROCESSOR
	#undef CPU
	#undef X86_ONCE
#endif

#ifdef X86_ONCE
	#error Must compile at least once processor.  Define X86_SUPPORT_X86_386 or similar
#endif

#undef X86_INCLUDE_MASTER