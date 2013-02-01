#pragma once
#include "stdafx.h"

#include "Piston\Win32\gdi.h"

namespace Tower { namespace Vga {
	class Adapter {
		friend void GfxModeDraw(int8 mode, Piston::Win32::HDC hDC);
		friend void TextModeDraw(int8 mode, Piston::Win32::HDC hDC);
	private:
		Adapter();
		Adapter(const Adapter &copy);
		Adapter &operator=(const Adapter &copy);

		static int8 *vram;
		static int8 LatchReg[4];
		static int8 vsyncp;
		static int8 hsyncp;
		static int8 odd_even_page;
		static int8 clock_select;
		static int8 host_ram_enable;
		static int8 io_addr_color;
		static int8 AttributeReg[0x15];
		static int8 AttributeIndex;
		static int8 AttributeIndexWritten;
		static int8 Sequencer[5];
		static int8 SequencerIndex;
		static int8 GfxReg[9];
		static int8 GfxRegIndex;
		static int8 CrtcReg[0x19];
		static int8 CrtcRegIndex;
		static int8 Dac[256 * 3];
		static int8 DacReadIndex;
		static int8 DacWriteIndex;

		static int32 cx, cy;
		static int8 charCX, charCY;

		static inline int32 MemAddrDecode(int32 host_addr);

		static inline Piston::Win32::COLORREF DecodeDac(int8 index);
		static void PreDraw();
		static void DrawTile(Piston::Win32::HDC hDC, int tileX, int tileY);

	public:

		static void Init() {
			ZSSERT(!vram);
			vram = new int8[0x40000];

			Sequencer[2] = 0xf; // enable write all planes
			GfxReg[8] = 0xff;
		}

		static void Uninit() {
			if(vram) {
				delete vram;
				vram = 0;
			}
		}

		static int8 PortRead8(int16 port);
		static int16 PortRead16(int16 port);
		static int32 PortRead32(int16 port);
		static void PortWrite8(int16 port, int8 value);
		static void PortWrite16(int16 port, int16 value);
		static void PortWrite32(int16 port, int32 value);

		static int8 TOWER_CC MemRead8(int32 addr);
		static int16 TOWER_CC MemRead16(int32 addr);
		static int32 TOWER_CC MemRead32(int32 addr);
		static void TOWER_CC MemWrite8(int32 addr, int8 data);
		static void TOWER_CC MemWrite16(int32 addr, int16 data);
		static void TOWER_CC MemWrite32(int32 addr, int32 data);

		static void Update(Piston::Win32::HDC hDC);
		static void RedrawAll(Piston::Win32::HDC hDC);
	};
}}