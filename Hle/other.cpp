#include "stdafx.h"
#include "calls.h"

#include "Piston\String.h"

namespace Tower { namespace Hle {
	void int_15() {
		switch(*ah) {
		default:
			plug->Log(plug_persist, LOG_ERROR, L"INT15: Undefined parameter in ah: 0x" +
				Piston::String::Renderhex(*ah).PadLeft(2, L'0') + L".");
			*flags |= flags_mask_cf;
			*ah = 0x86; // unsupported function
		}
	}

	void int_1a() {
		switch(*ah) {
		case 0x02:
		default:
			plug->Log(plug_persist, LOG_ERROR, L"INT1A: Undefined function in ah: 0x" +
				Piston::String::Renderhex(*ah).PadLeft(2, L'0') + L".");
			*flags |= flags_mask_cf;
		}
	}
}}