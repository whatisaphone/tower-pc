#pragma once
#include "stdafx.h"

#include "Piston\String.h"
#include "Piston\Io\MemoryBuffer.h"

namespace Tower { namespace Chipset {
	class Config {
	private:
		Config();
		Config(const Config &copy);
		Config &operator=(const Config &copy);

		static Piston::Io::MemoryBuffer *buffer;

	public:
		static void Cleanup();
		static void Defaults();
		static void Parse(const void *persist, int32 persist_len);
		static void Render(void **persist, int32 *persist_len);
	};
}}