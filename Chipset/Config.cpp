#include "stdafx.h"
#include "Config.h"

#include "Piston\Io\BinaryReader.h"
#include "Piston\Io\BinaryWriter.h"

namespace Tower { namespace Chipset {
	Piston::Io::MemoryBuffer *Config::buffer;

	void Config::Cleanup() {
		if(buffer) {
			delete buffer;
			buffer = 0;
		}
	}

	void Config::Defaults() {
	}

	void Config::Parse(const void *persist, int32 persist_len) {
		if(!persist_len) {
			Defaults();
			return;
		}

		Piston::Io::MemoryBuffer stream(persist, persist_len);
		Piston::Io::BinaryReader read(&stream);
		try {
		} catch(...) {
			ZSSERT(0); // show message here?
			Defaults();
		}
	}

	void Config::Render(void **persist, int32 *persist_len) {
		ZSSERT(!buffer);
		buffer = new Piston::Io::MemoryBuffer();
		Piston::Io::BinaryWriter w(buffer);

		// ...

		*persist = buffer->Buffer();
		*persist_len = buffer->Length();
	}
}}