#include "stdafx.h"

#include "adapter.h"

namespace Tower { namespace Vga {
	static const Piston::Win32::COLORREF colorz[16] = {
		0x000000, 0x800000, 0x008000, 0x808000, 0x000080, 0x800080, 0x008080, 0xc0c0c0,
		0x808080, 0xff0000, 0x00ff00, 0xffff00, 0x0000ff, 0xff00ff, 0x00ffff, 0xffffff
	};

	void TextModeDraw(int8 mode, Piston::Win32::HDC hDC) {
		int screenCX, screenCY, charCX, charCY;
		int8 *ptr;

		switch(mode) {
		case 0x03: screenCX = 80; screenCY = 25; charCX = 9; charCY = 16; ptr = Adapter::vram + 0x0000; break;
		default: ZSSERT(false); return;
		}

		ptr += plug_vid->MemRead8(0x462) * plug_vid->MemRead16(0x44c); // page offset

		//Piston::Win32::HGDIOBJ oldbrush = Piston::Win32::SelectObject(hDC, Piston::Win32::GetStockObject(Piston::Win32::STOCK_BLACK_BRUSH));
		//Piston::Win32::HGDIOBJ oldpen = Piston::Win32::SelectObject(hDC, Piston::Win32::GetStockObject(Piston::Win32::STOCK_NULL_PEN));
		//Piston::Win32::Rectangle(hDC, 0, 0, screenCX * charCX, screenCY * charCY);

		for(int y = 0; y < screenCY; y++)
		for(int x = 0; x < screenCX; x++) {
			unsigned int curChar = *ptr;
			Piston::Win32::SetBkColor(hDC, colorz[*(ptr + 1) >> 4]);
			Piston::Win32::SetTextColor(hDC, colorz[*(ptr + 1) & 0xf]);
			Piston::Win32::RECT rc = {x * charCX, y * charCY, (x + 1) * charCX, (y + 1) * charCY};
			Piston::Win32::ExtTextOut(hDC, x * charCX, y * charCY,
				Piston::Win32::ETO_OPAQUE, &rc, (const wchar_t *)&curChar, 1, 0);
			ptr += 2;
		}

		//Piston::Win32::SelectObject(hDC, oldbrush);
		//Piston::Win32::SelectObject(hDC, oldpen);
	}

	void GfxModeDraw(int8 mode, Piston::Win32::HDC hDC) {
		int screenCX, screenCY, bits;
		int8 *ptr = Adapter::vram;

		switch(mode) {
		case 0x06:
			// even scanlines
			ptr = Adapter::vram + 0x8000;
			for(int y = 0; y < 200; y += 2)
				for(int x = 0; x < 640; x += 8) {
					for(int b = 0; b < 8; ++b) {
						Piston::Win32::SetPixel(hDC, x + b, y, (*ptr & (1 << (7 - b))) ? 0x8080ff : 0);
					}
					++ptr;
				}

			// odd scanlines
			ptr = Adapter::vram + 0xa000;
			for(int y = 1; y < 200; y += 2)
				for(int x = 0; x < 640; x += 8) {
					for(int b = 0; b < 8; ++b) {
						Piston::Win32::SetPixel(hDC, x + b, y, (*ptr & (1 << (7 - b))) ? 0x8080ff : 0);
					}
					++ptr;
				}
			break;
		case 0x10:
			for(int y = 0; y < 350; ++y)
				for(int x = 0; x < 640; x += 8) {
					for(int b = 0; b < 8; ++b)
						if(!(b % 2) && !(y % 2))
						Piston::Win32::SetPixel(hDC, x + b, y, colorz[
							((*ptr             & (1 << (7 - b))) ? 1 : 0) |
							((*(ptr + 0x10000) & (1 << (7 - b))) ? 2 : 0) |
							((*(ptr + 0x20000) & (1 << (7 - b))) ? 4 : 0) |
							((*(ptr + 0x30000) & (1 << (7 - b))) ? 8 : 0)
						]);
					++ptr;
				}
			break;
		case 0x12:
			for(int y = 0; y < 480; ++y)
				for(int x = 0; x < 640; x += 8) {
					for(int b = 0; b < 8; ++b)
						//if((b % 2) && (y % 2))
						Piston::Win32::SetPixel(hDC, x + b, y, colorz[
							((*ptr             & (1 << (7 - b))) ? 1 : 0) |
							((*(ptr + 0x10000) & (1 << (7 - b))) ? 2 : 0) |
							((*(ptr + 0x20000) & (1 << (7 - b))) ? 4 : 0) |
							((*(ptr + 0x30000) & (1 << (7 - b))) ? 8 : 0)
						]);
					++ptr;
				}
			break;
		case 0x13:
			for(int y = 0; y < 200; ++y)
				for(int x = 0; x < 320; ++x) {
					Piston::Win32::SetPixel(hDC, x, y, colorz[*ptr & 15]);
					//Piston::Win32::SetPixel(hDC, x, y, Adapter::Dac[*ptr * 3] * 4 + (Adapter::Dac[*ptr * 3 + 1] << 8) * 4 + (Adapter::Dac[*ptr * 3 + 2] << 16) * 4);
					++ptr;
				}
			//for(int y = 0; y < 480; ++y)
			//	for(int x = 0; x < 360; x += 4) {
			//		//for(int b = 0; b < 4; ++b) {
			//		//	Piston::Win32::SetPixel(hDC, x + b, y, colorz[
			//		//		((*(ptr + 0x30000) & (1 << (7 - b))) ? 1 : 0) |
			//		//		((*(ptr + 0x30000) & (1 << (6 - b))) ? 2 : 0) |
			//		//		((*(ptr + 0x20000) & (1 << (7 - b))) ? 4 : 0) |
			//		//		((*(ptr + 0x20000) & (1 << (6 - b))) ? 8 : 0)
			//		//	]);
			//		//}
			//		for(int b = 0; b < 4; ++b)
			//			Piston::Win32::SetPixel(hDC, x + b, y, colorz[
			//				*(ptr + (b << 16))
			//			& 0xf]);
			//		++ptr;
			//	}
			break;
		case 0x5f:
			for(int y = 0; y < 480; ++y)
				for(int x = 0; x < 640; x += 2) {
					Piston::Win32::SetPixel(hDC, x, y, colorz[*ptr & 15]);
					++ptr;
				}
			break;
		default: ZSSERT(0);
		}

		return;
def_hanld:
		switch(mode) {
		case 0x06: screenCX = 640; screenCY = 200; bits = 1; ptr = Adapter::vram + 0x18000; break;
		case 0x12: screenCX = 640; screenCY = 480; bits = 4; ptr = Adapter::vram; break;
		//case 0x12: screenCX = 640; screenCY = 480; bits = 1; ptr = Adapter::vram; break;
		//case 0x13: screenCX = 320; screenCY = 200; bits = 8; ptr = Adapter::vram; break;
		case 0x13: screenCX = 360; screenCY = 480; bits = 2; ptr = Adapter::vram; break;
		default: ZSSERT(0); break;
		}

		// scorch def screen is 180 bytes across! (4bpp???????)

		switch(bits) {
		case 1: // 1bpp
			for(int y = 0; y < screenCY; ++y)
				for(int x = 0; x < screenCX; x += 8) {
					Piston::Win32::SetPixel(hDC, x,     y, *ptr & 0x80 ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 1, y, *ptr & 0x40 ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 2, y, *ptr & 0x20 ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 3, y, *ptr & 0x10 ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 4, y, *ptr & 0x8  ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 5, y, *ptr & 0x4  ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 6, y, *ptr & 0x2  ? 0x8080ff : 0);
					Piston::Win32::SetPixel(hDC, x + 7, y, *ptr & 0x1  ? 0x8080ff : 0);
					++ptr;
				}
			break;
		case 2:
			for(int y = 0; y < screenCY; ++y)
				for(int x = 0; x < screenCX; x += 4) {
					Piston::Win32::SetPixel(hDC, x,     y, colorz[(*ptr & 0xc0) >> 6]);
					Piston::Win32::SetPixel(hDC, x + 1, y, colorz[(*ptr & 0x30) >> 4]);
					Piston::Win32::SetPixel(hDC, x + 2, y, colorz[(*ptr & 0x0c) >> 2]);
					Piston::Win32::SetPixel(hDC, x + 3, y, colorz[ *ptr & 0x03      ]);
					++ptr;
				}
			break;
		case 4: // 4bpp
			//for(int y = 0; y < screenCY; ++y)
			//	for(int x = 0; x < screenCX; x += 2) {
			//		Piston::Win32::SetPixel(hDC, x,     y, colorz[(*ptr & 0xf0) >> 4]);
			//		Piston::Win32::SetPixel(hDC, x + 1, y, colorz[ *ptr & 0x0f      ]);
			//		++ptr;
			//	}
			//break;
			for(int y = 0; y < screenCY; ++y)
				for(int x = 0; x < screenCX; x += 8) {
					for(int b = 0; b < 8; ++b)
						Piston::Win32::SetPixel(hDC, x + b, y, colorz[
							((*ptr             & (1 << (7 - b))) >> (7 - b)) |
							((*(ptr + 0x10000) & (1 << (7 - b))) >> (6 - b)) |
							((*(ptr + 0x20000) & (1 << (7 - b))) >> (5 - b)) |
							((*(ptr + 0x30000) & (1 << (7 - b))) >> (4 - b))]);
						//Piston::Win32::SetPixel(hDC, x + b, y, Adapter::Dac[
						//	((*ptr             & (1 << (7 - b))) >> (7 - b)) |
						//	((*(ptr + 0x10000) & (1 << (7 - b))) >> (6 - b)) |
						//	((*(ptr + 0x20000) & (1 << (7 - b))) >> (5 - b)) |
						//	((*(ptr + 0x30000) & (1 << (7 - b))) >> (4 - b))]);
					//Piston::Win32::SetPixel(hDC, x,     y, colorz[(*ptr & 0xf0) >> 4]);
					//Piston::Win32::SetPixel(hDC, x + 1, y, colorz[ *ptr & 0x0f      ]);
					++ptr;
				}
			break;
		case 8:
			for(int y = 0; y < screenCY; ++y)
				for(int x = 0; x < screenCX; ++x) {
					//Piston::Win32::SetPixel(hDC, x, y, (Adapter::Dac[*ptr * 3] + (Adapter::Dac[*ptr * 3 + 1] << 8) + (Adapter::Dac[*ptr * 3 + 2] << 16)) * 0x40404);
					Piston::Win32::SetPixel(hDC, x, y, colorz[*ptr & 15]);
					++ptr;
				}
			break;
		default: ZSSERT(false);
		}
	}














	int32 Adapter::cx, Adapter::cy;
	int8 Adapter::charCX, Adapter::charCY;

	inline Piston::Win32::COLORREF Adapter::DecodeDac(int8 index) {
		return (Dac[3*index] | (Dac[3*index+1] << 8) | (Dac[3*index+2] << 16)) * 0x40404;
	}

	void Adapter::PreDraw() {
		unsigned int w, h;

		w = Sequencer[1] & 1 ? 640 : 720;
		if(Sequencer[1] & (1 << 3) || GfxReg[5] & (1 << 6)) // half dot clock
			w >>= 1;

		h = 1 + CrtcReg[6] | (CrtcReg[7] & 1 ? 0x100 : 0) | (CrtcReg[7] & 0x20 ? 0x200 : 0);
		if(GfxReg[5] & (1 << 6))
			h = 200;

		if((cx != w) || (cy != h)) {
			cx = w;
			cy = h;
			plug_vid->ResizeScreen(plug_persist, w, h);
		}

		charCX = Sequencer[1] & 1 ? 8 : 9;
		charCY = (CrtcReg[9] & 0x1f) + 3;
		if(CrtcReg[9] & 0x80) // temp: should double each scanline if true
			charCY <<= 1;
	}

	void Adapter::RedrawAll(Piston::Win32::HDC hDC) {
		PreDraw();

		if(!(GfxReg[6] & 1)) { // text mode
			for(unsigned int y = 0; y < cy / charCX; ++y) {
				int8 *ptr = vram + CrtcReg[0x0d] + (CrtcReg[0x0c] << 16) + (y * CrtcReg[0x13] << 2);
				for(unsigned int x = 0; x <= CrtcReg[0x01]; ++x) {
					Piston::Win32::RECT rc = {x * charCX, y * charCY, (x + 1) * charCX, (y + 1) * charCY};
					if(x > CrtcReg[1]) { // overscan
						Piston::Win32::SetBkColor(hDC, DecodeDac(AttributeReg[0x11]));
						Piston::Win32::ExtTextOut(hDC, rc.left, rc.top,
							Piston::Win32::ETO_OPAQUE, &rc, L'\0', 1, 0);
						continue;
					} else if(x >= CrtcReg[2]) { // blank
						Piston::Win32::SetBkColor(hDC, 0);
						Piston::Win32::ExtTextOut(hDC, rc.left, rc.top,
							Piston::Win32::ETO_OPAQUE, &rc, L'\0', 1, 0);
					} else { // output char
						Piston::Win32::SetBkColor(hDC, colorz[*(ptr + 1) >> 4]);
						Piston::Win32::SetTextColor(hDC, colorz[*(ptr + 1) & 15]);
						//Piston::Win32::SetBkColor(hDC, DecodeDac(AttributeReg[*(ptr + 1) >> 4]));
						//Piston::Win32::SetTextColor(hDC, DecodeDac(AttributeReg[*(ptr + 1) & 15]));

						unsigned int curChar = *ptr;
						Piston::Win32::ExtTextOut(hDC, rc.left, rc.top,
							Piston::Win32::ETO_OPAQUE, &rc, (const wchar_t *)&curChar, 1, 0);
					}
					ptr += 2;
				}
			}
		} else { // graphics mode
			if(GfxReg[5] & 0x40) { // shift256
				int8 *ptr = vram + CrtcReg[0x0d] + (CrtcReg[0x0c] << 16) ;//+ (y * CrtcReg[0x13] << 3);
				for(unsigned int y = 0; y < cy; ++y) {
					for(unsigned int x = 0; x < cx; ++x) {
						Piston::Win32::SetPixel(hDC, x, y, colorz[*ptr & 15] /*DecodeDac(*ptr)*/);
						++ptr;
					}
				}
			} else if(GfxReg[5] & 0x20) { // shift reg
				ZSSERT(0);
			} else { // 16-color planar
				for(unsigned int y = 0; y < cy; ++y) {
					int8 *ptr = vram + CrtcReg[0x0d] + (CrtcReg[0x0c] << 16) + (y * CrtcReg[0x13] << 1);
					for(unsigned int x = 0; x < cx; x += 8) {
						for(unsigned int b = 0; b < 8; ++b) {
							Piston::Win32::SetPixel(hDC, x + b, y, (colorz[ //DecodeDac(AttributeReg[
								((*ptr             & (1 << (7 - b))) ? 1 : 0) |
								((*(ptr + 0x10000) & (1 << (7 - b))) ? 2 : 0) |
								((*(ptr + 0x20000) & (1 << (7 - b))) ? 4 : 0) |
								((*(ptr + 0x30000) & (1 << (7 - b))) ? 8 : 0)
							]));
						}
						++ptr;
					}
				}
			}
		}
	}
}}