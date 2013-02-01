#include "stdafx.h"
#include "DiskChange.h"

#include "calls.h"

namespace Tower { namespace Hle {
	DiskChange::DiskChange(wchar_t letter) :
		grp(letter, true) {
		switch(letter) {
		case L'A':
			disk = 0;
			SetText(L"A:");
			break;
		case L'C':
			disk = 1;
			SetText(L"C:");
			break;
		case L'D':
			disk = 2;
			SetText(L"D:");
			break;
		default:
			ZSSERT(0);
		}
	}

	void DiskChange::OnCreated() {
		grp.Move(8, 8);
		grp.Create(*this);

		cmdOK.SetText(L"OK");
		cmdOK.Pushed += Piston::Delegate<void()>(this, &DiskChange::cmdOK_Pushed);
		cmdOK.Resize(72, 24);
		cmdOK.Create(*this);

		cmdCancel.SetText(L"Cancel");
		cmdCancel.Resize(cmdOK.GetSize());
		cmdCancel.Pushed += Piston::Delegate<void()>(this, &DiskChange::cmdCancel_Pushed);
		cmdCancel.Create(*this);

		ResizeClient(384, 144);
		OnResized();
	}

	void DiskChange::OnResized() {
		cmdCancel.Move(ClientWidth() - cmdCancel.Width() - 8, ClientHeight() - cmdCancel.Height() - 8);
		cmdOK.Move(cmdCancel.X() - cmdOK.Width() - 8, cmdCancel.Y());
		grp.Resize(ClientWidth() - 16, cmdOK.Y() - 16);
	}

	void DiskChange::cmdOK_Pushed() {
		Config::Drives[disk].File = grp.txtImage.GetText();
		Config::Drives[disk].Mounted = grp.chkMounted.IsChecked();
		Config::Drives[disk].Readonly = grp.chkReadonly.IsChecked();

		drives[disk].file->Close();
		if(Config::Drives[disk].Mounted) {
			drives[disk].file->Open(Config::Drives[disk].File, Config::Drives[disk].Readonly ? Piston::Io::File::Access::Read : Piston::Io::File::Access::ReadWrite, Piston::Io::File::Sharing::ReadWrite);
		}

		CloseDialog(1);
	}
}}