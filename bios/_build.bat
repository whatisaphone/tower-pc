@echo OFF
echo *********************==-   ASSEMBLING 'rombios.asm'   -==**********************
"c:\program files\nasm\nasm" -o rombios.bin -f bin -O9 -Xvc -w+macro-selfref rombios.asm
if errorlevel 1 (
	echo Assembling of 'rombios.asm' failed.
) else (
	echo Assembling of 'rombios.asm' succeeded.  Deploying...
	copy rombios.bin ..\debug
	copy rombios.bin ..\release
)
echo %%

echo *********************==-   ASSEMBLING 'vgabios.asm'   -==**********************
"c:\program files\nasm\nasm" -o vgabios.bin -f bin -O9 -Xvc -w+macro-selfref vgabios.asm
if errorlevel 1 (
	echo Assembling of 'vgabios.asm' failed.
) else (
	echo Assembling of 'vgabios.asm' succeeded.  Deploying...
	copy vgabios.bin ..\debug
	copy vgabios.bin ..\release
)
echo %%

pause