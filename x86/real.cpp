#include "stdafx.h"
#include "cpu.h"

#include "Piston\String.h" // for logging

#include "Config.h"

#define X86_RENDER_SLASH(num) L"/" + Piston::String::Render(((num) & 0x38) >> 3)
#define X86_RENDER_CSIP() L"[" + Piston::String::Renderhex(cs.selector).PadLeft(4, L'0') + \
	L":" + Piston::String::Renderhex(PICK_CPUBITS(*ip, *eip)).PadLeft(CPUBITS / 4, L'0')

#define i__jcc_rel8 XAOi__(jcc_rel8)
#define i__jcc_relOP CONCAT(XAOi__(jcc_rel), OPSIZE)
#define i__popOP CONCAT(XAOi__(pop), OPSIZE)
#define i__pushOP CONCAT(XAOi__(push), OPSIZE)

#define X86_INCLUDE_MASTER "real.hpp"
	#include "the_include_master.h"