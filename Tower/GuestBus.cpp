#include "stdafx.h"
#include "Guest.h"

#include "Piston\StringBuilder.h"
#include "Piston\Gui\MessageBox.h"

#include "Logger.h"

namespace Tower {
	// from pic to cpu
	void Guest::ExternalInterrupt() {
		Cpu->cpu_ExternalInterrupt();
	}

	// from cpu to pic
	int8 Guest::INTA() {
		ZSSERT(Pic);
		return Pic->pic_INTA();
	}

	// from device to pic
	void Guest::RaiseIRQ(int8 irq) {
		if(Pic) Pic->pic_RaiseIRQ(irq);
	}
}