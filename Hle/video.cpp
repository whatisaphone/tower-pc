#include "stdafx.h"
#include "calls.h"

#include "Piston\String.h"

namespace Tower { namespace Hle {
	void SetMode() {
		// al = desired mode*
		//
		// *supported modes:
		// mode | ??? |  chars | char |  pixels | clr | pgs |  addr
		//------+-----+--------+------+---------+-----+-----+--------
		// 0x03 | txt |  80x25 | 9x16 | 720x400 |  16 |  8  | 0xb800
		// 0x06 | gfx |  80x25 | 8x8  | 640x200 |   2 |  1  | 0xb800
		// 0x12 | gfx |  80x30 | 8x16 | 640x480 |  16 |  1  | 0xa000
		// 0x13 | gfx |  40x25 | 8x8  | 320x200 | 256 |  1  | 0xa000

		int32 screenCX, screenCY, bits, cols, rows, pages, charCX, charCY, ptr;

		switch(*al) {
		case 0x03:  screenCX = 720; screenCY = 400; bits = 4; cols = 80; rows = 25;
					pages = 8; charCX = 9; charCY = 16; ptr = 0xb8000; break;
		case 0x06:  screenCX = 640; screenCY = 200; bits = 1; cols = 80; rows = 25;
					pages = 1; charCX = 8; charCY = 8;  ptr = 0xb8000; break;
		case 0x10:	screenCX = 640; screenCY = 350; bits = 4; cols = 80; rows = 25;
					pages = 1; charCX = 8; charCY = 14; ptr = 0xa0000; break;
		case 0x12:  screenCX = 640; screenCY = 480; bits = 4; cols = 80; rows = 30;
					pages = 1; charCX = 8; charCY = 16; ptr = 0xa0000; break;
		case 0x13:  screenCX = 320; screenCY = 200; bits = 8; cols = 40; rows = 25;
					pages = 1; charCX = 8; charCY = 8;  ptr = 0xa0000; break;
		//case 0x13:  screenCX = 360; screenCY = 480; bits = 2; cols = 40; rows = 25;
		//			pages = 1; charCX = 8; charCY = 8;  ptr = 0xa0000; break;
		case 0x5f:	screenCX = 640; screenCY = 480; bits = 8; cols = 0;  rows = 0;
					pages = 1; charCX = 0; charCY = 0;  ptr = 0xa0000; break;
		default:
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] SetMode(0x" +
				Piston::String::Renderhex(*al).PadLeft(2, L'0') + L"): unsupported video mode");
			ZSSERT(0);
			return;
		}

		plug->Log(plug_persist, LOG_DEBUG, L"[VIDEO] SetMode(0x" +
			Piston::String::Renderhex(*al).PadLeft(2, L'0') + L")");
		plug_dev->MemWrite8(0x449, *al); // write new info to bios area
		plug_dev->MemWrite16(0x44a, cols);
		plug_dev->MemWrite16(0x44c, 0x1000);
		for(int page = 0; page < 8; ++page)
			plug_dev->MemWrite32(0x450 + (page << 2), 0);
		plug_dev->MemWrite8(0x484, rows - 1);
		plug_dev->MemWrite16(0x485, charCY);
		plug_dev->ResizeScreen(plug_persist, screenCX, screenCY);

		for(int i = 0; i < 0x7fff; i += 4)
			plug_dev->MemWrite32(ptr + i, 0); // clear video ram
	}

	void SetCursorShape() {
		// need impl
	}

	void SetCursorPos() {
		// bh = page #
		// dh = row
		// dl = col

		if(*bh > 7) {
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] SetCursorPos(): too high a page (" +
				Piston::String::Render(*bh) + L")");
			ZSSERT(0);
			return;
		}

		plug_dev->MemWrite16(0x450 + *bh * 4, *dh);
		plug_dev->MemWrite16(0x452 + *bh * 4, *dl);
	}

	void GetCursorPos() {
		// bh = page #
		// RETURNS: ch = cursor start scan line
		//          cl = cursor end scan line
		//          dh = row
		//          dl = column

		if(*bh > 7) {
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] GetCursorPos(): too high a page (" +
				Piston::String::Render(*bh) + L")");
			ZSSERT(0);
			return;
		}

		*ch = 8; // TODO
		*cl = 10;
		*dh = plug_dev->MemRead16(0x450 + *bh * 4);
		*dl = plug_dev->MemRead16(0x452 + *bh * 4);
	}

	void ScrollUp(int8 rowStart, int8 colStart, int8 rowEnd, int8 colEnd, int8 numLines, int8 attr) {
		int32 ptr = 0xb8000 + plug_dev->MemRead8(0x462) * plug_dev->MemRead16(0x44c);
		int16 cols = plug_dev->MemRead16(0x44a);
		int16 rows = plug_dev->MemRead8(0x484) + 1;

		if(colEnd >= cols || rowEnd >= rows || colStart > colEnd || rowStart > rowEnd) {
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] Bad input to ScrollUp()");
			ZSSERT(0);
			return;
		}

		if(!numLines) {
			for(int r = rowStart; r <= rowEnd; ++r)
				for(int c = colStart; c <= colEnd; ++c)
					plug_dev->MemWrite16(ptr + (r * cols + c) * 2, attr);
			return;
		}

		for(int i = 0; i < numLines; ++i) {
			for(int row = rowStart; row < rowEnd; ++row) // scroll lines up
				for(int col = colStart; col <= colEnd; ++col)
					plug_dev->MemWrite16(ptr + (row * cols + col) * 2,
						plug_dev->MemRead16(ptr + ((row + 1) * cols + col) * 2));
			for(int col = colStart; col <= colEnd; ++col) // fill last line
				plug_dev->MemWrite16(ptr + (rowEnd * cols + col) * 2, attr << 8);
		}
	}

	void ScrollUp() {
		// al = # of lines by which to move
		// bh = attribute for blank lines
		// ch,cl = row,col of upper left window corner
		// dh,dl = row,col of lower right window corner
		ScrollUp(*ch, *cl, *dh, *dl, *al, *bh);
	}

	void ScrollDown(int8 rowStart, int8 colStart, int8 rowEnd, int8 colEnd, int8 numLines, int8 attr) {
		int32 ptr = 0xb8000 + plug_dev->MemRead8(0x462) * plug_dev->MemRead16(0x44c);
		int16 cols = plug_dev->MemRead16(0x44a);
		int16 rows = plug_dev->MemRead8(0x484) + 1;

		if(colEnd >= cols || rowEnd >= rows || colStart > colEnd || rowStart > rowEnd) {
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] Bad input to ScrollDown()");
			ZSSERT(0);
			return;
		}

		if(!numLines) {
			for(int r = rowStart; r <= rowEnd; ++r)
				for(int c = colStart; c <= colEnd; ++c)
					plug_dev->MemWrite16(ptr + (r * cols + c) * 2, attr);
			return;
		}

		for(int i = 0; i < numLines; ++i) {
			for(int row = rowEnd; row > rowStart; ++row) // scroll lines up
				for(int col = colStart; col <= colEnd; ++col)
					plug_dev->MemWrite16(ptr + (row * cols + col) * 2,
						plug_dev->MemRead16(ptr + ((row - 1) * cols + col) * 2));
			for(int col = colStart; col <= colEnd; ++col) // fill last line
				plug_dev->MemWrite16(ptr + (rowStart * cols + col) * 2, attr << 8);
		}
	}

	void ScrollDown() {
		// al = # of lines by which to move
		// bh = attribute for blank lines
		// ch,cl = row,col of upper left window corner
		// dh,dl = row,col of lower right window corner
		ScrollDown(*ch, *cl, *dh, *dl, *al, *bh);
	}

	void SwitchPage() {
		if(*al > 7) {
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] SwitchPage(" +
				Piston::String::Render(*al) + L"): page too high");
			ZSSERT(0);
			return;
		}

		plug->Log(plug_persist, LOG_DEBUG, L"[VIDEO] SwitchPage(" + Piston::String::Render(*al) + L")");
		plug_dev->MemWrite8(0x462, *al);
	}

	void SetBgColor() {}

	void ReadCharAttrHere() {
		// bh = page
		// RETURNS: ah = attr
		//          al = character

		if(*bh > 7) { // too high of a page
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] ReadCharAttrHere(): too high a page # (" +
				Piston::String::Render(*bh));
			ZSSERT(false);
			*flags |= flags_mask_cf;
			return;
		}

		int16 cols = plug_dev->MemRead16(0x44a);
		int32 ptr = 0xb8000 + *bh * plug_dev->MemRead16(0x44c) +
			(plug_dev->MemRead16(0x450 + *bh * 4) * cols + plug_dev->MemRead16(0x452 + *bh * 4)) * 2;

		*ax = plug_dev->MemRead16(ptr);
	}

	void WriteCharAttrHere() {
		// al = character
		// bh = page
		// bl = attr
		// cx = count

		if(*bh > 7) { // too high of a page
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] WriteCharAttrHere(): too high a page # (" +
				Piston::String::Render(*bh));
			ZSSERT(false);
			*flags |= flags_mask_cf;
			return;
		}

		if(*cx > 2000) {
			plug->Log(plug_persist, LOG_WARNING, L"[VIDEO] Likely bad input to WriteCharAttrHere()");
			ZSSERT(0);
			return;
		}

		int16 cols = plug_dev->MemRead16(0x44a);
		int32 ptr = 0xb8000 + *bh * plug_dev->MemRead16(0x44c) +
			(plug_dev->MemRead16(0x450 + *bh * 4) * cols + plug_dev->MemRead16(0x452 + *bh * 4)) * 2;

		for(int i = 0; i < *cx; ++i)
			plug_dev->MemWrite16(ptr + i * 2, (*bl << 8) | *al);
	}

	void WriteCharHere() {
		// al = character
		// bh = page
		// bl = color (gfx mode), character XOR'd onto screen if bit 7 set
		// cx = number of times to write char

		if(*bh > 7) { // too high of a page
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] WriteCharHere(): too high a page # (" +
				Piston::String::Render(*bh));
			ZSSERT(false);
			*flags |= flags_mask_cf;
			return;
		}

		if(*cx > 2000) {
			plug->Log(plug_persist, LOG_WARNING, L"[VIDEO] Likely bad input to WriteCharHere()");
			ZSSERT(0);
			return;
		}

		int16 cols = plug_dev->MemRead16(0x44a);
		int32 ptr = 0xb8000 + *bh * plug_dev->MemRead16(0x44c) +
			(plug_dev->MemRead16(0x450 + *bh * 4) * cols + plug_dev->MemRead16(0x452 + *bh * 4)) * 2;

		for(int i = 0; i < *cx; ++i)
			plug_dev->MemWrite8(ptr + i * 2, *al);
	}

	void Teletype() {
		// al = character
		// bh = page
		// bl = foreground color (graphics modes only)

		if(*bh > 7) { // too high of a page
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] Teletype: too high a page # (" +
				Piston::String::Render(*bh));
			ZSSERT(false);
			*flags |= flags_mask_cf;
			return;
		}

		int16 row = plug_dev->MemRead16(0x450 + *bh * 4);
		int16 col = plug_dev->MemRead16(0x452 + *bh * 4);
		int16 cols = plug_dev->MemRead16(0x44a);
		int16 rows = plug_dev->MemRead8(0x484) + 1;
		if(*al == 0xd) { // cr
			col = 0;
		} else if(*al == 0xa) { // lf
			++row;
		} else if(*al == 0x8) { // bs
			if(col == 0) {
				col = cols - 1;
				if(row > 0)
					--row;
			} else
				--col;
		} else {
			plug_dev->MemWrite16(0xb8000 + *bh * plug_dev->MemRead16(0x44c) +
				(row * cols + col) * 2, 0x700 | *al);
			++col;
		}

		if(col >= cols) {
			col = 0;
			++row;
		}

		if(row >= rows) {
			ScrollUp(0, 0, rows - 1, cols - 1, row - rows + 1, 0);
			row = rows - 1;
		}

		plug_dev->MemWrite16(0x450 + *bh * 4, row);
		plug_dev->MemWrite16(0x452 + *bh * 4, col);
	}

	void GetMode() {
		// RETURNS: ah = character columns
		//          al = display mode
		//          bl = active page
		*al = plug_dev->MemRead8(0x449);
		*ah = plug_dev->MemRead16(0x44a);
		*bh = plug_dev->MemRead8(0x462);
	}

	void SetPaletteReg() {
		//ZSSERT(0);
	}

	void SetAllPaletteRegs() {
		//ZSSERT(0);
	}

	void GetDisplayInfo() {
		// ah = 0x12, bl = 0x10
		// RETURNS: bh = 00 if color, 01 if mono
		//			bl = video ram, 0-3 (bl + 1)*64K
		//			ch = feature connector bits -- wtf?
		//			cl = switch settings -- wtf?
		*bx = 0x0003;
		*cx = 0x0209;
	}

	void GetDisplay() {
		// RETURNS: al = 0x1a
		//			bl = active display code
		//			bh = alternate display code
		//
		// 0x00 = no display
		// ...
		// 0x08 = vga + color display
		*ax = 0x1a;
		*bx = 0x08;
	}

	void int_10() {
		switch(*ah) {
		case 0x00: SetMode(); break;
		case 0x01: SetCursorShape(); break;
		case 0x02: SetCursorPos(); break;
		case 0x03: GetCursorPos(); break;
		case 0x05: SwitchPage(); break;
		case 0x06: ScrollUp(); break;
		case 0x07: ScrollDown(); break;
		case 0x08: ReadCharAttrHere(); break;
		case 0x09: WriteCharAttrHere(); break;
		case 0x0a: WriteCharHere(); break;
		case 0x0b:
			switch(*bh) {
			case 0x00: SetBgColor(); break;
			default:
				plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] int 0x10, ah=0x0b: Undefined parameter in bh: 0x" +
					Piston::String::Renderhex(*bh).PadLeft(2, L'0') + L".");
				//ZSSERT(0);
			} break;
		case 0x0e: Teletype(); break;
		case 0x0f: GetMode(); break;
		case 0x10:
			switch(*al) {
			case 0x00: SetPaletteReg(); break;
			case 0x01: break; // set border (overscan) color
			case 0x02: SetAllPaletteRegs(); break;
			case 0x03: break; // toggle intensity/blinking
			case 0x10: break;            // set individual dac register
			default:
				plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] int 0x10, ah=0x10: Undefined parameter in al: 0x" +
					Piston::String::Renderhex(*al).PadLeft(2, L'0') + L".");
				//ZSSERT(0);
			} break;
		case 0x11:
			break; // load font
		case 0x12:
			switch(*bl) {
			case 0x10: GetDisplayInfo(); break;
			default:
				plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] int 0x10, ah=0x12: Undefined parameter in bl: 0x" +
					Piston::String::Renderhex(*bl).PadLeft(2, L'0') + L".");
				//ZSSERT(0);
			} break;
		case 0x1a:
			switch(*al) {
			case 0x00: GetDisplay(); break;
			default:
				plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] int 0x10, ah=0x1a: Undefined parameter in al: 0x" +
					Piston::String::Renderhex(*al).PadLeft(2, L'0') + L".");
				//ZSSERT(0);
			} break;
		case 0x5f: // this is all third party junk
		case 0x6f:
			break;
		default:
			plug->Log(plug_persist, LOG_ERROR, L"[VIDEO] Undefined parameter in ah: 0x" +
				Piston::String::Renderhex(*ah).PadLeft(2, L'0') + L".");
			//ZSSERT(0);
		}
	}
}}