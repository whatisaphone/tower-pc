#include "stdafx.h"
#include "calls.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

#include "Config.h"

namespace Tower { namespace Hle {
	rtd drives[3];

	bool int_13_init() {
		drives[0].bytes_per_sect = 512;
		drives[0].sect_per_cyl = 18;
		drives[0].cyl_per_head = 80;
		drives[0].heads = 2;

		drives[1].bytes_per_sect = 512;
		drives[1].sect_per_cyl = 63;
		drives[1].cyl_per_head = 32;
		drives[1].heads = 16;

		for(int d = 0; d < 3; ++d) {
			drives[d].file = new Piston::Io::File();

			if(Config::Drives[d].Enabled && Config::Drives[d].Mounted) try {
				drives[d].file->Open(Config::Drives[d].File, Config::Drives[d].Readonly ? Piston::Io::File::Access::Read : Piston::Io::File::Access::ReadWrite, Piston::Io::File::Sharing::ReadWrite);
			} catch(...) {
				Piston::Gui::MessageBox::Show(L"Error opening image for drive "
					+ Piston::String::Render(d), Piston::Gui::MessageBox::Icons::Error);
				return false;
			}
		}

		return true;
	}

	void int_13_cleanup() {
		for(int d = 0; d < 3; ++d) {
			drives[d].file->Close();
			delete drives[d].file;
		}
	}

	int WhichDrive(int8 biosval) {
		if(biosval == 0x00 && Config::Drives[0].Enabled)
			return 0;
		else if(biosval == 0x80 && Config::Drives[1].Enabled)
			return 1;
		else
			return 0xff;
	}

	static void Error(int8 value) {
		*flags |= flags_mask_cf;
		plug_dev->MemWrite8(0x441, value);
		*ax = value << 8;
	}

	static void Success() {
		*flags &= ~flags_mask_cf;
		plug_dev->MemWrite8(0x441, 0);
		*ah = 0;
	}

	static void Reset() { // ah = 0x00
		// dl = drive
		// RETURNS: cf on error
		//			ah = status

		int d = WhichDrive(*dl);
		if(d == 0xff) {
			Error(1);
			return;
		}

		Success();
	}

	static void ReadSectors() { // ah = 0x02
		// al = number of sectors to read
		// ch = low 8 bits of cylinder #
		// cl = sector number in [0..5]; for HDs, high 2 bits of cylinder # in [6..7]
		// dh = head
		// dl = drive, bit7 for HD
		// es:bx = dest buffer
		// RETURNS: CF on error, NO CF on success
		//			ah = status
		//			al = # of sectors transferred

		int d = WhichDrive(*dl);
		if(d == 0xff) {
			Error(1);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Read sectors: failed, bad drive.");
			return;
		} else if(!Config::Drives[d].Mounted) {
			Error(0x31);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Read sectors: failed, no media in guest drive.");
			return;
		} else if((*ch >= drives[d].cyl_per_head) | (*dh >= drives[d].heads)) {
			Error(4); // bad sector
			plug->Log(plug_persist, LOG_ERROR,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Read sectors: sector out of range.");
			return;
		}

		int32 log_sect = drives[d].sect_per_cyl * (*ch * drives[d].heads + *dh) + *cl - 1;
		Piston::Io::MemoryBuffer data(drives[d].bytes_per_sect);
		drives[d].file->Seek(log_sect * drives[d].bytes_per_sect);
		for(int i = 0; i < *al; ++i) {
			try {
				drives[d].file->Read(data.Buffer(), drives[d].bytes_per_sect);
				for(int j = 0; j < drives[d].bytes_per_sect; j += 4)
					plug_dev->MemWrite32((*es << 4) + *bx + (i * drives[d].bytes_per_sect) + j, *(int32 *)((int8 *)data.Buffer() + j));
			} catch(...) {
				plug->Log(plug_persist, LOG_ERROR,
					L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
					L"Read sectors: failed on image read.");
				Error(2);
				return;
			}
		}

		Success();
		/*plug->Log(plug_persist, LOG_TRACE, Piston::StringBuilder::Build(
			Piston::String::Render(*al),
			L" sect0rs from cyl 0x", Piston::String::Renderhex(*ch | ((*cl & 0xc0) << 2)).PadLeft(2, L'0'),
			L", head 0x", Piston::String::Renderhex(*dh).PadLeft(2, L'0'),
			L", sect 0x", Piston::String::Renderhex(*cl & 0x3f).PadLeft(2, L'0'),
			L" --> " + Piston::String::Renderhex(*es).PadLeft(4, L'0'),
			L":" + Piston::String::Renderhex(*bx).PadLeft(4, L'0')));*/
		if(d == 0)
			plug_dev->MemWrite8(0x442, 0x20 | (*dh << 2)); // seek complete + current head
	}

	static void WriteSectors() {
		// al = sector count
		// ch = low 8 bits of cylinder #
		// cl = sector number in [0..5]; for HDs, high 2 bits of cylinder # in [6..7]
		// dh = head
		// dl = drive, bit7 for HD
		// es:bx = data
		// RETURNS: CF on error, !CF on success
		//			ah = status
		//			al = # of sectors transferred

		int d = WhichDrive(*dl);
		if(d == 0xff) {
			Error(1);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Write sectors: failed, bad drive.");
			return;
		} else if(!Config::Drives[d].Mounted) {
			Error(0x31);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Write sectors: failed, no media in guest drive.");
			return;
		} else if((*ch >= drives[d].cyl_per_head) | (*dh >= drives[d].heads)) {
			Error(4); // bad sector
			plug->Log(plug_persist, LOG_ERROR,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Write sectors: sector out of range.");
			return;
		} else if(Config::Drives[d].Readonly) {
			Error(0x03); // write protected
			plug->Log(plug_persist, LOG_INFO,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Write sectors: failed, disk write protected.");
		}

		int32 log_sect = drives[d].sect_per_cyl * (*ch * drives[d].heads + *dh) + *cl - 1;
		drives[d].file->Seek(log_sect * drives[d].bytes_per_sect);
		try {
			for(int i = 0; i < *al * drives[d].bytes_per_sect; i += 4) {
				int32 dw = plug_dev->MemRead32((*es << 4) + *bx + i);
				drives[d].file->Write(&dw, 4);
			}
		} catch(...) {
			plug->Log(plug_persist, LOG_ERROR,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Write sectors: failed on image write.");
			Error(2);
			return;
		}

		Success();
		if(d == 0)
			plug_dev->MemWrite8(0x442, 0x20 | (*dh << 2)); // seek complete + current head
	}

	static void VerifySectors() {
		// al = sector count
		// ch = low 8 bits of cylinder #
		// cl = sector number in [0..5]; for HDs, high 2 bits of cylinder # in [6..7]
		// dh = head
		// dl = drive, bit7 for HD
		// RETURNS: CF on error, !CF on success
		//			ah = status
		//			al = # of sectors verified

		int d = WhichDrive(*dl);
		if(d == 0xff) {
			Error(1);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Verify sectors: failed, bad drive.");
			return;
		} else if(!Config::Drives[d].Mounted) {
			Error(0x31);
			plug->Log(plug_persist, LOG_WARNING,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Verify sectors: failed, no media in guest drive.");
			return;
		} else if((*ch >= drives[d].cyl_per_head) | (*dh >= drives[d].heads)) {
			Error(4); // bad sector
			plug->Log(plug_persist, LOG_ERROR,
				L"[DRV" + Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L"] "
				L"Verify sectors: sector out of range.");
			return;
		}

		Success();
		if(d == 0)
			plug_dev->MemWrite8(0x442, 0x20 | (*dh << 2)); // seek complete + current head
	}

	void GetParams() { // ah = 0x08
		// dl = drive
		// RETURNS: cf set on error
		//          ax = 0
		//          bl = if floppy, type: 1=360K, 2=1.2M, 3=720K, 4=1.44M, 5=???, 6=2.88M 0x10=atapi/other
		//          ch = low 8 bits of max cyl
		//          cl = [0..5]:max sector, [6..7]:high two bits of max cyl
		//          dh = max head
		//          dl = number of drives
		//          [TODO:] es:di = if floppy, drive parameter table

		int d = WhichDrive(*dl);
		if(d == 0xff) {
			plug->Log(plug_persist, LOG_INFO, L"Query drive 0x" +
				Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L": failed. Error 7.");
			Error(7);
			return;
		}

		plug->Log(plug_persist, LOG_INFO, L"Query drive 0x" +
			Piston::String::Renderhex(*dl).PadLeft(2, L'0') + L": success.");
		*ax = 0;
		if(d == 0)
			*bl = 4; // 1.44M
		*ch = drives[d].cyl_per_head - 1;
		*cl = drives[d].sect_per_cyl;
		*dh = drives[d].heads - 1;
		*dl = 1;
		*flags &= ~flags_mask_cf;
	}

	void int_13() {
		switch(*ah) {
		case 0x00: Reset(); break;
		case 0x02: ReadSectors(); break;
		case 0x03: WriteSectors(); break;
		case 0x04: VerifySectors(); break;
		case 0x08: GetParams(); break;
		default:
			plug->Log(plug_persist, LOG_ERROR, L"INT13: Undefined parameter in ah: 0x" +
				Piston::String::Renderhex(*ah).PadLeft(2, L'0') + L".");
			Error(1);
		}
	}
}}