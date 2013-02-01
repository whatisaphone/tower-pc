#pragma once
#include "stdafx.h"

#include "Piston\Gui\Button.h"
#include "Piston\Gui\Dialog.h"

#include "OptionsGroup.h"

namespace Tower { namespace Hle {
	class DiskChange : public Piston::Gui::Dialog {
	private:
		typedef Piston::Gui::Dialog base;

		int disk;

		OptionsGroup grp;
		Piston::Gui::Button cmdOK, cmdCancel;

		DiskChange(const DiskChange &copy);
		DiskChange &operator=(const DiskChange &copy);

		void cmdOK_Pushed();
		void cmdCancel_Pushed() {CloseDialog(0);}

	protected:
		virtual void OnCreated() PISTON_OVERRIDE;
		virtual void OnResized() PISTON_OVERRIDE;

	public:
		DiskChange(wchar_t letter);

		int ShowDialog(Piston::Win32::HWND owner) {return base::ShowDialog(owner);}
	};
}}