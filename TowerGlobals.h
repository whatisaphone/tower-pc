#pragma once

#define TOWER_CC //__fastcall
#define TOWER_EXPORT extern "C" __declspec(dllexport)
#define TOWER_STRING wchar_t *

namespace Tower {
	typedef unsigned char int8;
	typedef signed char sint8;
	typedef unsigned short int16;
	typedef signed short sint16;
	typedef unsigned int int32;
	typedef signed int sint32;
	typedef unsigned __int64 int64;
	typedef signed __int64 sint64;

	const unsigned int LOG_VERBOSE = 1;
	const unsigned int LOG_TRACE = 2;
	const unsigned int LOG_DEBUG = 4;
	const unsigned int LOG_INFO = 6;
	const unsigned int LOG_WARNING = 8;
	const unsigned int LOG_ERROR = 10;
	const unsigned int LOG_CRITICAL = 12;
	const unsigned int LOG_FATAL = 15;

	const unsigned int PLUGTYPE_INVALID = 0;
	const unsigned int PLUGTYPE_GENERAL = 1;
	const unsigned int PLUGTYPE_CPU = 2;
	const unsigned int PLUGTYPE_VIDEO = 4;
	const unsigned int PLUGTYPE_PIC = 8;

	struct MemHandlers {
		int8 (TOWER_CC *Read8)(int32 addr);
		int16 (TOWER_CC *Read16)(int32 addr);
		int32 (TOWER_CC *Read32)(int32 addr);
		void (TOWER_CC *Write8)(int32 addr, int8 data);
		void (TOWER_CC *Write16)(int32 addr, int16 data);
		void (TOWER_CC *Write32)(int32 addr, int32 data);
	};

	struct PortHandlers {
		int8 (TOWER_CC *Read8)(int16 port);
		int16 (TOWER_CC *Read16)(int16 port);
		int32 (TOWER_CC *Read32)(int16 port);
		void (TOWER_CC *Write8)(int16 port, int8 data);
		void (TOWER_CC *Write16)(int16 port, int16 data);
		void (TOWER_CC *Write32)(int16 port, int32 data);
	};

	struct PlugInitData {
		const void *DlgOwner;
		void (TOWER_CC *Log)(const void *persist, unsigned int level, const TOWER_STRING text);
		struct {
			const void *(TOWER_CC *Register)(const void *persist, int32 priority, sint32 width, const TOWER_STRING text);
			void (TOWER_CC *Resize)(const void *item, sint32 width); // settings for width: 0=autosize (collapse), -1=autosize(expand), 0-0xffff=pixels
			void (TOWER_CC *SetBackcolor)(const void *item, int32 color);
			void (TOWER_CC *SetText)(const void *item, const TOWER_STRING text);
			void (TOWER_CC *SetTooltip)(const void *item, const TOWER_STRING tip);
		} StatusItems;
	};

	struct DevInitData {
		int8 *(TOWER_CC *MemMapAdd)(const void *persist, int32 dev_lo, int32 dev_hi, const MemHandlers *handlers);
		void (TOWER_CC *MemMapRemove)(const void *persist, int32 dev_lo);
		int32 (TOWER_CC *PortClaim)(const void *persist, int16 low, int16 high, const PortHandlers *handlers);
		void (TOWER_CC *PortRelease)(const void *persist, int16 low, int16 high);

		int8 (TOWER_CC *MemRead8)(int32 addr);
		int16 (TOWER_CC *MemRead16)(int32 addr);
		int32 (TOWER_CC *MemRead32)(int32 addr);
		void (TOWER_CC *MemWrite8)(int32 addr, int8 data);
		void (TOWER_CC *MemWrite16)(int32 addr, int16 data);
		void (TOWER_CC *MemWrite32)(int32 addr, int32 data);

		int8 (TOWER_CC *PortRead8)(int16 port);
		int16 (TOWER_CC *PortRead16)(int16 port);
		int32 (TOWER_CC *PortRead32)(int16 port);
		void (TOWER_CC *PortWrite8)(int16 port, int8 value);
		void (TOWER_CC *PortWrite16)(int16 port, int16 value);
		void (TOWER_CC *PortWrite32)(int16 port, int32 value);

		void (TOWER_CC *RaiseIRQ)(int8 irq);

		// only temporary!!! until proper vga is added in
		void (TOWER_CC *ResizeScreen)(const void *persist, int32 width, int32 height);
	};

	struct CpuInitData : public DevInitData {
		int8 (TOWER_CC *INTA)();
		void (TOWER_CC *TimePassed)(int32 milliseconds);
	};

	struct VideoInitData : public DevInitData {
		const void *DisplayWindow;
	};

	struct PicInitData : public DevInitData {
		void (TOWER_CC *ExternalInterrupt)();
	};
}

TOWER_EXPORT Tower::int32 tower_GetLibCaps();
TOWER_EXPORT Tower::int32 tower_Init(const Tower::PlugInitData *init, const void *persist, Tower::int32 persist_len);
TOWER_EXPORT Tower::int32 tower_Run();
TOWER_EXPORT void tower_Pause();
TOWER_EXPORT void tower_Reset();
TOWER_EXPORT void tower_Uninit();

// on win32, keyInfo contains:
//   bits 0-15:  virtual key code
//   bits 16-23: system-reported scan code
//   bit 24:     extended key?
//   bit 29:     alt key down?
//   bit 30:     key previously down?
//   bit 31:     key currently down? 1 for tower_KeyDown, 2 for tower_KeyUp
TOWER_EXPORT void tower_KeyDown(Tower::int32 keyInfo);
TOWER_EXPORT void tower_KeyUp(Tower::int32 keyInfo);

TOWER_EXPORT void tower_StatusMouseMove(const void *item, Tower::sint32 x, Tower::sint32 y);
TOWER_EXPORT void tower_StatusMouseDown(const void *item, Tower::int32 button, Tower::sint32 x, Tower::sint32 y);
TOWER_EXPORT void tower_StatusMouseUp(const void *item, Tower::int32 button, Tower::sint32 x, Tower::sint32 y);
TOWER_EXPORT void tower_StatusMouseDblClk(const void *item, Tower::int32 button, Tower::sint32 x, Tower::sint32 y);
TOWER_EXPORT void tower_StatusMouseWheel(const void *item, Tower::sint32 delta, Tower::sint32 x, Tower::sint32 y);



TOWER_EXPORT Tower::int32 tower_opt_Init(const Tower::PlugInitData *init, const void *persist, Tower::int32 persist_len);
TOWER_EXPORT Tower::int32 tower_opt_Show(const void *container);
TOWER_EXPORT Tower::int32 tower_opt_Hide(void **persist, Tower::int32 *persist_len);
TOWER_EXPORT void tower_opt_Uninit(void *persist, Tower::int32 persist_len);

TOWER_EXPORT Tower::int32 tower_dev_Init(const Tower::DevInitData *init);

TOWER_EXPORT Tower::int32 tower_cpu_Init(const Tower::CpuInitData *init);

TOWER_EXPORT Tower::int32 tower_vid_Init(const Tower::VideoInitData *init);
TOWER_EXPORT void tower_vid_Refresh(const void *drawingSurface);

TOWER_EXPORT Tower::int32 tower_pic_Init(const Tower::PicInitData *init);
TOWER_EXPORT void tower_pic_RaiseIrq(Tower::int8 irq);
TOWER_EXPORT Tower::int8 tower_pic_INTA();