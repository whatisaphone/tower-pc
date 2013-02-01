#include "stdafx.h"
#include "GuestDev.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"
#include "Piston\Io\Path.h"

namespace Tower {
	PlugInitData GuestDev::Plug;
	DevInitData GuestDev::PlugDev;
	CpuInitData GuestDev::PlugCpu;
	VideoInitData GuestDev::PlugVideo;
	PicInitData GuestDev::PlugPic;

	// returns device types on success, (int32)(-1) on error
	int32 GuestDev::Load(ProfileDev &dev) {
		ZSSERT(!module.IsLoaded());
		this->persist = dev.GetPersist().Buffer();

		Piston::Finalizer<void()> freer(&module, &Piston::System::Module::Free);

		try {
			module.Load(dev.GetFileName());
			info = module.GetFunction<int32()>("tower_GetLibCaps")();
			if((info & 0xff00) != 0x0100)
				throw 0; // bad protocol version

			info = module.GetFunction<int32(const PlugInitData *, const void *, int32)>("tower_Init")
				(&Plug, dev.GetPersist().Buffer(), dev.GetPersist().Length());
			if(!info)
				throw 0; // no subdevice types?

			tower_Run = module.GetFunctionSafe<int32()>("tower_Run");
			tower_Pause = module.GetFunctionSafe<void()>("tower_Pause");
			tower_Reset = module.GetFunctionSafe<void()>("tower_Reset");
			tower_Uninit = module.GetFunctionSafe<void()>("tower_Uninit");
			tower_KeyDown = module.GetFunctionSafe<void(int32)>("tower_KeyDown");
			tower_KeyUp = module.GetFunctionSafe<void(int32)>("tower_KeyUp");
			tower_StatusMouseMove = module.GetFunctionSafe<void(const void *, sint32, sint32)>("tower_StatusMouseMove");
			tower_StatusMouseDown = module.GetFunctionSafe<void(const void *, int32, sint32, sint32)>("tower_StatusMouseDown");
			tower_StatusMouseUp = module.GetFunctionSafe<void(const void *, int32, sint32, sint32)>("tower_StatusMouseUp");
			tower_StatusMouseDblClk = module.GetFunctionSafe<void(const void *, int32, sint32, sint32)>("tower_StatusMouseDblClk");
			tower_StatusMouseWheel = module.GetFunctionSafe<void(const void *, sint32, sint32, sint32)>("tower_StatusMouseWheel");

			if(info & PLUGTYPE_GENERAL) {
				if(!module.GetFunction<int32(const DevInitData *)>("tower_dev_Init")(&PlugDev))
					throw 0;
			} if(info & PLUGTYPE_CPU) {
				tower_cpu_ExternalInterrupt = module.GetFunctionSafe<void()>("tower_cpu_ExternalInterrupt");
				if(!tower_Run || !tower_Pause || !tower_Reset || !tower_cpu_ExternalInterrupt)
					goto MissingExportsMsg;
				if(!module.GetFunction<int32(const CpuInitData *)>("tower_cpu_Init")(&PlugCpu))
					throw 0;
			} if(info & PLUGTYPE_VIDEO) {
				tower_Refresh = module.GetFunctionSafe<void(const void *)>("tower_vid_Refresh");
				if(!tower_Refresh)
					goto MissingExportsMsg;
				if(!module.GetFunction<int32(const VideoInitData *)>("tower_vid_Init")(&PlugVideo))
					throw 0;
			} if(info & PLUGTYPE_PIC) {
				tower_pic_INTA = module.GetFunctionSafe<int8()>("tower_pic_INTA");
				tower_pic_RaiseIRQ = module.GetFunctionSafe<void(int8)>("tower_pic_RaiseIRQ");
				if(!tower_pic_INTA || !tower_pic_RaiseIRQ)
					goto MissingExportsMsg;
				if(!module.GetFunction<int32(const PicInitData *)>("tower_pic_Init")(&PlugPic))
					throw 0;
			}
		} catch(...) {
			// no specific error messages -- should see those when building the profile
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"Error loading '",
				dev.GetFileName().GetFileTitle(), L"'."), Piston::Gui::MessageBox::Icons::Error);
			return (int32)-1;
		}

		freer.Cancel(); // success -- don't release module
		return info;

MissingExportsMsg:
		Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"Error loading '",
			dev.GetFileName().GetFileTitle(), L"' -- missing required exports."),
			Piston::Gui::MessageBox::Icons::Error);
		return (int32)-1;
	}

	void GuestDev::Unload() {
		if(running)
			Pause();
		if(module.IsLoaded()) {
			if(tower_Uninit) tower_Uninit();
			module.Free();
		}
	}














	/*bool GuestDev::Load(ProfileDev &info) {
		persist = info.GetPersist().Buffer();
		if(!GuestDevBase::Load(info.GetFileName(), PLUGTYPE_GENERAL))
			return false;

		tower_Init = module.GetProcAddressSafe<int32(const void *, const void *, int32)>("tower_dev_Init");
		tower_Run = module.GetProcAddressSafe<int32()>("tower_Run");
		tower_Pause = module.GetProcAddressSafe<void()>("tower_Pause");
		tower_KeyDown = module.GetProcAddressSafe<void(int32)>("tower_KeyDown");
		tower_Uninit = module.GetProcAddressSafe<void()>("tower_Uninit");
		if(!tower_Init) {
			Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"The device '",
				info.GetFileName().GetFileTitle(), L"' is missing one or more required exports "
				L"and cannot be loaded."), Piston::Gui::MessageBox::Icons::Error);
			return false;
		}

		if(!tower_Init(&PlugStruct, info.GetPersist().Buffer(), info.GetPersist().Length()))
			return false;
		if(tower_Reset) tower_Reset();
		return true;
	}

	bool GuestCpu::Load(ProfileDev &info) {
		persist = info.GetPersist().Buffer();
		if(!GuestDevBase::Load(info.GetFileName(), PLUGTYPE_CPU))
			return false;

		tower_Init = module.GetProcAddressSafe<int32(const void *, const void *, int32)>("tower_cpu_Init");
		tower_Run = module.GetProcAddressSafe<int32()>("tower_Run");
		tower_Pause = module.GetProcAddressSafe<void()>("tower_Pause");
		tower_Reset = module.GetProcAddressSafe<void()>("tower_Reset");
		tower_Uninit = module.GetProcAddressSafe<void()>("tower_Uninit");
		if(!tower_Init || !tower_Run || !tower_Pause || !tower_Reset || !tower_Uninit) {
				Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"The CPU '",
					info.GetFileName().GetFileTitle(), L"' is missing one or more required exports "
					L"and cannot be loaded."), Piston::Gui::MessageBox::Icons::Error);
				return false;
		}

		if(!tower_Init(&PlugStruct, info.GetPersist().Buffer(), info.GetPersist().Length()))
			return false;
		tower_Reset();
		return true;
	}

	bool GuestVideo::Load(ProfileDev &info) {
		persist = info.GetPersist().Buffer();
		if(!GuestDevBase::Load(info.GetFileName(), PLUGTYPE_VIDEO))
			return false;

		tower_Init = module.GetProcAddressSafe<int32(const void *, const void *, int32)>("tower_vid_Init");
		tower_Run = module.GetProcAddressSafe<int32()>("tower_Run");
		tower_Pause = module.GetProcAddressSafe<void()>("tower_Pause");
		tower_Uninit = module.GetProcAddressSafe<void()>("tower_Uninit");
		tower_vid_Refresh = module.GetProcAddressSafe<void(const void *)>("tower_vid_Refresh");
		if(!tower_Init || !tower_vid_Refresh) {
				Piston::Gui::MessageBox::Show(Piston::StringBuilder::Build(L"The display '",
					info.GetFileName().GetFileTitle(), L"' is missing one or more required exports "
					L"and cannot be loaded."), Piston::Gui::MessageBox::Icons::Error);
				return false;
		}

		if(!tower_Init(&PlugStruct, info.GetPersist().Buffer(), info.GetPersist().Length()))
			return false;
		if(tower_Reset) tower_Reset();
		return true;
	}*/
}