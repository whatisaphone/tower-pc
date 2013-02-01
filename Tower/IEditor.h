#error not impl
#pragma once
#include "stdafx.h"

namespace Tower {
	class __declspec(novtable) IEditor PISTON_ABSTRACT {
	public:
		virtual void OptionsShow(const void *container);
		virtual void OptionsHide(void **persist, int32 *persist_len);
	};
}