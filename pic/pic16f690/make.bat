
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "target.asm" /l"target.lst" /e"target.err" /o"target.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "..\sfputof.asm" /l"sfputof.lst" /e"sfputof.err" /o"sfputof.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "..\sfpaddf.asm" /l"sfpaddf.lst" /e"sfpaddf.err" /o"sfpaddf.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "..\sfpgtf.asm" /l"sfpgtf.lst" /e"sfpgtf.err" /o"sfpgtf.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "..\sfpmulf.asm" /l"sfpmulf.lst" /e"sfpmulf.err" /o"sfpmulf.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "..\sfp.asm" /l"sfp.lst" /e"sfp.err" /o"sfp.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f690 "kernel.asm" /l"kernel.lst" /e"kernel.err" /o"kernel.o"
"C:\Program Files (x86)\Microchip\MPASM Suite\MPLink.exe" "hloe16f690.lkr" "target.o" "sfputof.o" "sfpaddf.o" "sfpgtf.o" "sfpmulf.o" "sfp.o" "kernel.o" /o"hloe.hex" /M"hloe.map" /W
