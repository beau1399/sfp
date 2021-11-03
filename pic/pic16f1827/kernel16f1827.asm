;
; Stack-based integer math and I/O
;
; (c)2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#define HLOE_KERNEL_INC 1 ;File level macro allows selective preprocessing in HLOE.INC &c

#include "hloe.inc"
 ;FUNCTIONS
 GLOBAL printch,printu,getch ;I/O
 GLOBAL andb,orb,andu,oru,xoru ;Logical and Bit
 GLOBAL modu,divu,add,mul,eq,geu,gti,safeadd,negti ;Math
 GLOBAL dbgstk,dbgpku ;Debug
 GLOBAL parm ;Function Call
 ;FIELDS
 GLOBAL stack,alt_stack ;absolute beginning of each stack
 GLOBAL hloe3,savesp,savesp2 ;second stack pointer (moves)
 GLOBAL W_Save, STATUS_Save, FSR_Save, in_isr ;preemption buffers and flag
 
ukernl udata ;The kernel uses a small amount of static storage 
margpi res 1 ; in cases where the functions defined below don't call
mkarg2 res 1 ; each other, then each function can use all of these vars
mkarg1 res 1 ; freely. This does mean functions that use these are not 
mdiv res 1 ; threadsafe, and are not reentrant. 
mquot res 1 
mterm res 1 
dbgg1 res .1 ;
dbgg2 res .1 ;In cases where functions defined below do call each other,
hloe1 res .1 ; then care must be taken by the developer of the kernel to
hloe2 res .1 ; avoid problematic overlap. This is not a problem for libs
hloe3 res .1 ; where cross-calling is avoided.
savesp res .1
savesp2 res .1
mdiv2 res 1 ; for SAFE DIV / MOD
mquot2 res 1 ; 
mterm2 res 1 ; 
ukrnl2 UDATA
stack res HLOE_STACK_SIZE
 
ukrnl3 UDATA 
alt_stack res HLOE_STACK2_SIZE
 
ukrshr udata_shr
W_Save res .1 ; Used to save context for interrupts
STATUS_Save res .1
FSR_Save res .1
in_isr res .1
kernel CODE
;REENTRANT
add: 
 POP
 addwf INDF0,w
 decf FSR0L,f 
 PUSH
 return
negti: ;Two's Comp. Negation
 comf INDF0,f
 incf INDF0,f
 return
 
printch:
 POP
 HLLOCK ;NOT REENTRANT
 banksel PIR1
 btfss PIR1,TXIF
 goto $-1 
 banksel TXREG
 movwf TXREG
 nop
 banksel PIR1
 btfss PIR1,TXIF
 goto $-1 
 HLUNLOCK
 return 
 
modu: 
 HLLOCK ;NOT REENTRANT
 banksel mquot 
 clrf mquot 
 POP
 banksel mdiv
 movwf mdiv 
 POP
 banksel mterm
 movwf mterm 
 movfw mdiv 
modback: 
 subwf mterm,f 
 btfss STATUS,C 
 goto modout 
 banksel mquot 
 incf mquot,f
 goto modback 
modout: 
 addwf mterm,w 
 HLUNLOCK
 PUSH
 return 
 
;REENTRANT
orb: 
 POP
 xorlw .0
 btfsc STATUS,Z
 goto zzorz1;Z set
 movlw .1
 movwf INDF0
 return
zzorz1: ;Z set
 POP
 xorlw .0
 btfsc STATUS,Z
 goto zzorz2;Z set
 movlw .1
 PUSH
 return
zzorz2: ;Z set 
 movlw .0
 PUSH
 return
 
andb: 
 goto mul
 
 ;REENTRANT
xoru: 
 POP
 xorwf INDF0,w
 decf FSR0L,f 
 PUSH
 return
 
;REENTRANT
oru: 
 POP
 iorwf INDF0,w
 decf FSR0L,f 
 PUSH
 return
 
;REENTRANT
andu: 
 POP
 andwf INDF0,w
 decf FSR0L,f 
 PUSH
 return
 
 
divu:
 HLLOCK ;NOT REENTRANT
 banksel mquot 
 clrf mquot
not_at_max:
 POP
 banksel mdiv
 movwf mdiv
 POP
 banksel mterm
 movwf mterm
 movfw mdiv
divback:
 subwf mterm,f 
 btfss STATUS,C 
 goto divout 
 incf mquot,f
 goto divback
divout:
 movf mquot,w
 PUSH
 HLUNLOCK
 return
 
printu:
 HLLOCK ;NOT REENTRANT
 POP
 banksel margpi
 movwf margpi
 PUSH
 movlw .100 
 PUSH
 call divu
 POP
 addlw '0' 
 PUSH
 call printch
 banksel margpi
 movfw margpi
 PUSH
 movlw .100 
 PUSH
 call modu
 movlw .10
 PUSH
 call divu
 POP
 addlw '0' 
 PUSH
 call printch
 banksel margpi
 movfw margpi
 PUSH
 movlw .10 
 PUSH
 call modu
 POP
 addlw '0' 
 PUSH
 call printch
 HLUNLOCK
 return
 
; Debugging routines
;REENTRANT
;Peek at top of stack (top byte interpreted as type U)
dbgpku:
 COPY
 movlw .13
 PUSH
 call printch
 movlw .10
 PUSH
 call printch
 movlw 'U'
 PUSH
 call printch
 call printu
 return
 
;REENTRANT
dbgstk:
 movlw '@'
 PUSH
 call printch
 movfw FSR0L
 PUSH
 call printu 
 return
 
 ;REENTRANT
 ; (but blocking... this combination allows
 ; the ISR to do something else while input
 ; is awaited in an interruptable main loop)
getch:
 banksel PIR1
geth2: 
 btfss PIR1,RCIF
 goto geth2
 bcf PIR1,RCIF
 banksel RCREG
 movf RCREG,w
 PUSH 
 return

;REENTRANT
eq: 
 POP 
 xorwf INDF0,w
 movlw .1 
 btfss STATUS,Z
 movlw .0 
 decf FSR0L,f 
 PUSH 
 return
 
mul: 
 POP
 HLLOCK ;NOT REENTRANT
 banksel mterm 
 movwf mterm 
 clrw 
; decf FSR0L,f ;peek at stack top 
mulrepeat: 
 ;bankisel stack 
 addwf INDF0,w 
 banksel mterm 
 decf mterm,f 
 btfss STATUS,Z 
 goto mulrepeat 
 decf FSR0L,f 
 HLUNLOCK
 PUSH
 return 
 
parm:
 HLLOCK ;NOT REENTRANT
 banksel savesp2
 movfw FSR0L ;save user stack ptr
 movwf savesp2
 HLKRNPOP ;base ptr in hloe2
 banksel hloe2
 movwf hloe2 
 POP
 ;Incorporate offset into working pointer
 ;banksel hloe2 
 subwf hloe2,w
 movwf FSR0L 
 movfw INDF0 ;After this, retval is in W
 ;Save Retval in mkarg1
 movwf hloe1 
 ;Fix FSR0L then push ret. val
 movf savesp2,w 
 movwf FSR0L ;restore user stack ptr...\n",target
 clrf savesp2
 decf FSR0L,f ; Account for earlier POP
 movfw hloe1 ; Push parm's return value...\n",target 
 PUSH
 ;Put base ptr back
 movf hloe2,w
 HLKRNPSH
 
 HLUNLOCK
 return
 
geu:
 POP
 HLLOCK ;NOT REENTRANT
 banksel mkarg1
 movwf mkarg1 
 POP
 subwf mkarg1,w
 btfsc STATUS,Z
 goto gzeuu4
 btfsc STATUS,C
 goto ltemkarg25
 ;mkarg2>mkarg1
gzeuu4: 
 movlw .1
 PUSH
 HLUNLOCK
 return
ltemkarg25:
 movlw .0
 PUSH
 HLUNLOCK
 return
 
safeadd:
 POP
 HLLOCK ;NOT REENTRANT
 banksel margpi 
 movwf margpi 
 clrf mkarg1
 andlw .128 ;80 hex
 btfsc STATUS,Z
 goto Tmmmy ;runs if 0 set, ie. if pos
 bsf mkarg1,0 ; means arg0 is neg
Tmmmy:
 banksel stack
 ;peek at stack top 
 movlw .128
 andwf INDF0,w
 banksel mkarg1
 btfsc STATUS,Z
 goto Tmnny
 bsf mkarg1,1 ; means mkarg1 is neg
Tmnny:
 banksel margpi
 movf margpi,w ;get 1st arg to add w/ 2nd
 banksel stack 
 addwf INDF0,w 
 decf FSR0L,f ;done peeking
 banksel mterm
 movwf mterm
 btfsc mkarg1,0
 goto ar3neg
 ;arg0 was pos
 btfsc mkarg1,1
 goto ok00
 ;both pos
 btfss mterm,7
 goto ok00
 ;result negative - not good
 goto toob31
 ;goto ok00
ar3neg:
 btfss mkarg1,1
 goto ok00
 ;both neg
 btfsc mterm,7
 goto ok00
 ;result pos - not good
 goto toob32
ok00:
 HLUNLOCK
 PUSH
 return
 ;proportional control
toob31:
 HLUNLOCK
 movlw .127 
 PUSH
 return
toob32:
 HLUNLOCK
 movlw -.128 
 PUSH
 return
 
gti:
 ;if argr > 0
 ; if argl<0 return false
 ; else stdlogic
 ;else 
 ; if argl>=0 return true
 ; else stdlogic
 POP
 HLLOCK
 banksel mkarg1
 movwf mkarg1 ;mkarg1 is right arg (argr)
 btfsc mkarg1,7
 goto yypt44
 ;argr>0
 POP
 banksel mkarg2 
 movwf mkarg2
 btfss mkarg2,7
 goto yypt65
 ;argl<0
 HLUNLOCK
 movlw .0
 PUSH
 return
yypt65: 
 ;stdlogic
 subwf mkarg1,w ;mkarg1-mkarg2 right - left
 btfsc STATUS,C ;C==0 means borrow occured, ie. mkarg2>mkarg1, i.e. left > rt
 goto lt_mkarg25
 HLUNLOCK
 movlw .1
 PUSH
 return
lt_mkarg25:
 HLUNLOCK
 movlw .0
 PUSH
 return
yypt44: ;argr<=0
 ; if argl>=0 return true
 ; else stdlogic
 POP
 banksel mkarg2 
 movwf mkarg2
 btfsc mkarg2,7
 goto yypt65
 HLUNLOCK
 movlw .1
 PUSH
 return
 
 END
