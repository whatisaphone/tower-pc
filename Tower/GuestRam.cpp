#include "stdafx.h"
#include "Guest.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

#include "Logger.h"

namespace Tower {
	int8 *Guest::Ram::ram;
	Guest::Ram::Map Guest::Ram::maps[Guest::Ram::MapCount];

	bool Guest::Ram::Init(unsigned long bytes) {
		if(ram) throw 0; // TODO: replace with assert
		ram = new int8[bytes];
		if(!ram) {
			Piston::Gui::MessageBox::Show(Piston::String::Render(bytes >> 20) + L"MB of guest RAM could not be allocated.  Free some memory or lower the guest's memory size.", Piston::Gui::MessageBox::Icons::Error);
			return false;
		}

		if(profile->RamInit > 3)
			Logger::Log(L"RAM", LOG_ERROR, L"Unknown RAM initialization mode, defaulting to 0's.");
		switch(profile->RamInit) {
		case 1: for(unsigned long i = 0; i < bytes >> 2; ++i) // random
					((int32 *)ram)[i] = 0xaf82eb0d; // TODO: fix
				break;
		case 2: for(unsigned long i = 0; i < bytes >> 2; ++i) // close to reality
					((int32 *)ram)[i] = 0x01060402; // TODO: fix
				break;
		case 3: for(unsigned long i = 0; i < bytes >> 2; ++i) // #UDs
					((int32 *)ram)[i] = 0xffffffff;
				break;
		default:for(unsigned long i = 0; i < bytes >> 2; ++i) // zeros
					((int32 *)ram)[i] = 0;
				break;
		}

		for(int i = 0; i < MapCount; ++i)
			maps[i].Clear();

		maps[0].mem_hi = bytes - 1;
		maps[0].dev_hi = 0xffffffff;

		return true;
	}

	void Guest::Ram::Uninit() {
		if(ram) {
			delete [] ram;
			ram = 0;
		}
	}

#ifdef _DEBUG
	void Guest::Ram::Undefined(int what, int32 addr, int32 data) {
		/*Logger::Log(L"Ports", LOG_WARNING, Piston::StringBuilder::Build(L"Undefined ",
			Piston::String::Render(1 << (what % 3 + 3)), L"-bit ",
			(what < 3 ?
				L"read from" :
				L"write of 0x" + Piston::String::Renderhex(data).PadLeft(1 << ((what % 3) + 1), L'0') + L" to"
			), L" memory address 0x", Piston::String::Renderhex(addr).PadLeft(8, L'0')));*/
		//ZSSERT(0);
	}
#endif

	bool Guest::Ram::InsertAt(int index) {
		if(maps[MapCount - 1].dev_hi == 0xffffffff)
			return false;

		for(int i = MapCount - 1; i > index; --i)
			maps[i] = maps[i - 1];

		return true;
	}

	int8 *Guest::Ram::MapAdd(const void *persist, int32 dev_lo, int32 dev_hi, const MemHandlers *handlers) {
		GuestDev *dev = FindPersist(persist);
		if(!dev) {
			ZSSERT(0);
			return 0;
		}

		if(dev_lo > dev_hi) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
				dev->GetName(), L"' requested a memory map from 0x",
				Piston::String::Renderhex(dev_lo).PadLeft(dev_lo <= 0xffff ? 4 : 8, L'0'), L" to 0x",
				Piston::String::Renderhex(dev_hi).PadLeft(dev_lo <= 0xffff ? 4 : 8, L'0'), L".  Lower "
				L"bound is greater than upper bound."), Piston::Gui::MessageBox::Icons::Warning);
			return 0;
		}

		int i;
		for(i = 0; i < MapCount; ++i)
			if(dev_lo <= maps[i].mem_hi) {
				if(dev_hi <= maps[i].mem_hi) {
					if(!InsertAt(i)) goto MapSpaceMsg;
					maps[i].Set(persist, dev_lo - 1, dev_hi, handlers);
					return ram + dev_lo;
				} else // dev_hi > maps[i].mem_hi
					goto OverlapMsg;
			} else if(dev_lo <= maps[i].dev_hi)
				goto OverlapMsg;

		{
			Piston::StringBuilder err(L"An internal memory map error occured when '");
			err.Append(dev->GetName());
			err.Append(L"' requested a memory map from 0x");
			err.Append(Piston::String::Renderhex(dev_lo).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'));
			err.Append(L" to 0x");
			err.Append(Piston::String::Renderhex(dev_hi).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'));
			err.Append(L".\r\n\r\nMap dump:");
			for(int j = 0; j < MapCount; ++j) {
				err.Append(L"\r\n[");
				err.Append(Piston::String::Render(i).PadLeft(2, L'0'));
				err.Append(L"]: 0x");
				err.Append(Piston::String::Renderhex(maps[j].dev_hi).PadLeft(8, L'0'));
				err.Append(L"-0x");
				err.Append(Piston::String::Renderhex(maps[j].mem_hi).PadLeft(8, L'0'));
				err.Append(L", '");
				err.Append(FindPersist(maps[j].dev_persist)->GetName());
				err.Append(L"'");
				if(maps[j].dev_hi == 0xffffffff)
					break;
			}
			Piston::Gui::MessageBox::Show(err.Render(), Piston::Gui::MessageBox::Icons::Warning);
		}
		return 0;

MapSpaceMsg:
		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"Ran out of memory map space when '",
			dev->GetName(), L"' requested a memory map from 0x",
			Piston::String::Renderhex(dev_lo).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'), L" to 0x",
			Piston::String::Renderhex(dev_hi).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'), L"."),
			Piston::Gui::MessageBox::Icons::Warning);
		return 0;

OverlapMsg:
		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
			dev->GetName(), L"' requested a memory map from 0x",
			Piston::String::Renderhex(dev_lo).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'), L" to 0x",
			Piston::String::Renderhex(dev_hi).PadLeft(dev_hi <= 0xffff ? 4 : 8, L'0'),
			L".  This overlaps with memory range ",
			Piston::String::Renderhex(maps[i].mem_hi + 1).PadLeft(maps[i].dev_hi <= 0xffff ? 4 : 8, L'0'), L" to 0x",
			Piston::String::Renderhex(maps[i].dev_hi).PadLeft(maps[i].dev_hi <= 0xffff ? 4 : 8, L'0'),
			L" already mapped by '" + FindPersist(maps[i].dev_persist)->GetName(), L"'."),
			Piston::Gui::MessageBox::Icons::Warning);
		return 0;
	}

	void Guest::Ram::MapRemove(const void *persist, int32 dev_lo) {
		GuestDev *dev = FindPersist(persist);
		if(!dev) {
			ZSSERT(0);
			return;
		}

		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
			dev->GetName(), L"' called MemMapRemove, which is not yet implemented."),
			Piston::Gui::MessageBox::Icons::Warning);
	}

#ifdef _DEBUG
#define MAP_NOT_FOUND(blah) throw 0; // we shouldn't get past the loops
#else
#define MAP_NOT_FOUND(blah) blah
#endif

	int8 Guest::Ram::Read8(int32 addr) {
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi)
				return *(int8 *)(ram + addr);
			else if(addr <= maps[i].dev_hi)
				return maps[i].Read8(addr);

		MAP_NOT_FOUND(return 0xff;)
	}

	int16 Guest::Ram::Read16(int32 addr) {
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi)
				return *(int16 *)(ram + addr);
			else if(addr <= maps[i].dev_hi)
				return maps[i].Read16(addr);

		MAP_NOT_FOUND(return 0xffff;)
	}

	int32 Guest::Ram::Read32(int32 addr) {
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi)
				return *(int32 *)(ram + addr);
			else if(addr <= maps[i].dev_hi)
				return maps[i].Read32(addr);

		MAP_NOT_FOUND(return 0xffffffff;)
	}

	void Guest::Ram::Write8(int32 addr, int8 data) {
		ZSSERT((addr >= 0x400) || data); // i keep erasing the int tables in my Hle code lol
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi) {
				*(int8 *)(ram + addr) = data;
				return;
			} else if(addr <= maps[i].dev_hi) {
				maps[i].Write8(addr, data);
				return;
			}
		MAP_NOT_FOUND(return;)
	}

	void Guest::Ram::Write16(int32 addr, int16 data) {
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi) {
				*(int16 *)(ram + addr) = data;
				return;
			} else if(addr <= maps[i].dev_hi) {
				maps[i].Write16(addr, data);
				return;
			}
		MAP_NOT_FOUND(return;)
	}

	void Guest::Ram::Write32(int32 addr, int32 data) {
		ZSSERT((addr >= 0x400) || data); // i keep erasing the int tables in my Hle code lol
		for(int i = 0; i < MapCount; ++i)
			if(addr <= maps[i].mem_hi) {
				*(int32 *)(ram + addr) = data;
				return;
			} else if(addr <= maps[i].dev_hi) {
				maps[i].Write32(addr, data);
				return;
			}
		MAP_NOT_FOUND(return;)
	}
}