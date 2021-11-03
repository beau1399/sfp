
PUSH macro ;Push to the main stack for the programmer's parms and dyn. data;
 incf FSR,f ; The "incf" op serves as an allocator; it happens first so that interrupting
 movwf INDF ; code of any sort will not overwrite the data. 
 endm

POP macro ;Pop from main stack; "decf" is the de-allocator and thus happens last to 
 movfw INDF ; preserve the safety of this code under interruptible conditions. 
 decf FSR,f 
 endm

DISCARD macro ;Remove items from the main stack and throw them away w/o affecting W
 decf FSR,f 
 endm

COPY macro ;Duplicate stack top
 movfw INDF
 incf FSR,f 
 movwf INDF 
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

HLKRNPOP macro ;Pops from second stack to W; more complex than POP; must swap FSR ptr.
 HLLOCK ;NOT REENTRANT 
 bankisel alt_stack
 banksel hloe3 ;Save user stack ptr
 movfw FSR 
 movwf savesp 
 movfw alt_fsr ;Get second stack ptr 
 movwf FSR 
 movfw INDF ;Dereference it 
 decf FSR,f ;Decrement it 
 movwf hloe3 ;Save popped value for ret urn 
 movfw FSR ;Save second stack ptr 
 movwf alt_fsr 
 movfw savesp ;Restore user stack ptr 
 movwf FSR 
 clrf savesp ; allows ISR to discern whether savesp is valid
 movfw hloe3 ;Bring back popped value for ret urn 
 bankisel stack
 HLUNLOCK
 endm
 
HLKRNPSH macro ;Push to second stack rom W
 HLLOCK ;NOT REENTRANT
 banksel hloe3 ;hloe3 holds parm value being pushed
 movwf hloe3 
 movfw FSR 
 banksel savesp 
 movwf savesp 
 movfw alt_fsr 
 movwf FSR 
 bankisel alt_stack
 movfw hloe3 
 incf FSR,f ;The actual kernel push... preincrement for interrupt safety
 movwf INDF 
 movfw FSR 
 movwf alt_fsr 
 movfw savesp 
 movwf FSR 
 clrf savesp ; allows ISR to discern whether savesp is valid
 bankisel stack
 HLUNLOCK
 endm
 
PREEMPT macro
#ifdef HLMULTITASK 
 movwf W_Save ; save context- save W in "W_save" file reg.
 ;From datasheet... save STATUS properly
 SWAPF STATUS,W 
 CLRF STATUS 
 MOVWF STATUS_Save 
 movf FSR,w 
 movwf FSR_Save 
 movf PCLATH,w ; save status in "STATUS_Save" file reg.
 movwf PC_Save 
 movf alt_fsr,w 
 movwf ALT_Save
 incf in_isr,f
 pagesel ISR
#endif 
 endm
RESUME macro
 
#ifdef HLMULTITASK 
 clrf in_isr
 movf ALT_Save,w
 movwf alt_fsr 
 movf PC_Save,w ; restore context (W and STATUS)
 movwf PCLATH
 movf FSR_Save,w 
 movwf FSR
 ;Per the datasheet...
 SWAPF STATUS_Save,W
 MOVWF STATUS ;Move W into Status reg
 SWAPF W_Save,F ;Swap W_TEMP
 SWAPF W_Save,W ;Swap W_TEMP into W
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
 addwf INDF,w 
 decf FSR,f
 btfsc STATUS,C ; Necess. b/c writes to PCL take 5 bits fr. PCLATH
 incf PCLATH,f 
 movwf PCL 
mmnme#v(2): 
 ;retlw K, retlw K, etc. go here
 endm
 