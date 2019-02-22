;
; Converts SFP 16-bit SFP Float to UINT (0-255)
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#include "hloe.inc"

 GLOBAL ftou
 EXTERN loc000,loc001,loc002,loc003

sfp_tou CODE 

#define karg1 loc000
#define karg2 loc001
#define divisor loc002
#define util loc003

;This conversion loses the fractional portion; it is not
; a rounding function. Rounding can be achieved by adding #0.5
; to the number before calling.
ftou:
 HLLOCK
 POP
 banksel karg2
 movwf karg2 ;karg2 == ein
 clrf karg1 ;util == lobyte of result
 
 ;Any negative exponent should cause return
 ; of 0. The lowest 1 return is input 128/128*2^0,
 ; so anything based on 2^-K magnitude must be a 0.
 btfss karg2,7
 goto re55zek
 POP
 goto re55zer 
re55zek:
 
 POP
 addlw .128
 banksel karg1
 movwf karg1 ;karg1 == min
 movfw karg2
 sublw .7
 movwf divisor 
 movlw high FPRollTbl3 ;exec lookup 
 movwf PCLATH 
 movlw low FPRollTbl3
 addwf divisor,w 
 btfsc STATUS,C 
 incf PCLATH,f 
 movwf PCL 

FPRollTbl3:
 goto shift0
 goto shift1
 goto shift2 
 goto shift3
 goto shift4
 goto shift5
 goto shift6
 goto shift7
 
shift7:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift6:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift5:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift4:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift3:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift2:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift1:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift0:

re55zer:
 banksel karg1
 movfw karg1 ; lesser byte
 PUSH
 
 HLUNLOCK
 return
 
 END
 
#undefine karg1
#undefine karg2
#undefine divisor
#undefine util
