;
; Very Large Factorials - Demo of SFP Real Number Type
;
; (c)2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#include "hloe.inc"
 EXTERN stack,mulf,addf,gtf,printf,printch,iszerof,parm
 
 __config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_ON & _MCLRE_OFF & _CP_OFF & _BOR_ON & _IESO_OFF & _FCMEN_OFF)
 
Resetv code 0 
 pagesel hloego
 goto hloego

mainvars udata_shr 
tmp res .1 ; Used for functions w/ numbered pass/return, to clean up parms/push args

main code
hloego:
 banksel OSCCON 
 movlw B'01110000' ; full 8mhz internal osc 
 iorwf OSCCON,f 
 banksel TRISC
 clrf TRISC ; all LEDs (bank C) output
 banksel TRISA ;configure whole PORTA as input
 movlw .255
 movwf TRISA
 banksel SPBRG 
 movlw .34 ;34 -> ~57.6kbps@8mhz (207 for 9600bps )
 movwf SPBRG 
 banksel SPBRGH 
 movlw .0 
 movwf SPBRGH 
 banksel TXSTA 
 bcf TXSTA,SYNC ;async, i.e. timed by bits in the xmit stream 
 banksel RCSTA 
 bcf RCSTA,CREN ;serial recv
 bsf RCSTA,CREN
 bsf RCSTA,SPEN 
 banksel TXSTA 
 bsf TXSTA,TXEN ;enable TX 
 bcf TXSTA,TX9 ;we want 8 bit 
 bsf TXSTA,BRGH ;enable *64 baud generator w/o using SPBRGH 
 banksel BAUDCTL 
 bsf BAUDCTL, BRG16 
 bsf BAUDCTL, SCKP ;reverse polarity 
 banksel ANSELH 
 clrf ANSELH
 banksel ANSEL
 clrf ANSEL 
 banksel PIE1 
 bcf PIE1,RCIE 
 bcf PIE1,TXIE 
 ;Enable pull-ups
 banksel OPTION_REG 
 bcf OPTION_REG,NOT_RABPU ;¬RABPU bit off -> PU enable
 banksel WPUA
 bsf WPUA,WPUA5 
 bsf WPUA,WPUA4
 bsf WPUA,WPUA2 
 bsf WPUA,WPUA1 
 bcf WPUA,WPUA0 ;analog in
 banksel WPUB
 bsf WPUB,4 ; B5 and B7 used for ser. comm.
 bsf WPUB,6 ;
 ;comparators off
 banksel CM1CON0
 bcf CM1CON0,C1ON
 banksel CM2CON0
 bcf CM2CON0,C2ON
 banksel savesp
 clrf savesp 
 banksel savesp2
 clrf savesp2 
 bcf INTCON,INTE ;no external interrupt
 clrf INTCON ;disable IOC, all the other interrupts but timers by default
 banksel IOCA
 clrf IOCA
 banksel IOCB
 clrf IOCB
 banksel PIE1
 clrf PIE1
 banksel PIE2
 clrf PIE2
 clrf in_isr
 movlw stack-1 ;Set stack starting position based on literals det. by incremental linker
 movwf FSR 
 movlw alt_stack-1
 movwf alt_fsr 
 bankisel stack
 pagesel hlluserprog
 goto hlluserprog
hllupuser CODE
hlluserprog: 
 movlw .13
 PUSH
 FAR_CALL hlluserprog,printch
 movlw .10
 PUSH
 FAR_CALL hlluserprog,printch
 FAR_CALL hlluserprog,longfact
hllprogend:
 goto hllprogend
hllt450 CODE
longfact:
 movlw .8 
 PUSH
 movlw .5 
 PUSH
 FAR_CALL longfact,fact
 FAR_CALL longfact,printf
 pagesel longfact
 goto longfact 
 return
hllt451 CODE
fact:
 movf FSR,w
 HLKRNPSH
 movlw .0 
 PUSH
 movlw .128 
 PUSH
 movlw .1
 PUSH
 FAR_CALL fact,parm
 movlw .0
 PUSH
 FAR_CALL fact,parm
 FAR_CALL fact,build
 FAR_CALL fact,mulstr
 HLKRNPOP
 HLLOCK
 movwf tmp
 POP
 HLKRNPSH
 POP
 HLKRNPSH
 movfw tmp
 movwf FSR
 DISCARD 
 DISCARD 
 HLKRNPOP
 PUSH
 HLKRNPOP
 PUSH
 HLUNLOCK
 return
hllt452 CODE
build:
 movf FSR,w
 HLKRNPSH
 movlw .32 
 PUSH
 movlw .1 
 PUSH
 movlw .1
 PUSH
 FAR_CALL build,parm
 movlw .0
 PUSH
 FAR_CALL build,parm
 FAR_CALL build,gtf
 POP
 xorlw .0
 btfsc STATUS,Z
 goto hlllb51J5 
 goto hlllb51J6
hlllb51J5:
 movlw .1
 PUSH
 FAR_CALL build,parm
 movlw .0
 PUSH
 FAR_CALL build,parm
 movlw .128 
 PUSH
 movlw .0 
 PUSH
 FAR_CALL build,addf
 HLKRNPOP
 pagesel build
 goto build 
hlllb51J6:
 HLKRNPOP
 return
hllt455 CODE
mulstr:
 movf FSR,w
 HLKRNPSH
 movlw .3
 PUSH
 FAR_CALL mulstr,parm
 movlw .2
 PUSH
 FAR_CALL mulstr,parm
 FAR_CALL mulstr,iszerof
 POP
 xorlw .0
 btfsc STATUS,Z
 goto hlllb51J8 
 goto hlllb51J9
hlllb51J8:
 FAR_CALL mulstr,mulf
 HLKRNPOP
 pagesel mulstr
 goto mulstr 
hlllb51J9:
 HLKRNPOP
 return
hllprgen2:
 goto hllprgen2
 end
