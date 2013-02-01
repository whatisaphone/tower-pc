#include "stdafx.h"
#include "loop.h"

#include "Config.h"
#include "cpu.h"

namespace Tower { namespace X86 {
	unsigned int TowerWantsPause, TowerWantsQuit; // these also in cpu.h
	unsigned int INTPIN;
	unsigned int AsyncEventCount;
	Piston::Thread<void()> *CpuThread;
	Piston::System::Event *CpuPaused, *CanContinueRunning;
}}

#define X86_INCLUDE_MASTER "loop.hpp"
	#include "the_include_master.h"

namespace Tower { namespace X86 {
	TOWER_EXPORT void tower_cpu_ExternalInterrupt() {
		if(!INTPIN) {
			++INTPIN;
			++AsyncEventCount;
		}
	}

	void FillOpTables() {
		switch(Config::CpuLevel) {
#ifdef X86_SUPPORT_8086
		case X86_8086: X86_100_FillOpcodeTables(); break;
#endif
#ifdef X86_SUPPORT_186
		case X86_186: X86_150_FillOpcodeTables(); break;
#endif
#ifdef X86_SUPPORT_286
		case X86_286: X86_200_FillOpcodeTables(); break;
#endif
#ifdef X86_SUPPORT_386
		case X86_386: X86_300_FillOpcodeTables(); break;
#endif
#ifdef X86_SUPPORT_486
		case X86_486: X86_350_FillOpcodeTables(); break;
#endif
#ifdef X86_SUPPORT_P1
		case X86_P1: X86_400_FillOpcodeTables(); break;
#endif
		default: ZSSERT(0);
		}
	}

	void CpuInit() {
		CpuPaused = new Piston::System::Event();
		CpuPaused->Create();
		CanContinueRunning = new Piston::System::Event();
		CanContinueRunning->Create();
		CpuThread = new Piston::Thread<void()>(&CpuMain);

		FillOpTables();

		INTPIN = 0;
		TowerWantsQuit = 0;
		TowerWantsPause = 1;
		AsyncEventCount = 1; // get thread into the normal "paused" state
		CpuThread->Start();
		CpuPaused->Wait();
	}

	void CpuMain() {
		for(;;) {
			switch(Config::CpuLevel) {
#ifdef X86_SUPPORT_8086
			case X86_8086: X86_100_Loop(); break;
#endif
#ifdef X86_SUPPORT_186
			case X86_186: X86_150_Loop(); break;
#endif
#ifdef X86_SUPPORT_286
			case X86_286: X86_200_Loop(); break;
#endif
#ifdef X86_SUPPORT_386
			case X86_386: X86_300_Loop(); break;
#endif
#ifdef X86_SUPPORT_486
			case X86_486: X86_350_Loop(); break;
#endif
#ifdef X86_SUPPORT_P1
			case X86_P1: X86_400_Loop(); break;
#endif
			default: ZSSERT(0);
			}

			if(TowerWantsQuit)
				break;

			// here switch cpu and stuff (but not modes, that happens in loops)
		}
	}

	void CpuPause() {
		if(TowerWantsPause) return;
		++TowerWantsPause;
		++AsyncEventCount;

		CpuPaused->Wait();
	}

	void CpuQuit() {
		if(TowerWantsQuit) return;
		++TowerWantsQuit;
		++AsyncEventCount;

		CanContinueRunning->Signal();
		CpuThread->WaitForExit(); // check out real.cpp\HandleAsyncEvents for the codeflow

		delete CpuThread;
		delete CpuPaused;
		delete CanContinueRunning;
	}

	void CpuResume() {
		CanContinueRunning->Signal();
	}

	void CpuReset() {
		switch(Config::CpuLevel) {
#ifdef X86_SUPPORT_8086
		case X86_8086: X86_100_Reset(); break;
#endif
#ifdef X86_SUPPORT_186
		case X86_186: X86_150_Reset(); break;
#endif
#ifdef X86_SUPPORT_286
		case X86_286: X86_200_Reset(); break;
#endif
#ifdef X86_SUPPORT_386
		case X86_386: X86_300_Reset(); break;
#endif
#ifdef X86_SUPPORT_486
		case X86_486: X86_350_Reset(); break;
#endif
#ifdef X86_SUPPORT_P1
		case X86_486: X86_400_Reset(); break;
#endif
		default: ZSSERT(0);
		}
	}
}}


	// x86 async events in order of priority:
	// HIGHEST: Tower host events
	//          Faults
	//          trap instructions
	//          debug traps for this instruction
	//          debug faults for next instruction
	//          NMI pin
	// LOWEST:  INTR pin

	// taken from online:
	// <--- HIGHEST ------------------- LOWEST ----> 
	// 
	// IRQ0, 1, 2=(8, 9, 10, 11, 12, 13, 14, 15), 3, 4, 5, 6, 7 
   	//    |  |  |  |  |           |   |   |   |   |  |  |  |  |_ printer 
   	//    |  |  |  |  | mouse ____|   |   |   |   |  |  |  |____ Floppy 
   	//    |  |  |  |  | float error __| IDE0  |   |  |  |_______ Fixed disk/sound card 
   	//    |  |  |  |  |                 IDE1 _|   |  |__________ Serial 0 
   	//    |  |  |  |  |_____ ACPI events/devices  |_____________ Serial 1 
   	//    |  |  |  |________ RTC (real-time clock)
   	//    |  |  |___________ IRQ2->IRQ8 cascade RTC 
   	//    |  |______________ Keyboard 
   	//    |_________________ PIT channel 0