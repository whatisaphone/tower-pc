#pragma once
#include "stdafx.h"

#include "Piston\String.h"
#include "Piston\Io\MemoryBuffer.h"

namespace Tower { namespace Hle {
	class Config {
	private:
		Config();
		Config(const Config &copy);
		Config &operator=(const Config &copy);

		static Piston::Io::MemoryBuffer *buffer;

	public:
		static struct drivestruct {
			Piston::String File;
			unsigned char Enabled : 1, Mounted : 1, Readonly : 1;
		} Drives[3];

		static void Cleanup();
		static void Defaults();
		static void Parse(const void *persist, int32 persist_len);
		static void Render(void **persist, int32 *persist_len);
	};
}}