// included as part of CpuMain function
#include "real_a_o.hpp"
#ifdef X86_ONCE_PER_PROCESSOR

namespace Tower { namespace X86 {
	void X_(Loop)() {
		for(;;) {
			// switch(mode) {
				X_(real1616_Loop)();
			// }
			// when this returns, evaluate what's going on, and
			// here's where switch to protected set happens and "continue;"

			// lastly,
			if(TowerWantsQuit)
				break;
		}
	}

	void X_(Reset)() {
#if CPU < X86_386
		*di = *si = *bp = *sp = *bx = *dx = *cx = *ax = 0;
		*ip = 0xfff0;
		*flags = 0x0002;
#else
		*edi = *esi = *ebp = *esp = *ebx = *ecx = *eax = 0;
		*eip = 0xfff0;
		*eflags = 0x0002;

		gs->selector = fs->selector = 0;
		gs->base = fs->base = 0;
		gs->limit = fs->limit = 0xffff;
		gs->access = fs->access = 0x93;
#endif
		cs->selector = 0xf000;
		ds->selector = ss->selector = es->selector = 0;
#if CPU >= X86_286
		cs->base = 0xffff0000;
		ds->base = ss->base = es->base = 0;
		ds->limit = ss->limit = cs->limit = es->limit = 0xffff;
		cs->access = 0x93; // WRITABLE
		ds->access = ss->access = es->access = 0x93;
#endif

#if CPU == X86_8086
		*dx = 0x000f;
#elif CPU == X86_186
		*dx = 0x010f;
#elif CPU == X86_286
		*dx = 0x020f;
#elif CPU == X86_386 // 386DX = 030f, 386SX = 0320 or 0321
		*edx = 0x000e030f;
#elif CPU == X86_486 // 486DX = 0x042, 486DX-50 = 0411, 486DX4 = 0480
		*edx = 0x000e0402;
#else
	#error
#endif
	}
}}

#endif
#include "real_a_o_cleanup.hpp"