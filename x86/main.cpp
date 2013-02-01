#include "stdafx.h"

//#include "Piston\Delegate.h"
#include "Piston\Gui\MessageBox.h"

#include "Config.h"
#include "loop.h"

namespace Tower { namespace X86 {
	const PlugInitData *plug;
	const CpuInitData *plug_cpu;
	const void *plug_persist;

	TOWER_EXPORT unsigned int tower_GetLibCaps() {
		return 0x01 << 8; // dll protocol ver 0x01
	}

	TOWER_EXPORT int32 tower_Init(const PlugInitData *init, const void *persist, int32 persist_len) {
		Piston::Gui::MessageBox::SetDefaultOwner((Piston::Win32::HWND)init->DlgOwner);
		Piston::Gui::MessageBox::SetDefaultCaption(L"Tower x86 0.01");

		plug = init;
		plug_persist = persist;
		Config::Parse(persist, persist_len);

		return PLUGTYPE_CPU;
	}

	TOWER_EXPORT int32 tower_cpu_Init(const CpuInitData *init) {
		plug_cpu = init;

		CpuInit();
		return 1;
	}

	TOWER_EXPORT int32 tower_Run() {
		CpuResume();
		return 1;
	}

	TOWER_EXPORT void tower_Pause() {
		CpuPause();
	}

	TOWER_EXPORT void tower_Reset() {
		CpuReset();
	}

	TOWER_EXPORT void tower_Uninit() {
		CpuQuit();
	}
}}