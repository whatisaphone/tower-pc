#pragma once
#include "stdafx.h"

#include "Piston\Io\File.h"

namespace Tower { namespace Hle {
	void int_09();
	void int_10();
	bool int_13_init();
	void int_13_cleanup();
	void int_13();
	void int_15();
	void int_16();
	void int_1a();

	extern struct rtd {
		Piston::Io::File *file;
		int32 bytes_per_sect, sect_per_cyl, cyl_per_head, heads;
	} drives[3];
}}