;
; Root File for 16-bit Float Libarary
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")
;
#include "hloe.inc"

sfpu UDATA
 GLOBAL loc000,loc001,loc002,loc003,loc004,loc005,loc006,loc007,loc008
 GLOBAL loc009,loc010,loc011,loc012,loc013,loc014,loc015,loc016,loc017
 
 GLOBAL iszerof,printf,dbgpkf,nextf
 EXTERN printch,divu,modu
 
loc000 res .1
loc001 res .1
loc002 res .1
loc003 res .1
loc004 res .1
loc005 res .1
loc006 res .1
loc007 res .1
loc008 res .1
loc009 res .1
loc010 res .1
loc011 res .1
loc012 res .1
loc013 res .1
loc014 res .1
loc015 res .1
loc016 res .1
loc017 res .1 

sfp_iszero CODE
iszerof: 
 POP
 xorlw 0x80 
 btfss STATUS,Z 
 goto nonzf 
 POP
 andlw .127
 xorlw .0 
 btfss STATUS,Z 
 goto nonzg
 movlw .1 
 goto nonzr
nonzf: 
 IFDEF __16F1827
 decf FSR0L,f 
 ELSE
 decf FSR,f 
 ENDIF
nonzg:  
 movlw .0 
nonzr:  
 PUSH
 return 

sfp_next CODE
nextf:
 POP ;exponent
 banksel loc001 
 movwf loc001
 POP ;mantissa
 banksel loc000
 movwf loc000
 andlw .127
 xorlw .127
 btfss STATUS,Z 
 goto m0r33n
 banksel loc000
 movfw loc000
 andlw .128
 movwf loc000
 banksel loc001 
 incf loc001,f
 goto m0r34d   
m0r33n:
 banksel loc000
 incf loc000,f
m0r34d:
 banksel loc000
 movfw loc000
 PUSH
 banksel loc001
 movfw loc001
 PUSH
 return
  
printf: 
 HLLOCK ;NOT REENTRANT
 POP
 banksel loc001 
 movwf loc001
 POP
 banksel loc000
 movwf loc000
 movlw '(' 
 PUSH
 FAR_CALL printf,printch 
 banksel loc000
 ;movfw loc000 
 movlw '+' 
 btfss loc000,7 
 goto nomin
 banksel loc000
 movfw loc000
 andlw .127 
 movwf loc000 
 movlw '-' 
nomin: 
 PUSH
 FAR_CALL printf, printch 
 banksel loc000
 movfw loc000
 addlw .128 
 movwf loc000 
 movfw loc000 
 PUSH
 movlw .100 
 PUSH
 FAR_CALL printf, divu 
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 banksel loc000
 movfw loc000
 PUSH
 movlw .100 
 PUSH
 FAR_CALL printf, modu 
 movlw .10 
 PUSH
 FAR_CALL printf, divu 
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 ;push m 
 banksel loc000 
 movfw loc000 
 PUSH
 movlw .10 
 PUSH
 FAR_CALL printf, modu 
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 movlw '/' 
 PUSH
 FAR_CALL printf, printch 
 movlw '1' 
 PUSH
 FAR_CALL printf, printch 
 movlw '2' 
 PUSH
 FAR_CALL printf, printch 
 movlw '8' 
 PUSH
 FAR_CALL printf, printch 
 movlw ')' 
 PUSH
 FAR_CALL printf, printch 
 movlw '*' 
 PUSH
 FAR_CALL printf, printch 
 movlw '2' 
 PUSH
 FAR_CALL printf, printch 
 movlw '^' 
 PUSH
 FAR_CALL printf, printch 
 banksel loc001 
 ;movfw loc001 
 movlw '+' 
 btfss loc001,7 
 goto nomin2 
 banksel loc001 
 movfw loc001 
 xorlw .255 
 addlw .1
 movwf loc001 
 movlw '-' 
nomin2: 
 PUSH
 FAR_CALL printf, printch 
 ;push e 
 banksel loc001 
 movfw loc001 
 PUSH
 movlw .100 
 PUSH
 FAR_CALL printf, divu 
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 ;push e 
 banksel loc001 
 movfw loc001 
 PUSH
 movlw .100 
 PUSH
 FAR_CALL printf, modu 
 movlw .10 
 PUSH
 FAR_CALL printf, divu 
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 ;push e 
 banksel loc001 
 movfw loc001 
 PUSH
 movlw .10 
 PUSH
 FAR_CALL printf, modu
 FAR_CALL printf, ascii 
 FAR_CALL printf, printch 
 movlw ' '
 PUSH
 FAR_CALL printf, printch 
 HLUNLOCK 
 return 
 
dbgpkf:
 HLLOCK ;NOT REENTRANT - uses static storage
 ;copy stack top float 
 POP
 banksel loc002
 movwf loc002
 POP
 banksel loc003
 movwf loc003
 banksel loc003 ;Push the result
 movfw loc003
 PUSH
 ;
 banksel loc002 
 movfw loc002
 PUSH
 banksel loc003 ;Push the result
 movfw loc003
 PUSH
 ;
 banksel loc002
 movfw loc002
 PUSH
 movlw .13
 PUSH
 FAR_CALL dbgpkf, printch
 movlw .10
 PUSH
 FAR_CALL dbgpkf, printch
 movlw 'F'
 PUSH
 FAR_CALL dbgpkf, printch
 movlw ':'
 PUSH
 FAR_CALL dbgpkf, printch
 FAR_CALL dbgpkf, printf
 HLUNLOCK
 return

 ;REENTRANT
ascii:
 POP
 addlw '0' 
 PUSH
 return
 
 END