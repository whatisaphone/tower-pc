#include "stdafx.h"

#include "Piston\Gui\MessageBox.h"
#include "Piston\Io\File.h"

#include "Config.h"
#include "keyboard.h"
#include "pic.h"
#include "pit.h"

namespace Tower { namespace Chipset {
	const PlugInitData *plug;
	const DevInitData *plug_dev;
	const PicInitData *plug_pic;
	const void *plug_persist;
	const void *plug_status_num;
	const void *plug_status_caps;
	const void *plug_status_scrl;

	TOWER_EXPORT int32 tower_GetLibCaps() {
		return 0x01 << 8; // dll protocol ver 0x01
	}

	TOWER_EXPORT int32 tower_Init(const PlugInitData *init, const void *persist, unsigned long persist_len) {
		Piston::Gui::MessageBox::SetDefaultOwner((Piston::Win32::HWND)init->DlgOwner);
		Piston::Gui::MessageBox::SetDefaultCaption(L"Tower Chipset 0.01");

		plug = init;
		plug_persist = persist;
		Config::Parse(persist, persist_len);

		plug_status_num = plug->StatusItems.Register(plug_persist, 10000, 50, L"NUM");
		plug_status_caps = plug->StatusItems.Register(plug_persist, 10001, 50, L"CAPS");
		plug_status_scrl = plug->StatusItems.Register(plug_persist, 10002, 50, L"SCRL");

		return PLUGTYPE_GENERAL | PLUGTYPE_PIC;
	}

	TOWER_EXPORT int32 tower_dev_Init(const DevInitData *init) {
		plug_dev = init;

		// initialize kb
		PortHandlers h = {&KBC::Read8, &KBC::Read16, &KBC::Read32,
			&KBC::Write8, &KBC::Write16, &KBC::Write32};
		if(!init->PortClaim(plug_persist, 0x60, 0x6f, &h))
			return 0;
		PortHandlers pit = {&Pit::Read8, &Pit::Read16, &Pit::Read32, &Pit::Write8, &Pit::Write16, &Pit::Write32};
		if(!init->PortClaim(plug_persist, 0x40, 0x5f, &pit))
			return 0;

		// initialize roms
		MemHandlers m = {&RomRead8, &RomRead16, &RomRead32, &RomWrite8, &RomWrite16, &RomWrite32};
		RamBase = init->MemMapAdd(plug_persist, 0xc0000, 0xfffff, &m);
		if(!RamBase) return 0;
		RamBase -= 0xc0000;
		for(int i = 0xc0000; i < 0xfffff; i += 4)
			*(int32 *)(RamBase + i) = (int32)-1;

		try {
			Piston::Io::File rom;
			rom.Open(L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\debug\\rombios.bin", Piston::Io::File::Access::Read, Piston::Io::File::Sharing::ReadWrite);
			//ZSSERT(rom.GetSize() == 0x10000);
			rom.Read(RamBase + 0xf0000, rom.GetSize());
			rom.Close();

			//rom.Open(L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\debug\\vgabios.bin", Piston::Io::File::Access::Read, Piston::Io::File::Sharing::ReadWrite);
			rom.Open(L"C:\\Documents and Settings\\John Simon\\My Documents\\Visual Studio 2005\\Projects\\Tower\\debug\\vgabios-lgpl.bin", Piston::Io::File::Access::Read, Piston::Io::File::Sharing::ReadWrite);
			//ZSSERT(rom.GetSize() == 0x8000);
			rom.Read(RamBase + 0xc0000, rom.GetSize());
			rom.Close();
		} catch(...) {
			Piston::Gui::MessageBox::Show(L"Error reading ROMs into memory",
				Piston::Gui::MessageBox::Icons::Error);
			return 0;
		}

		ZSSERT(Pit::Init());

		return 1;
	}

	TOWER_EXPORT int32 tower_pic_Init(const PicInitData *init) {
		plug_pic = init;

		PortHandlers h = {&Pic::Read8, &Pic::Read16, &Pic::Read32, &Pic::Write8, &Pic::Write16, &Pic::Write32};
		if(!init->PortClaim(plug_persist, 0x20, 0x21, &h))
			return 0;
		if(!init->PortClaim(plug_persist, 0xa0, 0xa1, &h))
			return 0;

		return 1;
	}

	TOWER_EXPORT int32 tower_Run() {
		ZSSERT(Pit::Run());
		return 1;
	}

	TOWER_EXPORT void tower_Pause() {
		Pit::Pause();
	}

	TOWER_EXPORT void tower_Uninit() {
	}
}}