;
; SFP (16-bit floating point) Comparison Operation
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#include "hloe.inc"

 EXTERN loc000,loc001,loc002,loc003,loc004,loc005,in_isr
 GLOBAL gtf
sfp_gt CODE
#define neg loc000
#define neg2 loc001 ;No real need for a bit field since this method uses little RAM
#define karg1 loc002
#define karg2 loc003
#define karg3 loc004
#define karg4 loc005
gtf: 
 HLLOCK ;NOT REENTRANT
 ;parms get pushed as
 ; min ein min2 ein2
 ; 
 ; ret urns 1 if min/ein > min2/ein2
 ;ein=karg2 
 ;ein2=karg4 
 ;min=karg1 
 ;min2=karg3 
 
 POP
 banksel karg4
 movwf karg4 
 POP
 banksel karg3
 movwf karg3 
 
 POP
 banksel karg2
 movwf karg2 
 POP
 banksel karg1
 movwf karg1 
 
 ;Compare signs
 
 clrf neg 
 clrf neg2 
 btfsc karg1,7
 bsf neg,0 
 btfsc karg3,7
 bsf neg2,0 
 
 ;Change parms to abs. vals... 
 ; info about signs is in neg/neg2
 bcf karg1,7
 bcf karg3,7
 ;if neg & !neg2, ret urn false 
 btfss neg,0
 goto tsok7
 btfsc neg2,0
 goto tsok7
 movlw .0
 PUSH
 
 goto retok7
tsok7:
 ;if !neg & neg2, ret urn true
 btfsc neg,0
 goto tsok8
 btfss neg2,0
 goto tsok8
 movlw .1 
 PUSH
 
 goto retok7
tsok8:
 ;Same sign; 
 ;Compare exponents...
 ; if ein>ein2 ret urn true
 ; i.e. if karg2>karg4 ret urn true
 ;if karg4 > 0
 ; if karg2<=0 goto iiout4
 ; else goto iistl3 (stdlogic)
 ;else 
 ; if karg2>0 goto retnn
 ; else goto iiout4 (stdlogic)
 btfsc karg4,7 ;not neg then skip
 goto nxclg55
 movf karg4,f
 btfsc STATUS,Z ;not zero then skip
 goto nxclg55 
 
 movf karg2,f
 btfsc STATUS,Z
 goto iiout4
 btfsc karg2,7
 goto iiout4
 goto iistl3
 
nxclg55: ;else
 btfsc karg2,7 ;not neg then skip
 goto iiout4
 movf karg2,f
 btfsc STATUS,Z ;not zero then skip
 goto iiout4 
 goto retnn
iistl3: ;stdlogic
 movfw karg2 
 subwf karg4,w ;rt-lt
 btfsc STATUS,C ;C==0 means borrow occured, ie. mkarg2>mkarg1, i.e. left > rt
 goto iiout4
 goto retnn
iiout4: ;done w/ if
; if ein2>ein ret urn false 
 btfsc karg2,7 ;not neg then skip
 goto nzxlg55
 movf karg2,f
 btfsc STATUS,Z ;not zero then skip
 goto nzxlg55 
 
 movf karg4,f
 btfsc STATUS,Z
 goto izxut4
 btfsc karg4,7
 goto izxut4
 goto izxtl3
 
nzxlg55: ;else
 btfsc karg4,7 ;not neg then skip
 goto izxut4
 movf karg4,f
 btfsc STATUS,Z ;not zero then skip
 goto izxut4 
 goto retin

izxtl3: ;stdlogic
 movfw karg4 
 subwf karg2,w ;rt-lt
 btfsc STATUS,C ;C==0 means borrow occured, ie. mkarg2>mkarg1, i.e. left > rt
 goto izxut4
 goto retin
izxut4: ;done w/ if
 
 ;Equal exponents and signs... must compare mantissae
 ; if min>min2 ret urn (!neg)
 ; i.e. if karg1>karg3 ret urn !neg
 movfw karg1
 subwf karg3,w
 btfss STATUS,C 
 goto retnn 
 
 ; if min>min2 ret urn (!neg)
 movfw karg3
 subwf karg1,w
 btfss STATUS,C 
 goto retin
 ;equal - ret urn 0
 movlw .0 ;signs are negative.. ret 1
 PUSH
 
 goto retok7 
 
retin:
 banksel neg
 movlw .0 
 btfsc neg,0
 movlw .1 ;signs are negative.. ret 1
 PUSH
 
 goto retok7 
retnn:
 banksel neg
 movlw .0 
 btfss neg,0
 movlw .1
 PUSH
 
retok7:
 HLUNLOCK
 return 
#undefine neg 
#undefine neg2 
#undefine karg1 
#undefine karg2 
#undefine karg3 
#undefine karg4 
 end
