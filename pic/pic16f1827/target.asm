;
; Very Large Factorials - Demo of SFP Real Number Type
;
; (c)2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#include "hloe.inc"
 EXTERN stack,mulf,addf,gtf,printf,printch,iszerof,parm
 __config _CONFIG1,_WDTE_OFF & _BOREN_OFF & _FOSC_INTOSC & _PWRTE_OFF & _MCLRE_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF
 __config _CONFIG2,_PLLEN_ON & _STVREN_ON

Resetv code 0 
 pagesel hloego
 goto hloego

mainvars udata_shr 
tmp res .1 ; Used for functions w/ numbered pass/return, to clean up parms/push args

main code
hloego:

 banksel OSCCON 
 movlw B'01110000' ; full 32mhz internal osc 
 iorwf OSCCON,f 
 movlw B'11110111' 
 andwf OSCCON,f 
 banksel TRISA ;configure whole PORTA as input
 movlw .255
 movwf TRISA
 bcf TRISA,1 ;A1 is a DO
 banksel TRISB ;B5 is not an input (RS232 TX)
 movlw .255-.32 
 andwf TRISB,f
 bsf TRISB,2 ;B2 is input (ser rcv)
 banksel ANSELB ;Nor is B5 analog
 bcf ANSELB,5
 ;UART SETUP
 banksel TXSTA
 bsf TXSTA,BRGH 
 banksel BAUDCON
 bsf BAUDCON, BRG16
 banksel SPBRG
 movlw .68 ;;115kbps
 ; movlw .138;56.7kbps
 ; movlw .64 ;9600
 movwf SPBRG 
 banksel SPBRGH
 movlw .0 ;3 for 9600; 0 for higher bps
 movwf SPBRGH 
 banksel ANSELB ;Nor is B2 analog
 bcf ANSELB,2
 banksel TXSTA 
 bcf TXSTA,SYNC ;async, i.e. timed by bits in the xmit stream
 banksel TXSTA
 bsf TXSTA,TXEN ;enable TX 
 banksel TXSTA
 bsf TXSTA,TXEN ;enable TX 
 bcf TXSTA,TX9 ;we want 8 bit

 banksel BAUDCON
 bsf BAUDCON, SCKP ;reverse polarity
 banksel APFCON1
 bsf APFCON1,TXCKSEL ;TX on pin RB5
 banksel APFCON0
 bsf APFCON1,RXDTSEL ;RX on pin RB2
 banksel RCSTA
 bsf RCSTA,SPEN 
 ;CREN equals one to receive serial data
 bcf RCSTA,CREN ;serves only to clear buffer overrun error
 bsf RCSTA,CREN
 banksel PIE1 
 bcf PIE1,RCIE 
 bcf PIE1,TXIE 
 banksel ANSELA 
 bsf ANSELA,0 ;A0 / AN0 is ANALOG IN
 banksel ANSELA 
 bsf ANSELA,2 ;A2 / AN2 is ANALOG IN
 ;comparators off
 banksel CM1CON0
 bcf CM1CON0,C1ON
 banksel CM2CON0
 bcf CM2CON0,C2ON
 bcf INTCON,INTE ;no external interrupt
 clrf INTCON ;disable IOC, all the other interrupts but timers by default
 clrf in_isr
 movlw LOW (stack-1) ;Set up stack starting position based on literals det. by linker
 movwf FSR0L 
 movlw HIGH (stack-1)
 movwf FSR0H
 movlw LOW (alt_stack-1)
 movwf FSR1L
 movlw HIGH (alt_stack-1)
 movwf FSR1H
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
 movf FSR0L,w
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
 movwf FSR0L
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
 movf FSR0L,w
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
 movf FSR0L,w
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
