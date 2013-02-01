#include "stdafx.h"
#include "Guest.h"

#include "Piston\Memory.h"
#include "Piston\Gui\MessageBox.h"

#include "Logger.h"
#include "MainForm.h"

namespace Tower {
	int Guest::DevCount;
	GuestDev *Guest::Devs;
	GuestDev *Guest::Cpu;
	GuestDev *Guest::Video;
	GuestDev *Guest::Pic;
	const Profile *Guest::profile;

	bool Guest::Init(Piston::Win32::HWND dlgOwner, Profile &profile) {
		if(!GuestDev::Plug.DlgOwner) {
			GuestDev::Plug.DlgOwner = dlgOwner;
			GuestDev::Plug.Log = &Logger::Log;
			GuestDev::Plug.StatusItems.Register = &MainForm::Status_Register;
			GuestDev::Plug.StatusItems.Resize = &MainForm::Status_SetWidth;
			GuestDev::Plug.StatusItems.SetText = &MainForm::Status_SetText;

			GuestDev::PlugDev.MemMapAdd = &Guest::Ram::MapAdd;
			GuestDev::PlugDev.MemMapRemove = &Guest::Ram::MapRemove;
			GuestDev::PlugDev.PortClaim = &Guest::Ports::Claim;
			GuestDev::PlugDev.PortRelease = &Guest::Ports::Release;
			GuestDev::PlugDev.MemRead8 = &Ram::Read8;
			GuestDev::PlugDev.MemRead16 = &Ram::Read16;
			GuestDev::PlugDev.MemRead32 = &Ram::Read32;
			GuestDev::PlugDev.MemWrite8 = &Ram::Write8;
			GuestDev::PlugDev.MemWrite16 = &Ram::Write16;
			GuestDev::PlugDev.MemWrite32 = &Ram::Write32;
			GuestDev::PlugDev.PortRead8 = &Ports::Read8;
			GuestDev::PlugDev.PortRead16 = &Ports::Read16;
			GuestDev::PlugDev.PortRead32 = &Ports::Read32;
			GuestDev::PlugDev.PortWrite8 = &Ports::Write8;
			GuestDev::PlugDev.PortWrite16 = &Ports::Write16;
			GuestDev::PlugDev.PortWrite32 = &Ports::Write32;

			GuestDev::PlugDev.RaiseIRQ = &RaiseIRQ;
			GuestDev::PlugDev.ResizeScreen = &MainForm::ResizeScreen; // TODO: remove this!

			Piston::Memory::Copy(&GuestDev::PlugCpu, &GuestDev::PlugDev, sizeof(DevInitData));
			GuestDev::PlugCpu.INTA = &INTA;
			GuestDev::PlugCpu.TimePassed = &TimePassed;

			Piston::Memory::Copy(&GuestDev::PlugVideo, &GuestDev::PlugDev, sizeof(DevInitData));
			GuestDev::PlugVideo.DisplayWindow = MainForm::GetDisplayWindow();
			GuestDev::PlugVideo.ResizeScreen = &MainForm::ResizeScreen;

			Piston::Memory::Copy(&GuestDev::PlugPic, &GuestDev::PlugDev, sizeof(DevInitData));
			GuestDev::PlugPic.ExternalInterrupt = &ExternalInterrupt;
		}

		Guest::profile = &profile;

		Unload(); // start with a clean slate

		if(!Ram::Init(profile.RamSize)) {
			Piston::Gui::MessageBox::Show(L"TODO: status bar ram failed");
			return false;
		}

		if(!Ports::Init()) {
			Piston::Gui::MessageBox::Show(L"TODO: status bar portz failed");
			return false;
		}

		DevCount = profile.Devs.Count();
		Devs = new GuestDev[(unsigned int)DevCount];
		for(int i = 0; i < DevCount; ++i) {
			int32 type = Devs[i].Load(profile.Devs[i]);
			if(type == (int32)-1) {
				Piston::Gui::MessageBox::Show(L"TODO: status bar device " + Piston::String::Render(i) + L" failed");
				return false;
			}
			if(type & PLUGTYPE_CPU) {
				if(Cpu) {
					Piston::Gui::MessageBox::Show(L"ERROR: Multiple CPU's", Piston::Gui::MessageBox::Icons::Error);
					return false;
				}
				Cpu = &Devs[i];
			} if(type & PLUGTYPE_VIDEO) {
				if(Video) {
					Piston::Gui::MessageBox::Show(L"ERROR: Multiple video plugins", Piston::Gui::MessageBox::Icons::Error);
					return false;
				}
				Video = &Devs[i];
			} if(type & PLUGTYPE_PIC) {
				if(Pic) {
					Piston::Gui::MessageBox::Show(L"ERROR: Multiple PIC plugins", Piston::Gui::MessageBox::Icons::Error);
					return false;
				}
				Pic = &Devs[i];
			}
		}

		if(!Cpu) {
			Piston::Gui::MessageBox::Show(L"You must load a CPU.", Piston::Gui::MessageBox::Icons::Error);
			return false;
		} if(!Video) {
			if(Piston::Gui::MessageBox::Show(L"Warning: You have not chosen a display device.  "
				L"Are you sure you want to continue?", Piston::Gui::MessageBox::Buttons::YesNo |
				Piston::Gui::MessageBox::Icons::Warning) != Piston::Gui::MessageBox::Result::Yes)
					return false;
		} if(!Pic) {
			if(Piston::Gui::MessageBox::Show(L"Warning: No PIC.  Continue?",
				Piston::Gui::MessageBox::Buttons::YesNo |
				Piston::Gui::MessageBox::Icons::Warning) != Piston::Gui::MessageBox::Result::Yes)
					return false;
		}

		Reset();
		return true;
	}

	void Guest::Unload() {
		if(!IsLoaded())
			return;

		if(Devs) {
			for(int i = DevCount - 1; i >= 0; --i) {
				Devs[i].Pause();
				Devs[i].Unload();
			}
			delete [] Devs;
			Devs = 0;
		}
		Cpu = 0;
		Video = 0;
		Pic = 0;

		Ports::Uninit();
		Ram::Uninit();
	}

	bool Guest::Run() {
		for(int i = 0; i < DevCount; ++i)
			if(!Devs[i].Run()) {
				Pause();
				Piston::Gui::MessageBox::Show(L"TODO: status bar device " + Piston::String::Render(i) + L" failed");
				return false;
			}

		return true;
	}

	void Guest::Pause() {
		ZSSERT(IsLoaded());

		for(int i = 0; i < DevCount; ++i)
			Devs[i].Pause();
	}

	void TOWER_CC Guest::TimePassed(int32 milliseconds) { // VERY TEMPORARY...
		//int32 ticks_18p2 = Ram::Read32(0x46c);

		//if(Pic) Pic->pic_RaiseIRQ(0);
		//Ram::Write32(0x46c, ++ticks_18p2);

		static int32 ticks_18p2;

		if((++ticks_18p2 % 32) == 1)
			MainForm::RepaintScreen();
	}

	void Guest::Reset() {
		ZSSERT(IsLoaded());
		bool wasRunning = IsRunning();

		if(wasRunning)
			Pause();

		for(int i = 0; i < DevCount; ++i)
			Devs[i].Reset();

		if(wasRunning)
			Run();
	}

	GuestDev *Guest::FindPersist(const void *persist) {
		ZSSERT(IsLoaded());
		if(Devs)
			for(int i = 0; i < DevCount; ++i)
				if(Devs[i].GetPersist() == persist)
					return &Devs[i];
		return 0;
	}

	void Guest::SendKeyDown(int32 keyInfo) {
		if(Devs)
			for(int i = 0; i < DevCount; ++i)
				Devs[i].SendKeyDown(keyInfo);
	}

	void Guest::SendKeyUp(int32 keyInfo) {
		if(Devs)
			for(int i = 0; i < DevCount; ++i)
				Devs[i].SendKeyUp(keyInfo);
	}
}