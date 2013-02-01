#include "stdafx.h"
#include "Config.h"

#include "Piston\Io\BinaryReader.h"
#include "Piston\Io\BinaryWriter.h"

namespace Tower { namespace Hle {
	Config::drivestruct Config::Drives[3];
	Piston::Io::MemoryBuffer *Config::buffer;

	void Config::Cleanup() {
		if(buffer) {
			delete buffer;
			buffer = 0;
		}
	}

	void Config::Defaults() {
		Drives[0].Enabled = 1;
		Drives[0].File = L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\testsuite\\"
			//L"games\\scorch.bs.360x480.img";
			L"os-dos\\Miraculix 1.00.806.img";
			//L"os-gui\\win203.img";
			//L"os-inst\\msdos622a.img";
		Drives[0].Mounted = 1;
		Drives[0].Readonly = 1;

		Drives[1].Enabled = 1;
		Drives[1].File = L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\testsuite\\"
			L"hd.img";
			//L"bochs.hdd";
		Drives[1].Mounted = 1;
		Drives[1].Readonly = 0;

		Drives[2].Enabled = 0;
		Drives[2].File = 0;
		Drives[2].Mounted = 1;
		Drives[2].Readonly = 1;
	}

	void Config::Parse(const void *persist, int32 persist_len) {
		if(!persist_len) {
			Defaults();
			return;
		}

		Piston::Io::MemoryBuffer stream(persist, persist_len);
		Piston::Io::BinaryReader read(&stream);
		try {
			for(int i = 0; i < 3; ++i) {
				Drives[i].Enabled = read.ReadByte();
				Drives[i].File = read.ReadString();
				Drives[i].Mounted = read.ReadByte();
				Drives[i].Readonly = read.ReadByte();
			}
		} catch(...) {
			ZSSERT(0); // how to show message here?
			Defaults();
		}
	}

	void Config::Render(void **persist, int32 *persist_len) {
		ZSSERT(!buffer);
		buffer = new Piston::Io::MemoryBuffer();
		Piston::Io::BinaryWriter w(buffer);
		for(int i = 0; i < 3; ++i) {
			w.WriteByte(Drives[i].Enabled);
			w.WriteString(Drives[i].File);
			w.WriteByte(Drives[i].Mounted);
			w.WriteByte(Drives[i].Readonly);
		}

		*persist = buffer->Buffer();
		*persist_len = buffer->Length();
	}
}}