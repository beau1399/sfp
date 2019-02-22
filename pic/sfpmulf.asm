; SFP (16-bit floating point) Multiplication Operation
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")

#include "hloe.inc"

 EXTERN loc000,loc001,loc002,loc003,loc004,loc005,loc006,loc007,loc008,loc009
 EXTERN loc010,loc011,loc012,loc013
 GLOBAL mulf
 
sfp_mul CODE
#define min loc000
#define ein loc001
#define min2 loc002
#define ein2 loc003
#define neg loc004 
#define util loc005
#define mout loc006
#define mulhi loc007
#define factor1 loc008 ;next 5 are for kmul16
#define factor2 loc009
#define make_mout loc010
#define hi_byte loc011
#define iterator loc012
#define savelsb loc013
mulf: 
 HLLOCK
 
 POP
 ;if(ein2==0x80)goto mulf_zeer1;
 banksel ein2
 movwf ein2 
 xorlw .128 ;check for 0
 btfss STATUS,Z
 goto mulf_zokr1
 movlw .127 
 
 IFDEF __16F1827
 andwf INDF0,w ;mant must be 0 or 128
 ELSE
 andwf INDF,w ;mant must be 0 or 128
 ENDIF
 
 btfsc STATUS,Z
 goto mulf_zeer1
 
mulf_zokr1: 

 ;neg=0;
 ;neg2=0;
 clrf neg 
 
 POP

 ;if(min2&0x80) neg2=1;
 banksel min2
 movwf min2 
 btfsc min2,7
 bsf neg,1 ;Z clear, bit 7 set

 ;min2&=0x7F;
 bcf min2,7 
 POP

 ;if(ein==0x80)goto mulf_zeer2;
 banksel ein
 movwf ein
 xorlw .128 ;check for 0
 btfss STATUS,Z
 goto mulf_zokr2
 movlw .127
 IFDEF __16F1827
 andwf INDF0,w ;mant must be 0 or 128
 ELSE
 andwf INDF,w ;mant must be 0 or 128
 ENDIF
 btfsc STATUS,Z
 goto mulf_zeer2
mulf_zokr2:
 POP

 ;if(min&0x80) neg=1;
 banksel min
 movwf min 
 btfsc min,7
 bsf neg,0

 ;min&=0x7F;
 bcf min,7 
 
 ; got kargs, neg mantissa flags set 
 ;W=ein;
 movfw ein 

 ;util=W;
 movwf util 

 ;W=ein2;
 movfw ein2 

 ;util+=W;
 addwf util,f 
 
 ;W=min;
 movfw min 

 ;W+=128;
 addlw .128 

 ;int temp16=mul16(W,min2+128);
 PUSH
 banksel min2
 movfw min2 
 addlw .128 
 PUSH
 goto kmul16 ;mul true mantissae 
bmul16:

 ;W=temp16/256; //Get hi byte from mul16 result
 POP

 ;*mout=W;
 banksel mout
 movwf mout 

 ;if(!(*mout&0x80)) goto no_mulf_carry ;
 btfss mout,7 
 goto no_mulf_carry 

 ;W=(temp16&255); //Get lo byte from mul16 result
 POP

 ;++util;
 banksel util
 incf util,f ;eout 
 ;ROUNDING
 andlw .128 ; Mul16's LSB still in W
 btfss STATUS,Z
 incf mout,f
 goto mulf_if1_done 
no_mulf_carry: 
 
 ;need to divide result of last mul16 
 ;by 128, not 256; this involves an 
 ;organized call to rlf to shift the 
 ;data left by one bit. 

 ;bool C=0;
 bcf STATUS,C ;C will rotate into bottom of mout during rlf 

 ;W=(temp16/256);
 POP
 banksel savelsb
 movwf savelsb
 
 ;if(W&128) C=1;
 andlw .128 
 btfss STATUS,Z 
 bsf STATUS,C ;nonzero - top bit of LSB is 1 
 ; *mout*=2;
 ; *mout|=C;
 banksel mout
 rlf mout,f 
 ;ROUNDING 
 
 ; Get LSB of mul16
 movf savelsb,w
 banksel mout
 andlw .64
 btfss STATUS,Z
 incf mout,f
 ;
mulf_if1_done: 

 ;W=*mout;
 movfw mout ;clear implicit portion of mantissa 

 ;W-=128;
 addlw -.128 

 ;*mout=W;
 movwf mout 
 btfsc neg,0
 goto ita22nq ;neg1 set, escape..
 btfss neg,1
 goto mul_sames ;both clear
 goto mul_dif5 ;(!neg1) && neg2
ita22nq: ;neg1 set
 btfsc neg,1
 goto mul_sames ;both set
mul_dif5: 

 ;W=*mout;
 movfw mout 

 ;W|=128;
 iorlw .128 

 ;*mout=W;
 movwf mout 
mul_sames: 

 ;W=*mout;
 movfw mout 

 ;*mout=W;
 PUSH

 ;*eout=util;
 banksel util
 movfw util ;eout 
 PUSH
 goto reto9k ;ret urn;
mulf_zeer1: ;first exponent parms is -128
 POP
 POP
mulf_zeer2:
 POP

 ;*eout=*mout=128;
 movlw .128
 PUSH
 PUSH

 ;ret urn;
reto9k:
 HLUNLOCK
 return
 ; 
 ; kmul16 - 8*8 -> 16bits W/ RPI method
 ; 
kmul16: 
 POP
 banksel factor1
 movwf factor1
 POP
 banksel factor2
 movwf factor2

 ; hi_byte=0;
 clrf hi_byte

 ; make_mout=0; 
 clrf make_mout

 ; iterator=0; //Iterative loop counter 0...7
 clrf iterator

bptz2:

 ; if(!(real_min&1)) goto nyyu11;
 btfss factor1,0
 goto nyyu11

 ; C=((int)make_mout+(int)factor2>255);
 ; make_mout+=factor2;
 movfw factor2
 addwf make_mout,f

 ; if(C) ++hi_byte;
 btfsc STATUS,C
 incf hi_byte,f

nyyu11:

 ; real_min/=2;
 bcf STATUS,C
 rrf factor1,f

 ; c1=hi_byte&1;
 ; hi_byte/=2;
 bcf STATUS,C
 rrf hi_byte,f

 ; C=make_mout&1;
 ; make_mout/=2;
 ; if(!c1) goto chri8;
 ; make_mout|=128;
 ;chri8:
 rrf make_mout,f

 ;
 ; /*
 ; Carries out of make_mout (result hi byte) go into
 ; to top of real_min (the determiner); why does this
 ; work? The value of the carry out of make_mout just 
 ; happen to have the necessary value.
 ; */
 ; if(!C) goto bbybm; 
 ; 
 ; real_min|=128;
 ;bbybm:
 ;
 btfsc STATUS,C
 bsf factor1,7 

 ; iterator++;
 incf iterator,f

 ; if(iterator<8) goto bptz2;
 movlw .8
 xorwf iterator,w
 btfss STATUS,Z
 goto bptz2

 ; push lo byte of result
 movfw factor1 
 PUSH

 ; push hi byte of result
 banksel make_mout
 movfw make_mout
 PUSH
 goto bmul16 ;FASTCALL quasi-ret urn

#undefine min 
#undefine ein 
#undefine min2 
#undefine ein2 
#undefine neg 
#undefine util 
#undefine mout 
#undefine mulhi 
#undefine factor1 
#undefine factor2 
#undefine make_mout 
#undefine hi_byte 
#undefine iterator 
#undefine savelsb 
 end
