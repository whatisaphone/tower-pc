#pragma once

#include "Piston\Io\MemoryBuffer.h"
#include "Piston\Io\Path.h"

#include "Piston\System\Module.h"

namespace Tower {
	class ProfileDev {
	private:
		Piston::Io::Path fileName;
		Piston::Io::MemoryBuffer persist;
		unsigned int info;
		Piston::System::Module mod;
		int32 (TOWER_CC *opt_Init)(const void *, int32);
		int32 (TOWER_CC *opt_Show)(const void *);
		int32 (TOWER_CC *opt_Hide)(void **, int32 *);
		void (TOWER_CC *opt_Uninit)(void *, int32);
		unsigned int hasOptions : 2; // 0=none, 1=yep, 2=error
		unsigned int optionsState : 2; // 0=none, 1=init'd, 2=shown

	public:
		//static const wchar_t *GetDevName(unsigned int type);

		ProfileDev() {}
		ProfileDev(const wchar_t *fileName) : fileName(fileName) {}

		int32 Load();
		int32 OptionsShow(Piston::Win32::HWND container);
		int32 OptionsHide();

		void Free();
		unsigned int HasOptions() {if(!mod.IsLoaded()) Load(); return hasOptions;}

		Piston::String FriendlyName() const {return Piston::Io::Path::GetFileTitle(fileName);}
		Piston::Io::Path GetFileName() const {return fileName;}
		const Piston::Io::MemoryBuffer &GetPersist() const {return persist;}

		void SetFileName(const wchar_t *fileName) {ZSSERT(!mod.IsLoaded()); this->fileName = fileName; persist.Clear();}
	};
}













/*#pragma once

#include "Piston\Io\MemoryBuffer.h"
#include "Piston\Io\Path.h"

#include "Piston\System\Module.h"

namespace Tower {
	class ProfileDevBase PISTON_ABSTRACT {
	private:
		Piston::Io::Path fileName;
		Piston::Io::MemoryBuffer persist;
		unsigned int info;
		Piston::System::Module mod;
		Piston::Delegate<bool TOWER_CC(const void *, int32)> opt_Init;
		Piston::Delegate<bool TOWER_CC(Piston::Win32::HWND)> opt_Show;
		Piston::Delegate<void TOWER_CC(void **, int32 *)> opt_Hide;
		Piston::Delegate<void TOWER_CC(void *, int32)> opt_Uninit;
		int hasOptions : 1; // 0=none, 1=yep, 2=error
		bool tested : 1;

	protected:
		~ProfileDevBase() {}

		virtual bool Test() = 0;
		bool Test(unsigned int expectedType);
		virtual bool TestSomeMore(Piston::System::Module &module) = 0;

	public:
		static const wchar_t *GetDevName(unsigned int type);

		ProfileDevBase() : tested(false) {}
		ProfileDevBase(const wchar_t *fileName) : fileName(fileName), tested(false) {}

		int ShowOptions(Piston::Win32::HWND container);
		void HideOptions(void **persist, unsigned long *persist_len);

		Piston::Io::Path GetFileName() const {return fileName;}
		const Piston::Io::MemoryBuffer &GetPersist() const {return persist;}
		bool HasOptions() const {return hasOptions;}
		void SetFileName(const wchar_t *fileName) {this->fileName = fileName; tested = false; persist.Clear();}
#pragma warning(push)
#pragma warning(disable: 4265)
	};
#pragma warning(pop)

	class ProfileCpu PISTON_SEALED : public ProfileDevBase {
	public:
		ProfileCpu() {}
		ProfileCpu(const wchar_t *fileName) : ProfileDevBase(fileName) {}

		virtual bool Test() PISTON_OVERRIDE;
		virtual bool TestSomeMore(Piston::System::Module &module) PISTON_OVERRIDE;
#pragma warning(push)
#pragma warning(disable: 4265)
	};
#pragma warning(pop)

	class ProfileDev PISTON_SEALED : public ProfileDevBase {
	public:
		ProfileDev() {}
		ProfileDev(const wchar_t *fileName) : ProfileDevBase(fileName) {}

		virtual bool Test() PISTON_OVERRIDE;
		virtual bool TestSomeMore(Piston::System::Module &module) PISTON_OVERRIDE;
#pragma warning(push)
#pragma warning(disable: 4265)
	};
#pragma warning(pop)

	class ProfileVideo PISTON_SEALED : public ProfileDevBase {
	public:
		ProfileVideo() {}
		ProfileVideo(const wchar_t *fileName) : ProfileDevBase(fileName) {}

		virtual bool Test() PISTON_OVERRIDE;
		virtual bool TestSomeMore(Piston::System::Module &module) PISTON_OVERRIDE;
#pragma warning(push)
#pragma warning(disable: 4265)
	};
#pragma warning(pop)
}*/