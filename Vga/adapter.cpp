#include "stdafx.h"
#include "adapter.h"

#include "Piston\String.h"

#define PLUG_TRACE(x) plug->Log(plug_persist, LOG_TRACE, x)
//#define PLUG_TRACE(x)

#define PLUG_DEBUG(x) plug->Log(plug_persist, LOG_DEBUG, x)
//#define PLUG_DEBUG(x)

#define PLUG_INFO(x) plug->Log(plug_persist, LOG_INFO, x)
#define PLUG_WARNING(x) plug->Log(plug_persist, LOG_WARNING, x)

namespace Tower { namespace Vga {
	int8 *Adapter::vram;
	int8 Adapter::LatchReg[4];

	int8 Adapter::vsyncp;
	int8 Adapter::hsyncp;
	int8 Adapter::odd_even_page;
	int8 Adapter::clock_select;
	int8 Adapter::host_ram_enable;
	int8 Adapter::io_addr_color;

	int8 Adapter::AttributeReg[0x15];
	int8 Adapter::AttributeIndex;
	int8 Adapter::AttributeIndexWritten;
	int8 Adapter::Sequencer[5];
	int8 Adapter::SequencerIndex;
	int8 Adapter::GfxReg[9];
	int8 Adapter::GfxRegIndex;
	int8 Adapter::CrtcReg[0x19];
	int8 Adapter::CrtcRegIndex;
	int8 Adapter::Dac[256 * 3];
	int8 Adapter::DacReadIndex;
	int8 Adapter::DacWriteIndex;

	inline int8 rotateright(int8 num, int8 count) {
		return ((num & (0xff << count)) >> count) |
			((num & (0xff >> (8 - count))) << (8 - count));
	}

	int8 Adapter::PortRead8(int16 port) {
		const int8 undefined = 0xff;
		//PLUG_TRACE(L"8-bit read from port 0x" + Piston::String::Renderhex(port).PadLeft(4, L'0'));

		switch(port) {
		case 0x3c0: // attribute index
			ZSSERT(0);
			return AttributeIndex;
		case 0x3c1: // attribute data
			if(AttributeIndex < sizeof(AttributeReg))
				return AttributeReg[AttributeIndex];
			else
				return undefined;
		case 0x3c4: // sequencer index
			return SequencerIndex;
		case 0x3c5: // sequencer data
			if(SequencerIndex < sizeof(Sequencer))
				return Sequencer[SequencerIndex];
			else
				return undefined;
		case 0x3cc: // misc output reg
			return io_addr_color | (host_ram_enable << 1) | (clock_select << 2) |
				(odd_even_page << 5) | (hsyncp << 6) | (vsyncp << 7);
		case 0x3cd:
			PLUG_WARNING(L"unknown read from port 0x3cd");
			return 0xff; // no idea
		case 0x3cf:
			if(GfxRegIndex < sizeof(GfxReg))
				return GfxReg[GfxRegIndex];
			else
				return undefined;
		case 0x3b5:
		case 0x3d5: // crtc register
			if(CrtcRegIndex <= sizeof(CrtcReg))
				return CrtcReg[CrtcRegIndex];
			else
				return undefined;
		case 0x3da: { // input status reg
			static int tmp;
			tmp = (tmp + 1) & 1; // major hackage
			return tmp * 9;
		}
		case 0x3de: // ???
			PLUG_WARNING(L"Unknown read from port 0x03de");
			ZSSERT(0);
			return 0xff;
		default: ZSSERT(0);
		}
	}

	int16 Adapter::PortRead16(int16 port) {
		if(port != 0x3c4) ZSSERT(0);
		return PortRead8(port) + (PortRead8(port + 1) << 8);
	}

	int32 Adapter::PortRead32(int16 port) {
		ZSSERT(0);
		return PortRead8(port) + (PortRead8(port + 1) << 8) + (PortRead8(port + 2) << 16) + (PortRead8(port + 3) << 24);
	}

	void Adapter::PortWrite8(int16 port, int8 value) {
		switch(port) {
		case 0x3c0: // attribute index
			if(!AttributeIndexWritten) {
				if(value >= sizeof(AttributeReg)) //if(AttributeIndex < sizeof(AttributeReg)
					PLUG_WARNING(L"Attribute index set to 0x" +
						Piston::String::Renderhex(value).PadLeft(2, L'0') + L", max is 0x14, ignored.");
				AttributeIndex = value;
				AttributeIndexWritten = 1;
			} else {
				PLUG_TRACE(L"attr[0x" + Piston::String::Renderhex(AttributeIndex).PadLeft(2, L'0') +
					L"] = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
				if(AttributeIndex < sizeof(AttributeReg))
					AttributeReg[AttributeIndex] = value;
				AttributeIndexWritten = 0;
			}
			break;
		case 0x3c1: // attribute data read
			ZSSERT(0);
			break;
		case 0x3c2: // misc output reg
			io_addr_color = value & 1;
			host_ram_enable = (value & 2) ? 1 : 0;
			clock_select = (value & 12) >> 2;
			ZSSERT(clock_select <= 1);
			ZSSERT(!(value & 16));
			odd_even_page = (value & 0x20) ? 1 : 0;
			hsyncp = (value & 0x40) ? 1 : 0;
			vsyncp = (value & 0x80) ? 1 : 0;

			PLUG_TRACE(L"misc_out = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			break;
		case 0x3c4: // sequencer index
			if(value >= sizeof(Sequencer)) //if(SequencerIndex < sizeof(Sequencer))
				PLUG_WARNING(L"Sequencer index set to 0x" +
					Piston::String::Renderhex(value).PadLeft(2, L'0') + L", max is 0x04, ignored.");
			SequencerIndex = value;
			break;
		case 0x3c5: // sequencer data
			if(SequencerIndex != 2)
				PLUG_TRACE(L"seq[0x" + Piston::String::Renderhex(SequencerIndex).PadLeft(2, L'0') +
					L"] = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			if(SequencerIndex < sizeof(Sequencer))
				Sequencer[SequencerIndex] = value;
			break;
		case 0x3c6: // ???
			PLUG_INFO(L"unhandled write(0x03c6) = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			break;
		case 0x3c7: // dac read index
			DacReadIndex = value * 3;
			break;
		case 0x3c8: // dac write index
			DacWriteIndex = value * 3;
			break;
		case 0x3c9:
			if(value)
			Dac[DacWriteIndex++] = value;
			if(DacWriteIndex > sizeof(Dac)) DacWriteIndex = 0;
			break;
		case 0x3cd: // ???
			PLUG_INFO(L"unhandled write(0x03cd) = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			break;
		case 0x3ce: // gfx controller index
			if(value >= sizeof(GfxReg)) //if(GfxRegIndex < sizeof(GfxReg))
				PLUG_WARNING(L"Gfx controller index set to 0x" +
					Piston::String::Renderhex(value).PadLeft(2, L'0') + L", max is 0x08, ignored.");
			GfxRegIndex = value;
			break;
		case 0x3cf: // gfx controller data
			if(GfxRegIndex != 8)
				PLUG_TRACE(L"gfx_ctrl[0x" + Piston::String::Renderhex(GfxRegIndex).PadLeft(2, L'0') +
					L"] = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			if(GfxRegIndex < sizeof(GfxReg))
				GfxReg[GfxRegIndex] = value;
			break;
		case 0x3b4:
		case 0x3d4: // crtc index
			if(value >= sizeof(CrtcReg)) //if(CrtcRegIndex < sizeof(CrtcReg))
				PLUG_WARNING(L"CRTC index set to 0x" +
					Piston::String::Renderhex(value).PadLeft(2, L'0') + L", max is 0x18, ignored.");
			CrtcRegIndex = value;
			break;
		case 0x3b5:
		case 0x3d5: // crtc data
			if(CrtcRegIndex != 14 && CrtcRegIndex != 15)
				PLUG_TRACE(L"crtc[0x" + Piston::String::Renderhex(CrtcRegIndex).PadLeft(2, L'0') +
					L"] = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			if(CrtcRegIndex < sizeof(CrtcReg))
				CrtcReg[CrtcRegIndex] = value;
			break;
		case 0x3de: // ???
			PLUG_INFO(L"write(0x03de) = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			break;
		default:
			PLUG_WARNING(L"unhandled write(0x" + Piston::String::Renderhex(port).PadLeft(4, L'0') +
				L" = 0x" + Piston::String::Renderhex(value).PadLeft(2, L'0'));
			ZSSERT(0);
		}
	}

	void Adapter::PortWrite16(int16 port, int16 value) {
		if(port != 0x3ce && port != 0x3c4 && port != 0x3d4) ZSSERT(0);
		PortWrite8(port, value & 0xff);
		PortWrite8(port + 1, value >> 8);
	}

	void Adapter::PortWrite32(int16 port, int32 value) {
		ZSSERT(0);
		PortWrite8(port, (int8)value);
		PortWrite8(port + 1, (int8)(value >> 8));
		PortWrite8(port + 2, (int8)(value >> 16));
		PortWrite8(port + 3, (int8)(value >> 24));
	}

	inline int32 Adapter::MemAddrDecode(int32 host_addr) {
		ZSSERT(host_addr >= 0xa0000);
		ZSSERT(host_addr <= 0xbffff);
		switch(GfxReg[6] & 0xc) {
		case 0x0: return host_addr & 0x1ffff;
		case 0x4: if(host_addr & (1 << 16)) return (int32)-1; return host_addr & 0xffff;
		case 0x8: if((host_addr & 0x18000) != 0x10000) return (int32)-1; return host_addr & 0x7fff;
		default : if((host_addr & 0x18000) != 0x18000) return (int32)-1; return host_addr & 0x7fff;
		}
	}

	int8 TOWER_CC Adapter::MemRead8(int32 addr) {
		addr = MemAddrDecode(addr);
		if(addr == (int32)-1) return 0xff;

		LatchReg[0] = *(int8 *)(vram + addr);
		LatchReg[1] = *(int8 *)(vram + (1 << 16) + addr);
		LatchReg[2] = *(int8 *)(vram + (2 << 16) + addr);
		LatchReg[3] = *(int8 *)(vram + (3 << 16) + addr);

		if(GfxReg[5] & 0x8) { // read mode 1
			ZSSERT(0);
			for(int p = 0; p < 4; ++p) {
				if(GfxReg[7] & (1 << p)) // color don't care
					continue;
			}
			return LatchReg[GfxReg[4] & 3]; // return what now??
		} else
			return LatchReg[GfxReg[4] & 3]; // read map select reg
	}

	int16 TOWER_CC Adapter::MemRead16(int32 addr) {
		return MemRead8(addr) + (MemRead8(addr + 1) << 8);
	}

	int32 TOWER_CC Adapter::MemRead32(int32 addr) {
		return MemRead8(addr) + (MemRead8(addr + 1) << 8) + (MemRead8(addr + 2) << 16) + (MemRead8(addr + 3) << 24);
	}

	void TOWER_CC Adapter::MemWrite8(int32 addr, int8 data) {
		addr = MemAddrDecode(addr);
		if(!addr) return;

		switch(GfxReg[5] & 3) {
		case 0: // write mode 0
			data = rotateright(data, GfxReg[3] & 7);
			for(int p = 0; p < 4; ++p) {
				if(!(Sequencer[2] & (1 << p))) // memory plane write enable
					continue;

				int8 plane_data = (GfxReg[1] & (1 << p))
					? (GfxReg[0] & (1 << p)) ? (int8)-1 : 0
					: rotateright(data, GfxReg[3] & 7);
				switch(GfxReg[3] & 0x18) {
				case 0x08: plane_data &= LatchReg[p]; break;
				case 0x10: plane_data |= LatchReg[p]; break;
				case 0x18: plane_data ^= LatchReg[p]; break;
				}

				plane_data = (plane_data & GfxReg[8]) | (~GfxReg[8] & LatchReg[p]);

				*(vram + (p << 16) + addr) = plane_data;
			}
			break;
		case 1: // write mode 1
			for(int p = 0; p < 4; ++p) {
				if(!(Sequencer[2] & (1 << p)))
					continue;

				*(vram + (p << 16) + addr) = LatchReg[p];
			}
			break;
		case 2: // write mode 2
			for(int p = 0; p < 4; ++p) {
				if(!(Sequencer[2] & (1 << p)))
					continue;

				int8 plane_data = (data & (1 << p)) ? (int8)-1 : 0;
				switch(GfxReg[3] & 0x18) {
				case 0x08: plane_data &= LatchReg[p]; break;
				case 0x10: plane_data |= LatchReg[p]; break;
				case 0x18: plane_data ^= LatchReg[p]; break;
				}

				plane_data = (plane_data & GfxReg[8]) | (~GfxReg[8] & LatchReg[p]);

				*(vram + (p << 16) + addr) = plane_data;
			}
			break;
		default: // write mode 3
			ZSSERT(0);
			break;
		}
	}

	void TOWER_CC Adapter::MemWrite16(int32 addr, int16 data) {
		MemWrite8(addr, (int8)data);
		MemWrite8(addr + 1, (int8)(data >> 8));
	}

	void TOWER_CC Adapter::MemWrite32(int32 addr, int32 data) {
		MemWrite8(addr, (int8)data);
		MemWrite8(addr + 1, (int8)(data >> 8));
		MemWrite8(addr + 2, (int8)(data >> 16));
		MemWrite8(addr + 3, (int8)(data >> 24));
	}
}}