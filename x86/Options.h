#pragma once
#include "stdafx.h"

#include "Piston\Gui\GroupBox.h"

namespace Tower { namespace X86 {
	class Options {
	private:
		Options();
		Options(const Options &copy);
		Options &operator=(const Options &copy);

		static Piston::Gui::ChildWindow *dlg;
		static Piston::Gui::GroupBox *grp;

		static void DoLayout();

	public:
		static bool Commit();
		static int32 Create(Piston::Win32::HWND parent);
		static void Destroy();
		static int32 Hide(void **persist, int32 *persist_len);
	};
}}