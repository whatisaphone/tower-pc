#pragma once
#include "stdafx.h"

#include "Piston\Win32\types.h"

#include "GuestDev.h"
#include "Profile.h"

namespace Tower {
	class Guest {
	private:
		Guest();
		Guest(const Guest &copy);
		Guest &operator=(const Guest &copy);

		class Ram {
		private:
#ifdef _DEBUG
			static void Undefined(int what, int32 addr, int32 data);
#else
			static void Undefined(int what, int32 addr, int32 data) {}
#endif
			static int8 TOWER_CC UDRead8(int32 addr) {Undefined(0, addr, 0); return 0xff;}
			static int16 TOWER_CC UDRead16(int32 addr) {Undefined(1, addr, 0); return 0xffff;}
			static int32 TOWER_CC UDRead32(int32 addr) {Undefined(2, addr, 0); return 0xffffffff;}
			static void TOWER_CC UDWrite8(int32 addr, int8 data) {Undefined(3, addr, data);}
			static void TOWER_CC UDWrite16(int32 addr, int16 data) {Undefined(4, addr, data);}
			static void TOWER_CC UDWrite32(int32 addr, int32 data) {Undefined(5, addr, data);}

			Ram();
			Ram(const Ram &copy);
			Ram &operator=(const Ram &copy);

			static const unsigned int MapCount = 3;
			static struct Map {
				const void *dev_persist;
				int32 mem_hi, dev_hi;
				int8 (TOWER_CC *Read8)(int32 addr);
				int16 (TOWER_CC *Read16)(int32 addr);
				int32 (TOWER_CC *Read32)(int32 addr);
				void (TOWER_CC *Write8)(int32 addr, int8 data);
				void (TOWER_CC *Write16)(int32 addr, int16 data);
				void (TOWER_CC *Write32)(int32 addr, int32 data);

				void Clear() {
					dev_persist = 0; mem_hi = 0; dev_hi = 0;
					Read8 = &UDRead8; Read16 = &UDRead16; Read32 = &UDRead32;
					Write8 = &UDWrite8; Write16 = &UDWrite16; Write32 = &UDWrite32;
				}

				void Set(const void *dev_persist, int32 mem_hi, int32 dev_hi, const MemHandlers *handlers) {
					this->dev_persist = dev_persist; this->mem_hi = mem_hi; this->dev_hi = dev_hi;
					Read8 = handlers->Read8; Read16 = handlers->Read16; Read32 = handlers->Read32;
					Write8 = handlers->Write8; Write16 = handlers->Write16; Write32 = handlers->Write32;
				}
			} maps[MapCount];
			static int8 *ram;
		public:
			static bool Init(unsigned long bytes);
			static void Uninit();
			static bool IsLoaded() {return ram != 0;}
			static bool InsertAt(int index);
			static int8 *TOWER_CC MapAdd(const void *persist, int32 dev_lo, int32 dev_hi, const MemHandlers *handlers);
			static void TOWER_CC MapRemove(const void *persist, int32 dev_lo);
			static int8 TOWER_CC Read8(int32 addr);
			static int16 TOWER_CC Read16(int32 addr);
			static int32 TOWER_CC Read32(int32 addr);
			static void TOWER_CC Write8(int32 addr, int8 data);
			static void TOWER_CC Write16(int32 addr, int16 data);
			static void TOWER_CC Write32(int32 addr, int32 data);
		};

		class Ports {
		private:
#ifdef _DEBUG
			static void Undefined(int what, int16 port, int32 value);
#else
			static void Undefined(int what, int16 port, int32 value) {}
#endif
			static int8 TOWER_CC UDRead8(int16 port) {Undefined(0, port, 0); return 0xff;}
			static int16 TOWER_CC UDRead16(int16 port) {Undefined(1, port, 0); return 0xffff;}
			static int32 TOWER_CC UDRead32(int16 port) {Undefined(2, port, 0); return 0xffffffff;}
			static void TOWER_CC UDWrite8(int16 port, int8 value) {Undefined(3, port, value);}
			static void TOWER_CC UDWrite16(int16 port, int16 value) {Undefined(4, port, value);}
			static void TOWER_CC UDWrite32(int16 port, int32 value) {Undefined(5, port, value);}

			Ports();
			Ports(const Ports &copy);
			Ports &operator=(const Ports &copy);

			static struct Map {
				const void *dev_persist;
				int8 (TOWER_CC *Read8)(int16 port);
				int16 (TOWER_CC *Read16)(int16 port);
				int32 (TOWER_CC *Read32)(int16 port);
				void (TOWER_CC *Write8)(int16 port, int8 value);
				void (TOWER_CC *Write16)(int16 port, int16 value);
				void (TOWER_CC *Write32)(int16 port, int32 value);

				void Clear() {
					dev_persist = 0;
					Read8 = &UDRead8; Read16 = &UDRead16; Read32 = &UDRead32;
					Write8 = &UDWrite8; Write16 = &UDWrite16; Write32 = &UDWrite32;
				}

				void Set(const void *dev_persist, const PortHandlers *handlers) {
					this->dev_persist = dev_persist;
					Read8 = handlers->Read8; Read16 = handlers->Read16; Read32 = handlers->Read32;
					Write8 = handlers->Write8; Write16 = handlers->Write16; Write32 = handlers->Write32;
				}
			} maps[0x10000];

		public:
			static bool Init();
			static void Uninit() {}
			static int32 TOWER_CC Claim(const void *persist, int16 low, int16 high, const PortHandlers *handlers);
			static void TOWER_CC Release(const void *persist, int16 low, int16 high);
			static int8 TOWER_CC Read8(int16 port) {return maps[port].Read8(port);}
			static int16 TOWER_CC Read16(int16 port) {return maps[port].Read16(port);}
			static int32 TOWER_CC Read32(int16 port) {return maps[port].Read32(port);}
			static void TOWER_CC Write8(int16 port, int8 value) {maps[port].Write8(port, value);}
			static void TOWER_CC Write16(int16 port, int16 value) {maps[port].Write16(port, value);}
			static void TOWER_CC Write32(int16 port, int32 value) {maps[port].Write32(port, value);}
		};

		static const Profile *profile;

		static void TOWER_CC TimePassed(int32 milliseconds);

		static void ExternalInterrupt(); // from pic to cpu
		static int8 INTA(); // from cpu to pic
		static void RaiseIRQ(int8 irq); // from device to pic

	public:
		static int DevCount;
		static GuestDev *Devs;
		static GuestDev *Cpu;
		static GuestDev *Video;
		static GuestDev *Pic;

		static GuestDev *FindPersist(const void *persist);
		static bool Init(Piston::Win32::HWND dlgOwner, Profile &profile);
		static void Pause();
		static void Reset();
		static bool Run();
		static void SendKeyDown(int32 keyInfo);
		static void SendKeyUp(int32 keyInfo);
		static void Unload();

		static bool IsLoaded() {return Ram::IsLoaded();}
		static bool IsRunning() {if(!Cpu) return false; return Cpu->IsRunning();}
	};
}