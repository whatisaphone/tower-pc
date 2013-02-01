#if CPU < X86_386
	#define CPUBITS 16
	#define PICK_CPUBITS(x, y) x
#else
	#define CPUBITS 32
	#define PICK_CPUBITS(x, y) y
#endif

#if A_O == 1616
	#define ADSIZE 16
	#define OPSIZE 16
	#define PICK_ADSIZE(x, y) x
	#define PICK_OPSIZE(x, y) x
#elif A_O == 3216
	#define ADSIZE 32
	#define OPSIZE 16
	#define PICK_ADSIZE(x, y) y
	#define PICK_OPSIZE(x, y) x
#elif A_O == 1632
	#define ADSIZE 16
	#define OPSIZE 32
	#define PICK_ADSIZE(x, y) x
	#define PICK_OPSIZE(x, y) y
#elif A_O == 3232
	#define ADSIZE 32
	#define OPSIZE 32
	#define PICK_ADSIZE(x, y) y
	#define PICK_OPSIZE(x, y) y
#else
	#error need A_O
#endif

#define X_(x) CONCAT(X86_, CPU) ## _ ## x
#define XA_(x) CONCAT(X86_, CPU) ## CONCAT(_real, ADSIZE) ## _ ## x
#define XAO_(x) CONCAT(X86_, CPU) ## CONCAT(_real, ADSIZE) ## CONCAT(OPSIZE, _) ## x
#define AO_(x) CONCAT(real, ADSIZE) ## CONCAT(OPSIZE, _) ## x
#define XAOi_(x) XAO_(i_)##x
#define Xi__(x) X_(i__)##x
#define XAOi__(x) XAO_(i__)##x

#define intCPU PICK_CPUBITS(int16, int32)
#define intOP CONCAT(int, OPSIZE)
#define sintOP CONCAT(sint, OPSIZE)
#define intAD CONCAT(int, ADSIZE)