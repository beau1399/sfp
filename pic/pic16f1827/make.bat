
"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "target.asm" /l"target.lst" /e"target.err" /o"target.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "..\sfputof.asm" /l"sfputof.lst" /e"sfputof.err" /o"sfputof.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "..\sfpaddf.asm" /l"sfpaddf.lst" /e"sfpaddf.err" /o"sfpaddf.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "..\sfpgtf.asm" /l"sfpgtf.lst" /e"sfpgtf.err" /o"sfpgtf.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "..\sfpmulf.asm" /l"sfpmulf.lst" /e"sfpmulf.err" /o"sfpmulf.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "..\sfp.asm" /l"sfp.lst" /e"sfp.err" /o"sfp.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPAsmWin.exe" /w1 /q /p16f1827 "kernel16f1827.asm" /l"kernel16f1827.lst" /e"kernel16f1827.err" /o"kernel16f1827.o"

"C:\Program Files (x86)\Microchip\MPASM Suite\MPLink.exe" "hloe16f1827.lkr" "target.o" "sfputof.o" "sfpaddf.o" "sfpgtf.o" "sfpmulf.o" "sfp.o" "kernel16f1827.o" /o"hloe.hex" /M"hloe.map" /W
