#pragma once
#include "stdafx.h"

#include "Piston\Io\MemoryBuffer.h"

namespace Tower { namespace X86 {
	class Config {
	private:
		Config();
		Config(const Config &copy);
		Config &operator=(const Config &copy);

		static Piston::Io::MemoryBuffer *bfr;

	public:
		static int32 CpuLevel;

		static void Cleanup();
		static void Parse(const void *persist, int32 persist_len);
		static void Render(void **persist, int32 *persist_len);
	};
}}