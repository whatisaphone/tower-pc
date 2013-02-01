#pragma once
#include "stdafx.h"

#include "Piston\Gui\Button.h"
#include "Piston\Gui\CheckBox.h"
#include "Piston\Gui\ComboBox.h"
#include "Piston\Gui\GroupBox.h"
#include "Piston\Gui\RadioButton.h"
#include "Piston\Gui\TextBox.h"

#include "Config.h"

namespace Tower { namespace Hle {
	class OptionsGroup : public Piston::Gui::ChildWindow {
	private:
		typedef Piston::Gui::ChildWindow base;

		unsigned int drive;
		bool runtime;

		OptionsGroup(const OptionsGroup &copy);
		OptionsGroup &operator=(const OptionsGroup &copy);

	protected:
		virtual void OnCreated() PISTON_OVERRIDE;
		virtual void OnResized() PISTON_OVERRIDE;

	public:
		Piston::Gui::GroupBox frame;
		Piston::Gui::CheckBox check;
		Piston::Gui::RadioButton optPhysical, optImage;
		Piston::Gui::ComboBox cboPhysical;
		Piston::Gui::TextBox txtImage;
		Piston::Gui::Button cmdImage;
		Piston::Gui::CheckBox chkMounted, chkReadonly;

		OptionsGroup(wchar_t letter, bool runtime) :
			runtime(runtime) {
			if(letter == L'A') drive = 0;
			else if(letter == L'C') drive = 1;
			else if(letter == L'D') drive = 2;
			else ZSSERT(0);
		}
	};

	inline void OptionsGroup::OnCreated() {
		if(drive == 2) check.Disable(); // no cd support yet

		frame.Move(0, 0, 000000, 56);
		frame.Create(*this);

		if(drive == 0) check.SetText(L"A:");
		else if(drive == 1) check.SetText(L"C:");
		else if(drive == 2) check.SetText(L"D:");
		else ZSSERT(0);
		check.Move(8, 2, 32, 16);
		check.Enable(!runtime);
		check.Create(*this);
		check.Check(drive == 0);

		optPhysical.Enable(drive != 1);
		optPhysical.Move(8, 24, 16, 20);
		optPhysical.Create(frame);

		cboPhysical.Enable(optPhysical.IsEnabled());
		cboPhysical.SetType(Piston::Gui::ComboBox::Type::DropdownList);
		cboPhysical.Move(24, 24, 96, 16);
		cboPhysical.Create(frame);
		if(drive == 0) cboPhysical.Items().Add(L"Physical A:");
		if(drive == 2) cboPhysical.Items().Add(L"Physical D:");

		optImage.Move(8, 48, 16, 20);
		optImage.Create(frame);

		txtImage.Move(24, 48, 000000, 20);
		txtImage.Create(frame);

		cmdImage.SetText(L"O");
		cmdImage.Move(000000, txtImage.Y(), 20, 20);
		cmdImage.Create(frame);

		chkMounted.Enable(drive != 1);
		chkMounted.SetText(L"Mounted");
		chkMounted.Create(frame);

		chkReadonly.Enable(drive != 2);
		chkReadonly.SetText(L"Read-only");
		chkReadonly.Create(frame);

		check.Check(Config::Drives[drive].Enabled);
		if(Config::Drives[drive].File.StartsWith(L"\\\\.\\")) {
			optPhysical.SetValue(true);
		} else {
			optImage.SetValue(true);
			txtImage.SetText(Config::Drives[drive].File);
		}
		chkMounted.Check(Config::Drives[drive].Mounted);
		chkReadonly.Check(Config::Drives[drive].Readonly);
	}

	inline void OptionsGroup::OnResized() {
		frame.Move(ClientRect());

		cmdImage.SetX(Right() - 8 - cmdImage.Width());
		txtImage.SetRight(cmdImage.X());

		chkMounted.Move(8, 72, Width() / 2 - 16, 16);
		chkReadonly.Move(Width() / 2, chkMounted.Y(), chkMounted.GetSize());
	}
}}