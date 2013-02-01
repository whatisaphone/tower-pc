#include "stdafx.h"

#include "Piston\Gui\MessageBox.h"
#include "Piston\Io\File.h"

#include "Config.h"
#include "calls.h"
#include "DiskChange.h"

namespace Tower { namespace Hle {
	const PlugInitData *plug;
	const DevInitData *plug_dev;
	const void *plug_persist;
	const void *plug_status_a;
	const void *plug_status_c;
	const void *plug_status_d;

	int8 TOWER_CC Read8(int16 port);
	int16 TOWER_CC Read16(int16 port);
	int32 TOWER_CC Read32(int16 port);
	void TOWER_CC Write8(int16 port, int8 value);
	void TOWER_CC Write16(int16 port, int16 value);
	void TOWER_CC Write32(int16 port, int32 value);

	// not endian correct
	int32 regs[9];
	int32 *const eax = &regs[0];		int32 *const ecx = &regs[1];
	int32 *const edx = &regs[2];		int32 *const ebx = &regs[3];
	int32 *const esi = &regs[4];		int32 *const edi = &regs[5];
	int32 *const es = &regs[6];			int32 *const ds = &regs[7];
	int32 *const eflags = &regs[8];

	int16 *const ax = (int16 *)eax;		int16 *const cx = (int16 *)ecx;
	int16 *const dx = (int16 *)edx;		int16 *const bx = (int16 *)ebx;
	int16 *const si = (int16 *)esi;		int16 *const di = (int16 *)edi;
	int16 *const flags = (int16 *)eflags;

	int8 *const al = (int8 *)ax;		int8 *const ah = al + 1;
	int8 *const cl = (int8 *)cx;		int8 *const ch = cl + 1;
	int8 *const dl = (int8 *)dx;		int8 *const dh = dl + 1;
	int8 *const bl = (int8 *)bx;		int8 *const bh = bl + 1;

	TOWER_EXPORT int32 tower_GetLibCaps() {
		return 0x01 << 8; // dll protocol ver 0x01
	}

	TOWER_EXPORT int32 tower_Init(const PlugInitData *init, const void *persist, int32 persist_len) {
		Piston::Gui::MessageBox::SetDefaultOwner((Piston::Win32::HWND)init->DlgOwner);
		Piston::Gui::MessageBox::SetDefaultCaption(L"Tower HLE 0.01");

		plug = init;
		plug_persist = persist;
		Config::Parse(persist, persist_len);

		if(Config::Drives[0].Enabled)
			plug_status_a = plug->StatusItems.Register(plug_persist, 2000, 50, L"A:");
		if(Config::Drives[1].Enabled)
			plug_status_c = plug->StatusItems.Register(plug_persist, 2001, 50, L"C:");
		if(Config::Drives[2].Enabled)
			plug_status_d = plug->StatusItems.Register(plug_persist, 2002, 50, L"D:");

		return PLUGTYPE_GENERAL;
	}

	TOWER_EXPORT int32 tower_dev_Init(const DevInitData *init) {
		plug_dev = init;

		PortHandlers h = {&Read8, &Read16, &Read32, &Write8, &Write16, &Write32};
		if(!init->PortClaim(plug_persist, 0xface, 0xface, &h))
			return 0;
		if(!int_13_init())
			return 0;

		return 1;
	}

	TOWER_EXPORT void tower_Uninit() {
		int_13_cleanup();
	}

	TOWER_EXPORT void tower_StatusMouseDblClk(const void *item, int button, int x, int y) {
		DiskChange *d;
		int n;

		if(button != 1) return;

		if(item == plug_status_a)
			d = new DiskChange(L'A');
		else if(item == plug_status_c)
			d = new DiskChange(L'C');
		else if(item == plug_status_d)
			d = new DiskChange(L'D');
		else {ZSSERT(0); return;}

		ZSSERT(d);
		d->ShowDialog((Piston::Win32::HWND)plug->DlgOwner);

		delete d;
	}

	int8 TOWER_CC Read8(int16 port) {plug->Log(plug_persist, 3, L"Bad 8-bit read from Hle"); return 0xff;}
	int32 TOWER_CC Read32(int16 port) {plug->Log(plug_persist, 3, L"Bad 32-bit read from Hle"); return 0xffffffff;}
	void TOWER_CC Write8(int16 port, int8 value) {plug->Log(plug_persist, 3, L"Bad 8-bit write to Hle");}
	void TOWER_CC Write32(int16 port, int32 value) {plug->Log(plug_persist, 3, L"Bad 32-bit write to Hle");}

	// 16-bit is where the magic happens
	int16 TOWER_CC Read16(int16 port) {
		static int cur_reg;
		int16 ret = (int16)regs[cur_reg];
		cur_reg = (cur_reg + 1) % 9;
		return ret;
	}

	void TOWER_CC Write16(int16 port, int16 value) {
		static int cur_reg;
		if(cur_reg < 9)
			regs[cur_reg++] = value;
		else {
			switch(value) { // the real interrupt number
			case 0x09: int_09(); break;
			case 0x10: int_10(); break;
			case 0x13: int_13(); break;
			case 0x15: int_15(); break;
			case 0x16: int_16(); break;
			case 0x1a: int_1a(); break;
			default:
				plug->Log(plug_persist, LOG_WARNING, L"INT 0x" +
					Piston::String::Renderhex(value).PadLeft(2, L'0') + L" unhandled (ax = " +
					Piston::String::Renderhex(*ax).PadLeft(4, L'0') + L")");
			}
			cur_reg = 0;
		}
	}
}}