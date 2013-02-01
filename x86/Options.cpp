#include "stdafx.h"
#include "Options.h"

#include "Config.h"

namespace Tower { namespace X86 {
	TOWER_EXPORT int32 tower_opt_Init(const void *persist, int32 persist_len) {
		Config::Parse(persist, persist_len);
		return 1;
	}

	TOWER_EXPORT int32 tower_opt_Show(const void *container) {
		return Options::Create((Piston::Win32::HWND)container);
	}

	TOWER_EXPORT int32 tower_opt_Hide(void **persist, int32 *persist_len) {
		if(!Options::Commit()) return 2;
		Config::Render(persist, persist_len);
		Options::Destroy();
		return 1;
	}

	TOWER_EXPORT void tower_opt_Uninit(void *persist, int32 persist_len) {
		Config::Cleanup();
	}

	Piston::Gui::ChildWindow *Options::dlg;
	Piston::Gui::GroupBox *Options::grp;

	bool Options::Commit() {
		return true;
	}

	int32 Options::Create(Piston::Win32::HWND parent) {
		dlg = new Piston::Gui::ChildWindow();
		dlg->Move(Piston::Gui::NativeWindow::GetClientRect(parent));
		dlg->Create(parent);

		grp = new Piston::Gui::GroupBox();
		grp->SetText(Piston::String::Render(Config::CpuLevel));
		grp->Create(*dlg);

		DoLayout();

		return 1;
	}

	void Options::Destroy() {
		dlg->Close();
		delete grp;
		delete dlg;
	}

	void Options::DoLayout() {
		grp->Move(dlg->ClientRect());
	}
}}