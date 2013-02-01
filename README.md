Tower is an x86 PC emulator. From memory, it was able to run most real-mode operating systems I tried, including Windows 2.x and 3.x in real mode (with graphical glitches due to inaccuracies in the VGA code). It also runs [Scorched Earth][se], which used to be my favorite game.

The code is 5 or 10 years old and was written over the course of 1-2 weeks after I got my wisdom teeth removed and couldn't eat or leave the house. It's a crazy mess with hardcoded paths and overly-clever preprocessor drivel and no clear build process, but it exists and it works (worked?), so it's worth sharing. I amassed tons of old hardware documentation, which is stored in the `docs` directory and somewhat organized by component. There is also a collection of disk images containing OSs of varying obscurity, stored in `testsuite`.

[se]: http://en.wikipedia.org/wiki/Scorched_Earth_%28video_game%29
