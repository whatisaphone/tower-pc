#pragma once
#include "stdafx.h"

namespace Tower {
	class Logger;
	class MainForm;
}

namespace Tower {
	class App {
	private:
		App();
		App(const App &copy);
		App &operator=(const App &copy);

	public:
		static bool statusBar;

		static Logger *logger;
		static MainForm *mainForm;
	};
}