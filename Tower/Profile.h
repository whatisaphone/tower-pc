#pragma once

#include "Piston\Collection.h"

#include "ProfileDev.h"

namespace Tower {
	class Profile {
	private:
		Profile(const Profile &copy);
		Profile &operator=(const Profile &copy);

	public:
		static Profile *Current;

		Profile() : RamInit(0), RamSize(0) {}

		int RamInit; // 0=zeros, 1=random, 2=close to reality, 3=#UDs
		unsigned long RamSize;

		Piston::Collection<ProfileDev> Devs;
	};
}