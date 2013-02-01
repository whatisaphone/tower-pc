#pragma once
#include "stdafx.h"

#include "Piston\Delegate.h"

namespace Tower { namespace X86 {
	void CpuInit();
	void CpuMain();
	void CpuPause();
	void CpuResume();
	void CpuReset();
	void CpuQuit();
}}