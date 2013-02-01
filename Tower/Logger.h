#pragma once
#include "stdafx.h"

#include "Piston\Gui\Form.h"
#include "Piston\Gui\TextBox.h"

namespace Tower {
	class Logger : public Piston::Gui::Form {
	private:
		Piston::Gui::TextBox txtLog;

		Logger(const Logger &copy);
		Logger &operator=(const Logger &copy);

	protected:
		virtual void OnCreated() PISTON_OVERRIDE;
		virtual void OnResized() PISTON_OVERRIDE;

	public:
		Logger();

		void ClearLog() {txtLog.SetText(0);}
		void Hide();
		static void TOWER_CC Log(const void *persist, unsigned int flags, const wchar_t *text);
		static void Log(const wchar_t *devName, unsigned int flags, const wchar_t *text);
		void Log(unsigned int flags, const wchar_t *text);
		void Show();
	};
}