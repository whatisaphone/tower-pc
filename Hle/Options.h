#pragma once
#include "stdafx.h"

#include "OptionsGroup.h"

namespace Tower { namespace Hle {
	class Options {
	private:
		Options();
		Options(const Options &copy);
		Options &operator=(const Options &copy);

		static Piston::Gui::ChildWindow *dlg;
		static OptionsGroup *drives[3];

		static void DoLayout();

	public:
		static bool Commit();
		static int32 Create(Piston::Win32::HWND parent);
		static void Destroy();
		static int32 Hide(void **persist, int32 *persist_len);
	};
}}