#include <stdio.h>
#include <stdlib.h>
#include <sys/io.h>

int main(int argc, char *argv[])
{
	int master, slave;
	int m, s;

	if (argc != 3) {
		fputs("syntax: set8259priorities master slave\n", stderr);
		return 3;
	}
	master = atoi(argv[1]);
	if (master < 0 || master > 7) {
		fputs("master top priority device not between 0 and 7\n", stderr);
		return 2;
	}
	slave = atoi(argv[2]);
	if (slave < 8 || slave > 15) {
		fputs("slave top priority device not between 8 and 15\n", stderr);
		return 2;
	}

	if (iopl(3) < 0) {
		perror("cannot get i/o privileges");
		return 1;
	}

	/* calculate bottom priority interrupt levels */
	master = (master - 1) & 7;
	slave = (slave - 8 - 1) & 7;

	/* OCW2, R = 1, SL = 1 */
	outb_p(0xc0 | master, 0x20);
	outb_p(0xc0 | slave, 0xa0);

	printf("i8259 interrupt priorities:");
	m = (master + 1) & 7;
	for (;;) {
		if (m != 2)
			printf(" %d", m);
		else {
			s = (slave + 1) & 7;
			for (;;) {
				printf(" %d", s + 8);
				if (s == slave)
					break;
				s = (s + 1) & 7;
			}
		}
		if (m == master)
			break;
		m = (m + 1) & 7;
	}
	putchar('\n');

	return 0;
}
