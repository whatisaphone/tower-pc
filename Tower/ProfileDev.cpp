#include "stdafx.h"
#include "ProfileDev.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

/*typedef struct {} nothrow;

class my_class {
public:
    template<typename T> void *search(int what);
};

template<typename T> void *my_class::search(int what) {
    throw "error";
}

template<> void *my_class::search<nothrow>(int what) {
    return 0;
}

int main() {
    my_class c;
    c.search<nothrow>(42); // OK!
    c.search(42);          // ambiguous template parameter
    c.search("fea");       // ambiguous template parameter
    c.search(43.7);        // ambiguous template parameter
}*/

namespace Tower {
	//const wchar_t *ProfileDev::GetDevName(unsigned int type) {
	//	static const wchar_t *devs[] = {L"invalid device", L"device", L"CPU", L"display"};
	//	return devs[type <= (sizeof(devs) / sizeof(devs[0])) ? type : 0];
	//}

	void ProfileDev::Free() {
		ZSSERT(optionsState == 0);

		hasOptions = 0;
		optionsState = 0;
		opt_Init = 0;
		opt_Show = 0;
		opt_Hide = 0;
		opt_Uninit = 0;
		mod.Free();
	}

	// returns (int32)(-1) on error
	int32 ProfileDev::Load() {
		ZSSERT(!mod.IsLoaded()); // not twice?

		hasOptions = 0;
		optionsState = 0;
		Piston::Finalizer<void()> freer(&mod, &Piston::System::Module::Free);

		try {
			mod.Load(fileName);
			info = mod.GetFunction<unsigned int()>("tower_GetLibCaps")();
		} catch(...) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L" '", fileName.GetFileTitle(),
				L"' is not a Tower device."), Piston::Gui::MessageBox::Icons::Error);
			return (int32)-1;
		}

		if((info & 0xff00) < 0x0100) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", fileName.GetFileTitle(),
				L"' was built for an older version of Tower.  Please obtain a newer version "
				L"of this device."), Piston::Gui::MessageBox::Icons::Warning);
			return (int32)-1;
		} else if((info & 0xff00) > 0x0100) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", fileName.GetFileTitle(),
				L"' was built for a newer version of Tower.  Please visit the Tower website to see "
				L"if an upgrade is available."), Piston::Gui::MessageBox::Icons::Warning);
			return (int32)-1;
		}

		opt_Init = mod.GetFunctionSafe<int32 TOWER_CC(const void *, int32)>("tower_opt_Init");
		opt_Show = mod.GetFunctionSafe<int32 TOWER_CC(const void *)>("tower_opt_Show");
		opt_Hide = mod.GetFunctionSafe<int32 TOWER_CC(void **, int32 *)>("tower_opt_Hide");
		opt_Uninit = mod.GetFunctionSafe<void TOWER_CC(void *, int32)>("tower_opt_Uninit");
		if(opt_Init && opt_Show && opt_Hide && opt_Uninit)
			hasOptions = 1;
		else if(opt_Init || opt_Show || opt_Hide || opt_Uninit)
			hasOptions = 2; // error, not all exports found

		freer.Cancel(); // don't free module
		return info; // from GetLibCaps
	}

	// returns: 1=ok, 0x80000000=error
	int32 ProfileDev::OptionsShow(Piston::Win32::HWND container) {
		ZSSERT(mod.IsLoaded());
		ZSSERT(hasOptions == 1);

		//if(hasOptions == 0) return 0;
		//if(hasOptions != 1) return 0x80000000;

		try {if(opt_Init(persist.Buffer(), persist.Length()) != 1) return 0x80000000;}
		catch(...) {opt_Uninit(0, 0); return 0x80000000;}

		try {if(opt_Show(container) != 1) return 0x80000000;}
		catch(...) {opt_Uninit(0, 0); return 0x80000000;}

		optionsState = 2;
		return 1;
	}

	// returns: 0=no new data; 1=ok, new data valid; 2=retain focus; 0x80000000=error
	int32 ProfileDev::OptionsHide() {
		ZSSERT(mod.IsLoaded());
		if(optionsState != 2)
			return 0;

		int32 ret;
		void *new_persist = 0;
		int32 new_persist_len = 0;

		try {
			switch(opt_Hide(&new_persist, &new_persist_len)) {
			case 1:
				persist.Replace(new_persist, new_persist_len);
				ret = 1;
				break;
			case 2:
				ret = 2;
				break;
			default:
				ZSSERT(0);
				ret = 0x80000000;
			}
		} catch(...) {
			ret = 0x80000000;
		}

		if(ret != 2) {
			opt_Uninit(new_persist, new_persist_len);
			mod.Free();
			optionsState = 0;
		}

		return ret;
	}
}















/*#include "stdafx.h"
#include "ProfileDev.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

namespace Tower {
	const wchar_t *ProfileDevBase::GetDevName(unsigned int type) {
		static const wchar_t *devs[] = {L"invalid device", L"device", L"CPU", L"display"};
		return devs[type <= (sizeof(devs) / sizeof(devs[0])) ? type : 0];
	}

	// returns: 0=no options, 1=ok, 2=error
	int ProfileDevBase::ShowOptions(Piston::Win32::HWND container) {
		if(!tested)
			throw 0;

		if(!hasOptions)
			return 0;

		void *new_persist = (void *)persist.Buffer();
		int32 new_persist_len = persist.Length();

		try {mod.Load(fileName);}
		catch(...) {return 2;}

		try {if(opt_Init(new_persist, new_persist_len) != 1) return 2;}
		catch(...) {opt_Uninit(0, 0); return 2;}

		try {if(opt_Show(container) != 1) return 2;}
		catch(...) {opt_Uninit(0, 0); return 2;}

		return 1;
	}

	bool ProfileDevBase::Test(unsigned int expectedType) {
		if(tested)
			throw "twice??";

		tested = false;

		try {
			mod.Load(fileName);
			info = mod.GetProcAddress<unsigned int()>("tower_GetLibCaps")();
		} catch(...) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L" '", fileName.GetFileTitle(),
				L"' is not made for Tower."), Piston::Gui::MessageBox::Icons::Error);
			return false;
		}

		if((info & 0xff00) < 0x0100) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", fileName.GetFileTitle(),
				L"' was built for an older version of Tower.  Please obtain a newer version "
				L"of this device."), Piston::Gui::MessageBox::Icons::Warning);
			return false;
		} else if((info & 0xff00) > 0x0100) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", fileName.GetFileTitle(),
				L"' was built for a newer version of Tower.  Please visit the Tower website to see "
				L"if an upgrade is available."), Piston::Gui::MessageBox::Icons::Warning);
			return false;
		}

		if((info & 0xff) != expectedType) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", fileName.GetFileTitle(),
				L"' is a ", GetDevName(info & 0xff), L", we were expecting a ",
				GetDevName(expectedType), L"."), Piston::Gui::MessageBox::Icons::Error);
			return false;
		}

		opt_Init = mod.GetProcAddressSafe<int32 TOWER_CC(const void *, int32)>("tower_opt_Init");
		opt_Show = mod.GetProcAddressSafe<int32 TOWER_CC(const void *)>("tower_opt_Show");
		opt_Hide = mod.GetProcAddressSafe<int32 TOWER_CC(void **, int32 *)>("tower_opt_Hide");
		opt_Uninit = mod.GetProcAddressSafe<int32 TOWER_CC(void *, int32)>("tower_opt_Uninit");
		if(opt_Init && opt_Show && opt_Hide && opt_Uninit)
			hasOptions = 1;
		else if(opt_Init || opt_Show || opt_Hide || opt_Uninit)
			hasOptions = 2; // error, not all exports found

		return tested = TestSomeMore(mod);
	}

	bool ProfileCpu::Test() {
		return ProfileDevBase::Test(Tower::PLUGTYPE_CPU);
	}

	bool ProfileCpu::TestSomeMore(Piston::System::Module &module) {
		if(module.GetProcAddressSafe<bool(const DevInitData *, const void *, unsigned long)>("tower_cpu_Init") &&
			module.GetProcAddressSafe<bool()>("tower_Run") && 
			module.GetProcAddressSafe<void()>("tower_Pause") &&
			module.GetProcAddressSafe<void()>("tower_cpu_Reset"))
				return true;

		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", GetFileName().GetFileTitle(), L"' is missing one or more required exports, and cannot be loaded."), Piston::Gui::MessageBox::Icons::Error);
		return false;
	}

	bool ProfileDev::Test() {
		return ProfileDevBase::Test(Tower::PLUGTYPE_GENERAL);
	}

	bool ProfileDev::TestSomeMore(Piston::System::Module &module) {
		if(module.GetProcAddressSafe<bool(const DevInitData *, const void *, unsigned long)>("tower_dev_Init"))
			return true;

		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", GetFileName().GetFileTitle(),
			L"' is missing one or more required exports, and cannot be loaded."),
			Piston::Gui::MessageBox::Icons::Error);
		return false;
	}

	bool ProfileVideo::Test() {
		return ProfileDevBase::Test(Tower::PLUGTYPE_VIDEO);
	}

	bool ProfileVideo::TestSomeMore(Piston::System::Module &module) {
		if(module.GetProcAddressSafe<bool(const DevInitData *, const void *, unsigned long)>("tower_vid_Init") &&
		   module.GetProcAddressSafe<void(const void *)>("tower_vid_Refresh"))
			return true;

		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"'", GetFileName().GetFileTitle(),
			L"' is missing one or more required exports, and cannot be loaded."),
			Piston::Gui::MessageBox::Icons::Error);
		return false;
	}
}*/