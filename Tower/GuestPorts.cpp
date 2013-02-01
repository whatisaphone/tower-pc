#include "stdafx.h"
#include "Guest.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

#include "Logger.h"

namespace Tower {
	Guest::Ports::Map Guest::Ports::maps[0x10000];

	bool Guest::Ports::Init() {
		for(unsigned int i = 0; i < 0x10000; ++i)
			maps[i].Clear();

		return true;
	}

#ifdef _DEBUG
	void Guest::Ports::Undefined(int what, int16 port, int32 value) {
		if(port != 0x0064) // keyboard
		if(port != 0x0201) // joystick
		if(port != 0x0cf8)
		if(port != 0x0cfc)
			Logger::Log(L"Ports", LOG_WARNING, Piston::StringBuilder::Build(L"Undefined ",
				Piston::String::Render(1 << (what % 3 + 3)), L"-bit ",
				(what < 3 ?
					L"read from" :
					L"write of 0x" + Piston::String::Renderhex(value).PadLeft(1 << ((what % 3) + 1), L'0') + L" to"
				), L" port 0x", Piston::String::Renderhex(port).PadLeft(4, L'0')));
	}
#endif

	int32 Guest::Ports::Claim(const void *persist, int16 low, int16 high, const PortHandlers *handlers) {
		GuestDev *dev = FindPersist(persist);
		if(!dev) {
			ZSSERT(0);
			return 0;
		}

		if(low > high) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
				dev->GetName(), L"' attempted to claim the port range 0x",
				Piston::String::Renderhex(low).PadLeft(low <= 0xff ? 2 : 4, L'0'), L" to 0x",
				Piston::String::Renderhex(high).PadLeft(low <= 0xff ? 2 : 4, L'0'), L".  Lower "
				L"bound is greater than upper bound."), Piston::Gui::MessageBox::Icons::Warning);
			return 0;
		}

		bool failure = false;
		for(int i = low; i <= high; ++i) {
			if(maps[i].dev_persist) {
				if(!failure)
					Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
						dev->GetName(), L"' attempted to claim the port range 0x",
						Piston::String::Renderhex(low).PadLeft(high <= 0xff ? 2 : 4, L'0'), L" to 0x",
						Piston::String::Renderhex(high).PadLeft(high <= 0xff ? 2 : 4, L'0'),
						L", however one or more of these ports are already claimed by another device."),
						Piston::Gui::MessageBox::Icons::Warning);
				failure = true;
			} else
				maps[i].Set(persist, handlers);
		}
		return failure ? 0 : 1;
	}

	void Guest::Ports::Release(const void *persist, int16 low, int16 high) {
		GuestDev *dev = FindPersist(persist);
		if(!dev) {
			ZSSERT(0);
			return;
		}

		ZSSERT(0);
		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'",
			dev->GetName(), L"' called PortRelease, which is not yet implemented."),
			Piston::Gui::MessageBox::Icons::Warning);
	}
}