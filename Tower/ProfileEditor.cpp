#include "stdafx.h"
#include "ProfileEditor.h"

#include "Piston\Gui\MessageBox.h"

namespace Tower {
	static const int TXTH = 20;
	const int ProfileEditor::SplitPos = 200;

	ProfileEditor::ProfileEditor() :
		activeDev(0) {}

	void ProfileEditor::OnCreated() {
		lstDevs.SetView(Piston::Gui::ListView::View::Details);
		lstDevs.DeselectItem += Piston::Delegate<void(Piston::Gui::ListView::Item &, bool &)>(this, &ProfileEditor::lstDevs_DeselectItem);
		lstDevs.SelectItem += Piston::Delegate<void(Piston::Gui::ListView::Item &, bool &)>(this, &ProfileEditor::lstDevs_SelectItem);
		lstDevs.Create(*this);
		lstDevs.Columns().Add(100, L"Device");

		pnlDLL.Hide();
		pnlDLL.Create(*this);

		pnlRam.Hide();
		pnlRam.Create(*this);

			grpRam.SetText(L"RAM");
			grpRam.Move(0, 0, 100, 100);
			grpRam.Create(pnlRam);

			cboRam.Move(8, 16, 64, TXTH);
			cboRam.Create(grpRam);
			cboRam.Items().Clear();
			cboRam.Items().Add(L"1");
			cboRam.Items().Add(L"2");
			cboRam.Items().Add(L"3");
			cboRam.Items().Add(L"4");
			cboRam.Items().Add(L"6");
			cboRam.Items().Add(L"8");
			cboRam.Items().Add(L"12");
			cboRam.Items().Add(L"16");

			lblRamMB.SetText(L" MB");
			lblRamMB.Move(cboRam.Right(), cboRam.Y() + 3, 16, 16);
			lblRamMB.Create(pnlRam);

		pnlMessage.Hide();
		pnlMessage.Create(*this);
			grpMessage.Create(pnlMessage);
			lblMessage.Create(pnlMessage);
			lblMessage.SetTextAlign(Piston::Gui::Static::HAlign::Center);

		OnResized();
	}

	void ProfileEditor::OnResized() {
		ChildWindow::OnResized();

		lstDevs.Move(8, 8, SplitPos - 16, ClientHeight() - 16);

		pnlDLL.Move(SplitPos, 8, ClientWidth() - SplitPos - 8, ClientHeight() - 16);
		if(pnlRam.IsVisible()) {
			pnlRam.Move(pnlDLL.Bounds());
			grpRam.Move(0, 0, pnlRam.ClientWidth());
		}
		if(pnlMessage.IsVisible()) {
			pnlMessage.Move(pnlDLL.Bounds());
			grpMessage.Move(0, 0, pnlMessage.ClientWidth(), 96);
			lblMessage.Move(8, 40, pnlMessage.ClientWidth() - 16, 16);
		}
		//cmdCpuOptions.Move(GetClientWidth() - 8 - cmdCpuOptions.GetWidth(), txtCpu.GetY());
		//cmdCpuBrowse.Move(cmdCpuOptions.GetX() - cmdCpuBrowse.GetWidth(), txtCpu.GetY());
		//txtCpu.SetRight(cmdCpuBrowse.GetX());
	}

	void ProfileEditor::Cleanup() {
		// TODO: destroy all children of pnlDLL
		pnlDLL.Hide();
		pnlRam.Hide();
		pnlMessage.Hide();
	}

	// returns whether or not the hide was allowed
	bool ProfileEditor::DoHide(const void *what) {
		if(what == &pnlRam) {
			try {
				Profile::Current->RamSize = Piston::String::ParseInt(cboRam.GetText()) << 10 << 10;
			} catch(...) {
				return false;
			}
		} else {
			ZSSERT(what == activeDev);

			if(activeDev->OptionsHide() == 2) // means don't close
				return false;

			activeDev->Free();
		}

		Cleanup();
		return true;
	}

	void ProfileEditor::DoMessage(const wchar_t *title, const wchar_t *text) {
		Cleanup();

		if(text) {
			grpMessage.SetText(title);
			grpMessage.Show();
		} else
			grpMessage.Hide();
		lblMessage.SetText(text);
		pnlMessage.Show();

		OnResized();
	}

	void ProfileEditor::DoShow(const void *what) {
		Cleanup();

		if(what == &pnlRam) {
			activeDev = 0;
			pnlRam.Show();
		} else
			activeDev = (ProfileDev *)what;

		if(activeDev) {
			DoMessage(0, L"Loading...");
			Repaint();
			activeDev->Load();
			switch(activeDev->HasOptions()) {
			case 0:
				DoMessage(activeDev->FriendlyName(), L"This device has no options you can modify.");
				break;
			case 1:
				if(activeDev->OptionsShow(pnlDLL) == (int32)-1)
					goto case2;
				Cleanup();
				pnlDLL.Show();
				break;
			case 2: case2:
				DoMessage(activeDev->FriendlyName(), L"Error loading device options.");
				break;
			default:
				ZSSERT(0);
			}
		}

		OnResized();
	}

	void ProfileEditor::Flush() {
		//lstDevs.SetSelectedIndex(-1);
		bool todo = true;
		if(lstDevs.GetSelectedIndex() != -1)
			lstDevs_DeselectItem(lstDevs.GetSelectedItem(), todo);
	}

	void ProfileEditor::New() {
		if(Profile::Current)
			delete Profile::Current;
		cboRam.SetText(L"1");
		//txtCpu.SetText(L"386");

		Profile::Current = new Profile();
		Profile::Current->RamSize = 1 << 10 << 10;
		Profile::Current->RamInit = 3;
		Profile::Current->Devs.Add(ProfileDev(L"x86.dll"));
		Profile::Current->Devs.Add(ProfileDev(L"Chipset.dll"));
		Profile::Current->Devs.Add(ProfileDev(L"Vga.dll"));
		Profile::Current->Devs.Add(ProfileDev(L"Hle.dll"));

		lstDevs.Items().Clear();
		lstDevs.Items().Add(L"General").SetTag(&pnlRam);
		for(int i = 0; i < Profile::Current->Devs.Count(); ++i)
			lstDevs.Items().Add(Profile::Current->Devs[i].GetFileName().GetFileTitle()).SetTag(&Profile::Current->Devs[i]);
	}

	void ProfileEditor::lstDevs_DeselectItem(Piston::Gui::ListView::Item &item, bool &allow) {
		void *tag;

		if(lstDevs.GetSelectionCount() == 1) {
			tag = item.GetTag();
			ZSSERT(tag);
			allow = DoHide(tag);
			if(allow)
				DoMessage(0, L"No selection");
		}
	}

	void ProfileEditor::lstDevs_SelectItem(Piston::Gui::ListView::Item &item, bool &allow) {
		void *tag;

		if(lstDevs.GetSelectionCount() == 0) { // this will be only selected item
			tag = item.GetTag();
			ZSSERT(tag);
			DoShow(tag);
		} else
			DoMessage(0, L"Multiple selection");
	}

	/*void ProfileEditor::cmdCpuBrowse_Pushed() {}

	void ProfileEditor::cmdCpuOptions_Pushed() {
		DoOptions(Profile::Current->Cpu);
	}*/
}