#pragma once
#include "stdafx.h"

#include "Piston\System\Module.h"

#include "ProfileDev.h"

namespace Tower {
	class GuestDev {
	private:
		unsigned int info;
		bool running : 1;

		GuestDev(const GuestDev &copy);
		GuestDev &operator=(const GuestDev &copy);

	protected:
		const void *persist;
		Piston::System::Module module;

		void (TOWER_CC *tower_Pause)();
		void (TOWER_CC *tower_Refresh)(const void *);
		void (TOWER_CC *tower_Reset)();
		int32 (TOWER_CC *tower_Run)();
		void (TOWER_CC *tower_Uninit)();
		void (TOWER_CC *tower_KeyDown)(int32);
		void (TOWER_CC *tower_KeyUp)(int32);
		void (TOWER_CC *tower_StatusMouseMove)(const void *item, sint32 x, sint32 y);
		void (TOWER_CC *tower_StatusMouseDown)(const void *item, int32 button, sint32 x, sint32 y);
		void (TOWER_CC *tower_StatusMouseUp)(const void *item, int32 button, sint32 x, sint32 y);
		void (TOWER_CC *tower_StatusMouseDblClk)(const void *item, int32 button, sint32 x, sint32 y);
		void (TOWER_CC *tower_StatusMouseWheel)(const void *item, sint32 delta, sint32 x, sint32 y);
		void (TOWER_CC *tower_cpu_ExternalInterrupt)();
		int8 (TOWER_CC *tower_pic_INTA)();
		void (TOWER_CC *tower_pic_RaiseIRQ)(int8 irq);

	public:
		static PlugInitData Plug;
		static DevInitData PlugDev;
		static CpuInitData PlugCpu;
		static VideoInitData PlugVideo;
		static PicInitData PlugPic;

		GuestDev() : running(false), tower_KeyDown(0), tower_KeyUp(0), tower_Run(0),
			tower_Pause(0), tower_Reset(0), tower_Refresh(0), tower_Uninit(0),
			tower_StatusMouseMove(0), tower_StatusMouseDown(0), tower_StatusMouseUp(0), tower_StatusMouseDblClk(0), tower_StatusMouseWheel(0) {}

		int32 Load(ProfileDev &dev);
		void Pause() {if(!running) return; if(tower_Pause) tower_Pause(); running = false;}
		void Refresh(const void *hDC) {if(tower_Refresh) tower_Refresh(hDC);}
		void Reset() {if(tower_Reset) tower_Reset();}
		void SendKeyDown(int32 keyCode) {if(tower_KeyDown) tower_KeyDown(keyCode);}
		void SendKeyUp(int32 keyCode) {if(tower_KeyUp) tower_KeyUp(keyCode);}
		void StatusMouseMove(const void *item, sint32 x, sint32 y) {if(tower_StatusMouseMove) tower_StatusMouseMove(item, x, y);}
		void StatusMouseDown(const void *item, int32 button, sint32 x, sint32 y) {if(tower_StatusMouseDown) tower_StatusMouseDown(item, button, x, y);}
		void StatusMouseUp(const void *item, int32 button, sint32 x, sint32 y) {if(tower_StatusMouseUp) tower_StatusMouseUp(item, button, x, y);}
		void StatusMouseDblClk(const void *item, int32 button, sint32 x, sint32 y) {if(tower_StatusMouseDblClk) tower_StatusMouseDblClk(item, button, x, y);}
		void StatusMouseWheel(const void *item, sint32 delta, sint32 x, sint32 y) {if(tower_StatusMouseWheel) tower_StatusMouseWheel(item, delta, x, y);}
		bool Run() {if(running) return true; return running = ((tower_Run ? tower_Run() : 1) & 1) != 0;}
		void Unload();
		void cpu_ExternalInterrupt() {tower_cpu_ExternalInterrupt();}
		int8 pic_INTA() {ZSSERT(tower_pic_INTA); return tower_pic_INTA();}
		void pic_RaiseIRQ(int8 irq) {if(tower_pic_RaiseIRQ) tower_pic_RaiseIRQ(irq);}

		Piston::String GetName() const {return module.GetFileName().GetFileTitle();}
		const void *GetPersist() const {return persist;}
		bool IsRunning() const {return running;}
	};



























	/*class GuestDev : public GuestDevBase {
	private:
		GuestDev(const GuestDev &copy);
		GuestDev &operator=(const GuestDev &copy);

	public:
		static DevInitData PlugStruct;

		GuestDev() {}

		bool Load(ProfileDev &info);
	};

	class GuestCpu : public GuestDevBase {
	private:
		GuestCpu(const GuestCpu &copy);
		GuestCpu &operator=(const GuestCpu &copy);

	public:
		static CpuInitData PlugStruct;

		GuestCpu() {}

		bool Load(ProfileDev &info);
	};

	class GuestVideo : public GuestDevBase {
	private:
		GuestVideo(const GuestVideo &copy);
		GuestVideo &operator=(const GuestVideo &copy);

		void (*tower_vid_Refresh)(const void *);

	public:
		static VideoInitData PlugStruct;

		GuestVideo() {}

		bool Load(ProfileDev &info);
		void Refresh(const void *hDC) {if(tower_vid_Refresh) tower_vid_Refresh(hDC);}
	};*/
}