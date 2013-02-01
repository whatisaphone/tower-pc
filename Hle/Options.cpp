#include "stdafx.h"
#include "Options.h"

#include "Config.h"

namespace Tower { namespace Hle {
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
	OptionsGroup *Options::drives[3];

	bool Options::Commit() {
		const wchar_t *fns[3] = {L"\\\\.\\A:", L"\\\\.\\C:", L"\\\\.\\D:"};

		for(int i = 0; i < 3; ++i) {
			Config::Drives[i].Enabled = drives[i]->check.IsChecked();
			if(drives[i]->optPhysical.GetValue())
				Config::Drives[i].File = fns[i]; // TODO: get real physical drive
			else
				Config::Drives[i].File = drives[i]->txtImage.GetText();
			Config::Drives[i].Mounted = drives[i]->chkMounted.IsChecked();
			Config::Drives[i].Readonly = drives[i]->chkReadonly.IsChecked();
		}

		return true;
	}

	int32 Options::Create(Piston::Win32::HWND parent) {
		dlg = new Piston::Gui::ChildWindow();
		dlg->Move(Piston::Gui::NativeWindow::GetClientRect(parent));
		dlg->Create(parent);

		drives[0] = new OptionsGroup(L'A', false);
		drives[0]->Move(0, 0);
		drives[0]->Create(*dlg);

		drives[1] = new OptionsGroup(L'C', false);
		drives[1]->Move(0, 0);
		drives[1]->Create(*dlg);

		drives[2] = new OptionsGroup(L'D', false);
		drives[2]->Move(0, 0);
		drives[2]->Create(*dlg);

		DoLayout();

		return 1;
	}

	void Options::Destroy() {
		dlg->Close();
		delete dlg;
		delete drives[0];
		delete drives[1];
		delete drives[2];
	}

	void Options::DoLayout() {
		int each = dlg->Height() / 3 - 16;
		drives[0]->Move(0, 0, dlg->Width(), each);
		drives[1]->Move(0, drives[0]->Bottom() + 8, drives[0]->GetSize());
		drives[2]->Move(0, drives[1]->Bottom() + 8, drives[0]->GetSize());
	}
}}