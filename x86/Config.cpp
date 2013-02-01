#include "stdafx.h"
#include "Config.h"

namespace Tower { namespace X86 {
	Piston::Io::MemoryBuffer *Config::bfr;
	int32 Config::CpuLevel;

	void Config::Cleanup() {
		if(bfr) {
			delete bfr;
			bfr = 0;
		}
	}

	void Config::Parse(const void *persist, int32 persist_len) {
		CpuLevel = X86_486;
	}

	void Config::Render(void **persist, int32 *persist_len) {
		ZSSERT(!bfr);
	}
}}