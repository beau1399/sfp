;
; Basic High-Level Structures for Next Generation PIC 8-Bit Processors
;
; Copyright (c)2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

PUSH macro ;Push to the main stack for the programmer's parms and dyn. data;
 incf FSR0L,f ; The "incf" op serves as an allocator; it runs first so that interrupting
 movwf INDF0 ; code of any sort will not overwrite the data. 
 endm

POP macro ;Pop from main stack; "decf" is the de-allocator and thus happens last to 
 movfw INDF0 ; preserve the safety of this code under interruptible conditions. 
 decf FSR0L,f 
 endm

HLKRNPSH macro ;Push to the main stack for the programmer's parms and dyn. data;
 incf FSR1L,f ; The "incf" op serves as an allocator; it runs first so that interrupting
 movwf INDF1 ; code of any sort will not overwrite the data. 
 endm

HLKRNPOP macro ;Pop from main stack; "decf" is the de-allocator and thus happens last to 
 movfw INDF1 ; preserve the safety of this code under interruptible conditions. 
 decf FSR1L,f 
 endm

DISCARD macro ;Remove items from the main stack and throw them away w/o affecting W
 decf FSR0L,f 
 endm

COPY macro ;Duplicate stack top
 movfw INDF0
 incf FSR0L,f 
 movwf INDF0 
 endm

FAR_CALL macro caller_os,func_os ;Call destination residing within a different code page
 pagesel func_os
 call func_os
 pagesel caller_os
 endm

HLLOCK macro ;Serves to establish a critical section where interrupts are disabled
#ifdef HLMULTITASK 
 bcf INTCON,GIE
 incf in_isr,f
#endif 
 endm 

HLUNLOCK macro ;End critical section
#ifdef HLMULTITASK 
 decf in_isr,f
 btfsc STATUS,Z
 bsf INTCON,GIE 
#endif 
 endm

 
PREEMPT macro
#ifdef HLMULTITASK 
 incf in_isr,f
 pagesel ISR
#endif 
 endm

RESUME macro
#ifdef HLMULTITASK 
 clrf in_isr
#endif
 endm
 
; Table macro.. this followed by any series of RETLW calls
; transforms said call list into a function that takes an offset
; and returns that entry in the table (takes 1 byte, returns 1
; byte... this goes atop the HLL feature which allows generation 
; of tables. It can also go atop RETLW tables entered into assembly 
; files in a very basic fashion when doing assembly programming. In 
; either case, the overall result can be called exactly as if it were any 
; other HLOE function
HLTABLE macro mmnme
mmnme:
 movlw high mmnme#v(2) ; Necess. b/c writes to PCL take 5 bits fr. PCLATH
 movwf PCLATH ; and PAGESEL doesn't take care of all 5
 movlw low mmnme#v(2) ; Perform pointer arithmetic
 addwf INDF0,w 
 decf FSR0L,f
 btfsc STATUS,C ; Necess. b/c writes to PCL take 5 bits fr. PCLATH
 incf PCLATH,f 
 movwf PCL 
mmnme#v(2): 
 ;retlw K, retlw K, etc. go here
 endm
 