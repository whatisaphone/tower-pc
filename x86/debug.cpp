#include "stdafx.h"

#ifdef _DEBUG
#include "cpu.h"

#include "Piston\String.h"
#include "Piston\Io\File.h"

void DumpSeg(Tower::int16 seg) {
	Piston::Io::File f;
	try {
		f.CreateOrTruncate(L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\debug\\" + Piston::String::Renderhex(seg).PadLeft(4, L'0') + L".bin");
		for(int i = 0; i < 0xffff; i += 4) {
			Tower::int32 dw = Tower::X86::plug_cpu->MemRead32((seg << 4) + i);
			f.Write(&dw, 4);
		}
		Tower::X86::plug->Log(Tower::X86::plug_persist, Tower::LOG_INFO, L"[DEBUG] DumpSeg(" +
			Piston::String::Renderhex(seg).PadLeft(4, L'0') + L"): Success");
	} catch(...) {
		Tower::X86::plug->Log(Tower::X86::plug_persist, Tower::LOG_ERROR, L"[DEBUG] DumpSeg(" +
			Piston::String::Renderhex(seg).PadLeft(4, L'0') + L"): Failure");
	}
	f.Close();
}
#endif