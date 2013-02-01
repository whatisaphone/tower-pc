#include "stdafx.h"

#include "Piston\Gui\MessageBox.h"
#include "Piston\Io\File.h"

#include "adapter.h"

namespace Tower { namespace Vga {
	const PlugInitData *plug;
	const VideoInitData *plug_vid;
	const void *plug_persist;

	TOWER_EXPORT int32 tower_GetLibCaps() {
		return 0x01 << 8; // dll protocol ver 0x01
	}

	TOWER_EXPORT int32 tower_Init(const PlugInitData *init, const void *persist, int32 persist_len) {
		Piston::Gui::MessageBox::SetDefaultOwner((Piston::Win32::HWND)init->DlgOwner);
		Piston::Gui::MessageBox::SetDefaultCaption(L"Tower Vga 0.01");

		plug = init;
		plug_persist = persist;
		//Config::Parse(plug, plug_persist);

		return PLUGTYPE_VIDEO;
	}

	TOWER_EXPORT int32 tower_vid_Init(const VideoInitData *init) {
		plug_vid = init;

		MemHandlers m = {&Adapter::MemRead8, &Adapter::MemRead16, &Adapter::MemRead32,
			&Adapter::MemWrite8, &Adapter::MemWrite16, &Adapter::MemWrite32};
		if(!init->MemMapAdd(plug_persist, 0xa0000, 0xbffff, &m))
			return 0;

		PortHandlers p = {&Adapter::PortRead8, &Adapter::PortRead16, &Adapter::PortRead32,
			&Adapter::PortWrite8, &Adapter::PortWrite16, &Adapter::PortWrite32};
		if(!init->PortClaim(plug_persist, 0x3b0, 0x3df, &p))
			return 0;

		Adapter::Init();
		return 1;
	}

	TOWER_EXPORT void tower_vid_Refresh(const void *hDC) {
#if 0 // ze major hack...
		int8 mode = plug_vid->MemRead8(0x449);

		if(mode == 0 || mode == 0xff) return; // for now, avoid race condition

		switch(mode) {
		case 0x00: case 0x01: case 0x02: case 0x03:
			TextModeDraw(mode, (Piston::Win32::HDC)hDC);
			break;
		case 0x06: case 0x10: case 0x12: case 0x13: case 0x5f:
			GfxModeDraw(mode, (Piston::Win32::HDC)hDC);
			break;
		default:
			ZSSERT(false);
			return;
		}
#else
		Adapter::RedrawAll((Piston::Win32::HDC)hDC);
#endif
	}

	TOWER_EXPORT void tower_Uninit() {
		Adapter::Uninit();
	}
}}