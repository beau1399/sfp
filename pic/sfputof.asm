;
; Converts UINT (0-255) to SFP 
;
; SFP (16-bit floating point) Multiplication Operation
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")


#include "hloe.inc"

 GLOBAL utof
 EXTERN loc000
sfp_uto CODE 
#define arg1 loc000

utof:
 HLLOCK ;NOT REENTRANT
 POP
 banksel arg1 ;Save arg
 movwf arg1
 btfss arg1,7
 goto mbww0 ;parm<128... skip down...
 
 ; parm>=128... construct a float of value [(parm-128), 7]; 
 ; this indicates a float having value [(parm-128)+128]/128 * (2^7)
 bcf arg1,7 ;This reflects the hidden bit
 movfw arg1 
 
 PUSH
 movlw .7
 PUSH
 
 goto ret101
mbww0: ;parm was <128... 
 btfss arg1,6
 goto mbww1 ;parm<64... skip down...
 ; parm<128 && parm>=64... construct a float of value [((parm-64)*2), 6]; 
 ; this indicates a float having value [((parm-64)*2)+128]/128 * (2^6)
 ;
 ; (This establishes the pattern for the remainder of the function) 
 ;
 banksel arg1
 bcf arg1,6 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .6
 PUSH
 
 goto ret101
mbww1: 
 btfss arg1,5
 goto mbww2
 banksel arg1
 bcf arg1,5 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .5
 PUSH
 
 goto ret101
mbww2: 
 btfss arg1,4
 goto mbww3
 banksel arg1
 bcf arg1,4 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .4
 PUSH
 
 goto ret101
mbww3: 
 btfss arg1,3
 goto mbww4
 banksel arg1
 bcf arg1,3 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .3
 PUSH
 
 goto ret101
mbww4: 
 btfss arg1,2
 goto mbww5
 banksel arg1
 bcf arg1,2 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .2
 PUSH
 
 goto ret101
mbww5: 
 btfss arg1,1
 goto mbww6
 banksel arg1
 bcf arg1,1 ;accounted for
 bcf STATUS,C ;shift zeroes in 
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 rlf arg1,f
 movfw arg1
 PUSH
 movlw .1
 PUSH
 goto ret101
mbww6: 
 btfss arg1,0
 goto tis00
 movlw .0
 PUSH
 movlw .0
 PUSH
 
 goto ret101
tis00:
 movlw .0
 PUSH
 movlw -.128
 PUSH
 
ret101:
 HLUNLOCK
 return
#undefine arg1
 END
