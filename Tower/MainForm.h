#pragma once
#include "stdafx.h"

#include "Piston\Gui\ChildWindow.h"
#include "Piston\Gui\Form.h"
#include "Piston\Gui\MenuBar.h"
#include "Piston\Gui\StatusBar.h"

#include "ProfileEditor.h"

namespace Tower {
	class MainForm : public Piston::Gui::Form {
	private:
		Piston::Gui::MenuBar menu;
		ProfileEditor editor;
		Piston::Gui::ChildWindow screen;
		Piston::Gui::StatusBar statusBar;

		MainForm(const MainForm &copy);
		MainForm &operator=(const MainForm &copy);

		bool AskKillTheGuest();
		void Cleanup();
		void PaintScreen(Piston::Gdi::DeviceContext &dc);

		void statusBar_DoubleClick(Piston::Gui::StatusBar::MouseEventArgs &e);

		void mnuFile_New_Click();
		void mnuFile_Exit_Click();
		void mnuView_StatusBar_Click();
		void mnuSystem_Power_Click();
		void mnuSystem_Pause_Click();
		void mnuSystem_Console_Click();

	protected:
		virtual void OnCreated() PISTON_OVERRIDE;
		virtual void OnClosing(Piston::CancelMaster &cancel) PISTON_OVERRIDE;
		virtual void OnKeyDown(Piston::Gui::KeyEventArgs &e) PISTON_OVERRIDE;
		virtual void OnKeyUp(Piston::Gui::KeyEventArgs &e) PISTON_OVERRIDE;
		virtual void OnResized() PISTON_OVERRIDE;

	public:
		static Piston::Win32::HWND GetDisplayWindow();
		static void TOWER_CC RepaintScreen();
		static void TOWER_CC ResizeScreen(const void *persist, int32 width, int32 height);
		static const void *TOWER_CC Status_Register(const void *persist, int32 priority, sint32 width, const TOWER_STRING text);
		static void TOWER_CC Status_SetWidth(const void *item, sint32 width);
		static void TOWER_CC Status_SetText(const void *item, const TOWER_STRING text);

		MainForm();

		void ResizeScreen(int32 width, int32 height);
	};
}