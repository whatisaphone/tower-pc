#include "stdafx.h"
#include "Logger.h"

#include "Piston\Debugger.h"

#include "App.h"
#include "Guest.h"

namespace Tower {
	void TOWER_CC Logger::Log(const void *persist, unsigned int flags, const wchar_t *text) {
		const GuestDev *dev = Guest::FindPersist(persist);
		ZSSERT(dev);
		if(!dev) return;

		// very temporary, change to "if((flags & 15) < dev->GetLogThresh()) return;"
		unsigned int thresh;
		if(dev->GetName().StartsWith(L"Vga"))
			thresh = LOG_TRACE;
		else
			thresh = LOG_DEBUG;
		if((flags & 15) < thresh)
			return;

		Log(dev->GetName(), flags, text);
	}

	void Logger::Log(const wchar_t *devName, unsigned int flags, const wchar_t *text) {
		App::logger->Log(flags, Piston::String(L"[") + devName + L"] " + text);
	}

	Logger::Logger() {
		Resize(600, 350);
		SetText(L"Console");
	}

	void Logger::OnCreated() {
		txtLog.SetMultiline(true);
		txtLog.SetShowScrollVert(true);
		txtLog.SetReadOnly(true);
		txtLog.Create(*this);

		OnResized();
	}

	void Logger::OnResized() {
		txtLog.Move(0, 0, ClientSize());
	}

	void Logger::Hide() {
		Form::Hide();
	}

	void Logger::Log(unsigned int flags, const wchar_t *text) {
		//int s1 = txtLog.GetSelStart(), s2 = txtLog.GetSelLength();
		//txtLog.SetText(txtLog.GetText() + text + L"\r\n");
		//txtLog.Select(s1, s2);
		Piston::Debugger::WriteLn(text);
	}

	void Logger::Show() {
		Form::Show();
	}
}