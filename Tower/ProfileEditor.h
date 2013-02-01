#pragma once
#include "stdafx.h"

#include "Piston\Gui\Button.h"
#include "Piston\Gui\ComboBox.h"
#include "Piston\Gui\GroupBox.h"
#include "Piston\Gui\ListView.h"
#include "Piston\Gui\Static.h"
#include "Piston\Gui\TextBox.h"

#include "Profile.h"

namespace Tower {
	class ProfileEditor : public Piston::Gui::ChildWindow {
	private:
		static const int SplitPos;

		Piston::Gui::ListView lstDevs;
		Piston::Gui::ChildWindow pnlDLL, pnlRam;
			Piston::Gui::GroupBox grpRam;
			Piston::Gui::Static lblRam;
			Piston::Gui::ComboBox cboRam;
			Piston::Gui::Static lblRamMB;
		Piston::Gui::ChildWindow pnlMessage;
			Piston::Gui::GroupBox grpMessage;
			Piston::Gui::Static lblMessage;

		ProfileDev *activeDev;

		ProfileEditor(const ProfileEditor &copy);
		ProfileEditor &operator=(const ProfileEditor &copy);

		void Cleanup();
		bool DoHide(const void *what);
		void DoMessage(const wchar_t *title, const wchar_t *text);
		void DoShow(const void *what);

		void lstDevs_DeselectItem(Piston::Gui::ListView::Item &item, bool &allow);
		void lstDevs_SelectItem(Piston::Gui::ListView::Item &item, bool &allow);

	protected:
		virtual void OnCreated() PISTON_OVERRIDE;
		virtual void OnResized() PISTON_OVERRIDE;

	public:
		ProfileEditor();

		void Flush();
		void New();
	};
}