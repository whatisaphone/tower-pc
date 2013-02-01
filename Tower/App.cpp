#include "stdafx.h"
#include "App.h"

#include "Piston\EntryPoint.h"
#include "Piston\Gui\MessageLoop.h"

#include "App.h"
#include "Logger.h"
#include "MainForm.h"

int PistonMain() {
	Tower::App::statusBar = true;

	Tower::Logger l;
	Tower::App::logger = &l;

	Tower::MainForm f;
	Tower::App::mainForm = &f;

	return Piston::Gui::MessageLoop::Run(&f);
}

namespace Tower {
	bool App::statusBar;

	Logger *App::logger;
	MainForm *App::mainForm;
}