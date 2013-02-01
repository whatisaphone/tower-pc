#include "stdafx.h"
#include "MainForm.h"

#include "Piston\Gdi\DeviceContext.h"
#include "Piston\Gdi\Stock.h"
#include "Piston\Gui\MenuItem.h"
#include "Piston\Gui\MessageBox.h"

#include "App.h"
#include "Guest.h"
#include "Logger.h"

namespace Tower {
	struct StatusPartInfo {
		GuestDev *dev;
		int32 priority;
		StatusPartInfo(GuestDev *dev, int32 priority) : dev(dev), priority(priority) {}
	};

	Piston::Win32::HWND MainForm::GetDisplayWindow() {
		return App::mainForm->screen.hWnd();
	}

	void TOWER_CC MainForm::RepaintScreen() {
		App::mainForm->screen.Repaint();
	}

	void TOWER_CC MainForm::ResizeScreen(const void *persist, int32 width, int32 height) {
		// TODO: put this back how it was
		//if(persist == Guest::Video->GetPersist())
		if(width > 0)
			App::mainForm->ResizeScreen(width, height);
		else
			RepaintScreen();
	}

	const void *MainForm::Status_Register(const void *persist, int32 priority, sint32 width, const TOWER_STRING text) {
		GuestDev *dev = Guest::FindPersist(persist);
		if(!dev) {
			ZSSERT(0);
			return;
		}

		int idx;
		for(idx = 1; idx < App::mainForm->statusBar.Parts().Count(); ++idx)
			if(priority < ((StatusPartInfo *)App::mainForm->statusBar.Parts()[idx].Tag)->priority)
				break;
		Piston::Gui::StatusBar::Part &p = App::mainForm->statusBar.Parts().Insert(idx, 100, text);
		p.Tag = new StatusPartInfo(dev, priority);

		Status_SetWidth(p.Tag, width);
		return p.Tag;
	}

	void MainForm::Status_SetWidth(const void *item, sint32 width) {
		int idx = App::mainForm->statusBar.Parts().IndexOfTag(item);
		ZSSERT(idx != -1);
		if(width < 0)
			ZSSERT(0);
		else if(width == 0)
			App::mainForm->statusBar.Parts()[idx].Resize(Piston::Gui::StatusBar::Part::Unit::Collapse, 1);
		else if(width <= (int)(unsigned short)-1)
			App::mainForm->statusBar.Parts()[idx].Resize((unsigned short)width);
		else
			ZSSERT(0);
	}

	void MainForm::Status_SetText(const void *item, const TOWER_STRING text) {
		int idx = App::mainForm->statusBar.Parts().IndexOfTag(item);
		ZSSERT(idx != -1);
		App::mainForm->statusBar.Parts()[idx].SetText(text);
	}

	MainForm::MainForm() {
		EnableMaximize(false); // reenable if full screen ever gets implemented
#ifdef _DEBUG
		SetText(L"Tower ******* DEBUG BUILD **********");
#else
		SetText(L"Tower");
#endif
		SetSizable(false);
	}

	void MainForm::OnCreated() {
		Piston::Gui::MessageBox::SetDefaultOwner(*this);
		Piston::Gui::MessageBox::SetDefaultCaption(L"Tower 0.01");

		Piston::Gui::MenuItem *mnu;
		mnu = menu.Items().Add(L"&File");
			mnu->Popup().Items().Add(L"&New\tCtrl+N", Piston::Delegate<void()>(this, &MainForm::mnuFile_New_Click));
			mnu->Popup().Items().Add(L"&Open...\tCtrl+O");
			mnu->Popup().Items().Add(L"&Save\tCtrl+S");
			mnu->Popup().Items().Add(L"Save &As...\tF12");
			mnu->Popup().Items().Add(L"Re&vert");
			mnu->Popup().Items().AddSeparator();
			mnu->Popup().Items().Add(L"E&xit\tAlt+F4", Piston::Delegate<void()>(this, &MainForm::mnuFile_Exit_Click));
		mnu = menu.Items().Add(L"&View");
			mnu->Popup().Items().Add(L"&Toolbar");
			mnu->Popup().Items().Add(L"&Status bar", Piston::Delegate<void()>(this, &MainForm::mnuView_StatusBar_Click))->Check(App::statusBar);
			mnu->Popup().Items().Add(L"&Full screen\tAlt+Enter");
			mnu->Popup().Items().AddSeparator();
			mnu->Popup().Items().Add(L"&Hook system keystrokes");
			mnu->Popup().Items().Add(L"     &Including Ctrl+Alt+Del");
			mnu->Popup().Items().AddSeparator();
			mnu->Popup().Items().Add(L"&ROM Font");
			mnu->Popup().Items().Add(L"&Custom Font...");
		mnu = menu.Items().Add(L"&System");
			mnu->Popup().Items().Add(L"&Power on\tF5", Piston::Delegate<void()>(this, &MainForm::mnuSystem_Power_Click));
			mnu->Popup().Items().Add(L"&Resume", Piston::Delegate<void()>(this, &MainForm::mnuSystem_Pause_Click))->Disable();
			mnu->Popup().Items().Add(L"&Hard reset")->Disable();
			mnu->Popup().Items().Add(L"&Soft reset\tCtrl+Alt+Del")->Disable();
			mnu->Popup().Items().AddSeparator();
			mnu->Popup().Items().Add(L"Show &console", Piston::Delegate<void()>(this, &MainForm::mnuSystem_Console_Click));
		SetMenu(&menu);

		editor.Create(*this);

		screen.SetBorderStyle(Piston::Gui::ChildWindow::BorderStyle::InsetThickest);
		screen.Paint += Piston::Delegate<void(Piston::Gdi::DeviceContext &)>(this, &MainForm::PaintScreen);
		screen.Hide();
		screen.Create(*this);

		statusBar.Show(App::statusBar);
		statusBar.DoubleClick += Piston::Delegate<void(Piston::Gui::StatusBar::MouseEventArgs &)>(this, &MainForm::statusBar_DoubleClick);
		statusBar.Create(*this);
		statusBar.Parts().Add(Piston::Gui::StatusBar::Part::Unit::Expand, 100, L"Powered off");

		ResizeScreen(0, 0); // editor default size
		OnResized();

		mnuFile_New_Click();
	}

	void MainForm::OnClosing(Piston::CancelMaster &cancel) {
		if(AskKillTheGuest())
			App::logger->Close();
		else
			cancel.Cancel();
	}

	void MainForm::OnKeyDown(Piston::Gui::KeyEventArgs &e) {
		if(e.KeyCurrentlyDown == e.KeyPreviouslyDown)
			return; // don't send repeats

		int32 info = (int16)e.VirtualKeyCode |
			e.ScanCode << 16 |
			e.ExtendedKey << 24 |
			e.Reserved << 25 |
			e.AltKeyDown << 29 |
			e.KeyPreviouslyDown << 30 |
			e.KeyCurrentlyDown << 31;

		Guest::SendKeyDown(info);

		e.Discard = 1;
	}

	void MainForm::OnKeyUp(Piston::Gui::KeyEventArgs &e) {
		if(e.KeyCurrentlyDown == e.KeyPreviouslyDown)
			return; // don't send repeats

		Guest::SendKeyUp((int16)e.VirtualKeyCode | e.ScanCode << 16 | e.ExtendedKey << 24 | e.Reserved << 25 | e.AltKeyDown << 29 | e.KeyPreviouslyDown << 30 | e.KeyCurrentlyDown << 31);

		e.Discard = 1;
	}

	void MainForm::OnResized() {
		int spaceY = ClientHeight();
		if(App::statusBar) {
			spaceY -= statusBar.Height();
			statusBar.Move(0, ClientHeight() - statusBar.Height(), ClientWidth());
		}
		if(Guest::IsLoaded())
			screen.Move(0, 0, ClientWidth(), spaceY);
		else
			editor.Move(0, 0, ClientWidth(), spaceY);
	}

	bool MainForm::AskKillTheGuest() {
		if(Guest::IsRunning()) {
			if(Piston::Gui::MessageBox::Show(L"The guest is still running.  Okay to kill it?",
				Piston::Gui::MessageBox::Buttons::YesNo | Piston::Gui::MessageBox::Icons::Question) !=
				Piston::Gui::MessageBox::Result::Yes)
					return false;
			mnuSystem_Power_Click();
		} else if(Guest::IsLoaded()) {
			if(Piston::Gui::MessageBox::Show(L"The guest is currently loaded.  Unload it?",
				Piston::Gui::MessageBox::Buttons::YesNo | Piston::Gui::MessageBox::Icons::Question) !=
				Piston::Gui::MessageBox::Result::Yes)
					return false;
			mnuSystem_Power_Click();
		}

		return true;
	}

	void MainForm::Cleanup() {
		menu[2][0].SetText(L"&Power on\tF5");
		menu[2][1].SetText(L"&Pause\tCtrl+Break");
		menu[2][1].Disable(); // pause
		menu[2][2].Disable(); // cold reboot
		menu[2][3].Disable(); // warm reboot

		for(int i = statusBar.Parts().Count() - 1; i > 0; --i) {
			delete statusBar.Parts()[i].Tag;
			statusBar.Parts().RemoveAt(i);
		}

		screen.Hide();
		editor.Show();
		ResizeScreen(0, 0);
	}

	void MainForm::PaintScreen(Piston::Gdi::DeviceContext &dc) {
		if(Guest::Video)
			Guest::Video->Refresh(dc.hDC());
		else {
			dc.SetBrush(Piston::Gdi::Stock::BlackBrush());
			dc.SetPen(Piston::Gdi::Stock::NullPen());
			dc.Rectangle(ClientRect());
		}
	}

	void MainForm::ResizeScreen(int32 width, int32 height) {
		const Window &area = width ? (Piston::Gui::Window &)(Guest::IsLoaded() ? screen : editor) : *this;
		if(!width) {
			width = 480;
			height = 360;
		}
		for(int i = 0; i < 2; ++i) { // do it twice, in case it's so small that toolbar wraps
			Piston::Size s = area.ClientSize();
			if(s.Equals(width, height)) break;

			s.Width = width - s.Width;
			s.Height = height - s.Height;
			Move(X() - s.Width / 2, Y() - s.Height / 2, Width() + s.Width, Height() + s.Height);
		}
		OnResized();
	}

	void MainForm::statusBar_DoubleClick(Piston::Gui::StatusBar::MouseEventArgs &e) {
		if(!e.Part()) return;
		if(!e.Part()->Tag) return;

		((StatusPartInfo *)e.Part()->Tag)->dev->StatusMouseDblClk(e.Part()->Tag, e.WhichButton, e.X, e.Y);
	}

	void MainForm::mnuFile_New_Click() {
		if(!AskKillTheGuest())
			return;

		editor.New();
	}

	void MainForm::mnuFile_Exit_Click() {
		Close();
	}

	void MainForm::mnuView_StatusBar_Click() {
		if(App::statusBar = !App::statusBar) {
			menu[1][1].Check();
			statusBar.Show();
			SetHeight(Height() + statusBar.Height());
		} else {
			menu[1][1].Uncheck();
			statusBar.Hide();
			SetHeight(Height() - statusBar.Height());
		}
	}

	void MainForm::mnuSystem_Power_Click() {
		if(Guest::IsLoaded()) { // powering off
			if(Guest::IsRunning())
				Guest::Pause();
			Guest::Unload();
			statusBar.Parts()[0].SetText(L"Powered off");
			Cleanup();
		} else { // powering on
			editor.Flush();
			if(!Guest::Init(*this, *Profile::Current)) {
				Guest::Unload();
				Cleanup();
				return;
			}
			menu[2][0].SetText(L"&Power off");
			menu[2][1].Enable(); // pause
			menu[2][2].Enable(); // cold reboot
			menu[2][3].Enable(); // warm reboot

			App::logger->ClearLog();
			editor.Hide();
			screen.Show();
			OnResized();
			//screen.SetFocus();

			if(!Guest::Run()) {
				statusBar.Parts()[0].SetText(L"Paused");
				return;
			}
			menu[2][1].SetText(L"&Pause\tCtrl+Break");
			statusBar.Parts()[0].SetText(L"Running");
		}
	}

	void MainForm::mnuSystem_Pause_Click() {
		if(Guest::IsRunning()) { // pause
			Guest::Pause();
			menu[2][1].SetText(L"&Resume\tF5");

			statusBar.Parts()[0].SetText(L"Paused");
		} else { // resume
			if(!Guest::Run())
				return;
			menu[2][1].SetText(L"&Pause\tCtrl+Break");

			statusBar.Parts()[0].SetText(L"Running");
		}
	}

	void MainForm::mnuSystem_Console_Click() {
		if(menu[2][5].IsChecked()) {
			menu[2][5].Uncheck();
			App::logger->Hide();
		} else {
			menu[2][5].Check();
			App::logger->Show();
		}
	}
}