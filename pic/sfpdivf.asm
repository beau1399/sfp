;
; 16-bit Float Divide and Power (2^X) Functions
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL");

#include "hloe.inc"

 EXTERN loc000,loc001,loc002,loc003,loc004,loc005,loc006,loc007,loc008
 EXTERN loc009,loc010,loc011,loc012,loc013,loc014,loc015,loc016,loc017
 
 GLOBAL divf

sfp_div CODE 

#define min loc000
#define ein loc001
#define min2 loc002
#define ein2 loc003
#define neg loc004 
#define util loc005
#define mout loc006
#define multiplier loc007
#define exam loc008
#define term loc009
#define quotient_lo loc010
#define subtrahend loc011
#define min2_lower loc012
#define run_total loc013
#define loop_count loc014
#define a_hi_msb loc015
#define big_c loc016
#define rounded loc017

; Domain considerations for DIVF:
;
;(~Ends of range of type)
; (just less than) 2^128 = 340282366920938463463374607431760000000 /3.4*10^38 
; 2^-128 ~= 2.9e-39
; .0000000000000000000000000000000000000029
;
; Any parameters that would give an out-of-range answer are excluded from the domain of 
; _divf.
; For example, 2^127 divided by 2^-128 is excluded from the domain along with all other 
; combinations yielding inexpressibly large or small numbers. The behavior of such calls
; is not defined for _divf at this time.

divf: 
 HLLOCK ;NOT REENTRANT
 POP
 banksel min
 movwf ein2 
 clrf neg 
 POP

 banksel min
 movwf min2 
 btfsc min2,7
 bsf neg,1
 bcf min2,7 

 POP

 banksel min
 movwf ein 

 POP

 banksel min
 movwf min 
 btfsc min,7
 bsf neg,0 
 bcf min,7 ;got kargs, neg mantissa flags set 
 movfw ein ;ein is the term parm's exp. 
 movwf util 
 movfw ein2 
 subwf util,f ;eout 

 clrf exam ;serves as LSB of numerator, starts at 0

 ;((min + 128 ) / (min2 + 128)) - 128-> (multiplier:mout)
 movfw min ;term mantissa 
 addlw .128 
 movwf min 

 movfw min2 ;denom mantissa 
 addlw .128 
 movwf min2 
 
 ; INLINE 16b / 8b => 8b DIV routine 

 ;save denominator to see if roundn necess. after loop
 movwf term 

; Restoring Division (initially, at least, w/o post-loop rounding)

; Quotient_lo=0;
 clrf quotient_lo

; subtrahend=0;
 clrf subtrahend

; min2_lower=0;
 clrf min2_lower

; run_total=0;
 clrf run_total

; loop_count=0;
 clrf loop_count

f4tp:
; if(loop_count>=16) goto f4dn;
 movf loop_count,w
 xorlw .16
 btfsc STATUS,Z
 goto f4dn

; A_hi_msb=min&(128); //check top bit
 movf min,w
 andlw .128
 movwf a_hi_msb
 
; min2_lower*=2; 
 bcf STATUS,C
 rlf min2_lower,f

; c1=run_total&128;
; run_total*=2; 
 bcf STATUS,C
 rlf run_total,f

; if(!c1) goto que4;
 btfss STATUS,C
 goto que4

; ++min2_lower;
 incf min2_lower,f

que4:

; min*=2;
 bcf STATUS,C
 rlf min,f 

; c1=Quotient_lo&128;
; Quotient_lo*=2; 
 bcf STATUS,C
 rlf quotient_lo,f

; if(!c1) goto qu5e;
; ++min;
;qu5e:
 btfsc STATUS,C
 incf min,f
 
; if(!A_hi_msb) goto nry4;
 movf a_hi_msb,f
 btfsc STATUS,Z
 goto nry4

; ++run_total;
 incf run_total,f

; if(!run_total) ++min2_lower;
 btfsc STATUS,Z
 incf min2_lower,f

nry4:

; C=min2>run_total;
 clrf big_c 
 movfw min2
 subwf run_total,w 
 btfss STATUS,C 
 bsf big_c,0 ;C==0 means borrow occured

; min2_lower-=subtrahend;
 movf subtrahend,w
 subwf min2_lower,f ;f-w i.e. min2_lower-subtrahend

; run_total-=min2;
 movf min2,w
 subwf run_total,f

; if(C) --min2_lower;
 btfsc big_c,0 
 decf min2_lower,f

; if(!(min2_lower&128)) goto ga4g0;
 btfss min2_lower,7
 goto ga4g0

; C=((int)min2+(int)run_total)>255;
 movf min2,w
 addwf run_total,w
 clrf big_c
 btfsc STATUS,C
 bsf big_c,0

; min2_lower+=subtrahend;
 movf subtrahend,w
 addwf min2_lower,f

; run_total+=min2;
 movf min2,w
 addwf run_total,f

; if(C) ++min2_lower;
 btfsc big_c,0 
 incf min2_lower,f

; Quotient_lo&=0xFE;
 movlw .254
 andwf quotient_lo,f

; goto ga5g0;
 goto ga5g0
ga4g0:

; Quotient_lo|=0x01;
 movlw .1
 iorwf quotient_lo,f
ga5g0:

; ++loop_count;
 incf loop_count,f

; goto f4tp;
 goto f4tp

f4dn:

; *mout= Quotient_lo;
 movf quotient_lo,w
 movwf mout

; quot_out_hi = (bool)(min&1);
 clrf multiplier
 btfsc min,0
 bsf multiplier,0

 ; save_denom/=2;
 bcf STATUS,C
 rrf term,f

 clrf rounded
 movfw run_total
 subwf term,w ;save_denom-run_total
 btfsc STATUS,C 
 goto fr9rh ;C, no borrow,!(save_denom<runtot)
 incf mout,f ;borrow, i.e. runtotal>term
 bsf rounded,0 
 
fr9rh:
 
; if(!quot_out_hi) goto notmult0; //(Just compiled this statement)

 movf multiplier,f
 btfsc STATUS,Z
 goto notmult0

; if(!((*mout)&1 && !rounded)) goto prpgl;
; i.e. if((mout&1 && !rounded)){
 ;First - if !mout:0 goto prpg1
 btfss mout,0
 goto prpg1

 ;2nd - if rounded goto prpg1
 btfsc rounded,0
 goto prpg1
 
; (*mout)/=2;
 bcf STATUS,C
 rrf mout,f

; (*mout)++;
 incf mout,f

; goto prpgm;
 goto prpgm

prpg1:

; (*mout)/=2;
 bcf STATUS,C 
 rrf mout,f

prpgm:

; (*mout)|=128; //This is "quot_out_hi" shifting into top of *mout
 bsf mout,7

 goto notmult1
notmult0:
 decf util,f ;compensates for answer which is expressed in 256ths not 128ths
notmult1:
 movfw mout 

retrydvif1: ;will return here rep'ly. as necess. to normalize mantissa 

 addlw -.128 
 movwf exam ; no neg mantissa 
 btfss exam,7 
 goto nodivfcarr2 ;divf carry making mantissa 
 addlw .128 ; w is mout; exam is mout-128; 
 
 decf util,f ;dec eout 
 bcf STATUS,C 

 rlf mout,f ;mout*=2
 movfw mout 
 goto retrydvif1 

nodivfcarr2: 

 movwf mout
 
 btfsc neg,0
 goto ita33nq ;neg1 set, escape..
 btfss neg,1
 goto div_sames ;both clear
 goto div_dif5 ;(!neg1) && neg2
ita33nq: ;neg1 set
 btfsc neg,1
 goto div_sames ;both set

div_dif5: 
 
 movfw mout 
 iorlw .128 
 movwf mout 

div_sames: 
 movfw mout 
 PUSH
 banksel min
 movfw util ;eout 
 PUSH
 HLUNLOCK
 return 

#undefine min 
#undefine ein 
#undefine min2 
#undefine ein2 
#undefine neg 
#undefine util 
#undefine mout 
#undefine multiplier 
#undefine exam 
#undefine term 
#undefine quotient_lo 
#undefine subtrahend 
#undefine min2_lower 
#undefine run_total 
#undefine loop_count 
#undefine a_hi_msb 
#undefine big_c 
#undefine rounded 

 sfp_pow CODE 

#define karg1 loc000
#define karg2 loc001
#define exam loc002
#define util loc003
#define neg loc004
#define totest loc005


; Domain considerations for POWF:
; Any parameter >= 128 (i.e. with an exponent of 7+) results in sfp largest
; positive value being returned. (Params. >=128 could have been deemed out-of-range.)
; Any parameter <= -128 (mant -129/128exponent 7) results in sfp smallest
; positive value being returned. 2^-128 is SFP smallest value, others could have been
; deemed out of range.
;
;(~Ends of range of type)
; (just less than) 2^128 = 340282366920938463463374607431760000000 /3.4*10^38 
; 2^-128 ~= 2.9e-39
; .00000000000000000000000000000000000000292
;
powf:
 HLLOCK ;not reentrant
 POP
 banksel karg1
 movwf karg2 ;karg2 == ein
 xorlw 0x80 
 btfss STATUS,Z 
 goto nonzpow 
 HLUNLOCK
 
 ;clean off remaining arg
 POP

 ; return 1;
 movlw .0
 PUSH
 PUSH
 return
 
nonzpow:

 POP
 banksel karg1
 movwf karg1
 clrf neg
 andlw .128
 btfss STATUS,Z
 bsf neg,0 ; negative min 
 movfw karg1
 andlw .127 ;discard sign bit of mantissa... b/c our floating point
 ;format uses a pure sign bit, vs. complementation, this
 ;is all that is necessary

 addlw .128 ;make "real" (i.e. 2's comp) mantissa
 movwf karg1 ;karg1 == min + 128 ("real" mantissa, which is 2's comp)
 
 ; if(ein<7) goto gjjm44;
 btfsc karg2,7
 goto gjjm44 ;negative
 movf karg2,f
 btfsc STATUS,Z
 goto gjjm44 ;zero
 movlw .7;positive non-zero; subtract 7 from ein, if borrow goto gjjm44
 subwf karg2,w
 btfss STATUS,C
 goto gjjm44 ;borrow occured
 
 ; if(neg)goto gjkm44; 
 btfsc neg,0
 goto gjkm44
 
 ; *mout=*eout=127;
 HLUNLOCK 
 movlw .127
 PUSH
 PUSH
 
 ; return;
 return

gjkm44:

 HLUNLOCK 
 ; *mout=0; 
 movlw .0
 PUSH
 ; *eout=-128; 
 movlw .128 
 PUSH
 
 ; return;
 return

gjjm44:
 ; if(ein>=-8)goto gjjm45; 
 ;Strategy: 8+ein, if result>=0 (not neg) then goto gjjm45 
 movlw .8
 addwf karg2,w ;OK to trash, per Primitive C; util is used instead
 movwf totest
 btfss totest,7
 goto gjjm45 ;totest>=0

 ; *mout=0;
 ; *eout=0;
 ; return;
 HLUNLOCK 
 movlw .0
 PUSH
 PUSH
 return
 
 
gjjm45:
 
 bcf STATUS,C
 ;util == lobyte of result
 clrf util
 movfw karg2
 sublw .7
 movwf exam 
 movlw high FPRollTbl4 ;exec lookup 
 movwf PCLATH 
 movlw low FPRollTbl4
 addwf exam,w 
 btfsc STATUS,C 
 incf PCLATH,f 
 movwf PCL 

FPRollTbl4:

 goto shift0b
 goto shift1b
 goto shift2b
 goto shift3b
 goto shift4b
 goto shift5b
 goto shift6b
 goto shift7b
 goto shift8b
 goto shift9b
 goto shift10b
 goto shift11b
 goto shift12b
 goto shift13b
 goto shift14b

shift15b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift14b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift13b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift12b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift11b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift10b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift9b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift8b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift7b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift6b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift5b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift4b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift3b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift2b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
shift1b:
 bcf STATUS,C 
 rrf karg1,f
 rrf util,f
 
 btfsc STATUS,C ;rounding
 incf util,f
shift0b:

; karg1 will be return exp, 2nd parm pushed

; lookup 2^(util/256), expressed in mantissa form (i.e. 0 means 128), to be ret. mantissa
; this will be a single unsigned byte; values less than 128 will
; have to be normalized by increasing karg1

 call FPCoreLook2 
 banksel karg1
 movwf util

 ; If the mantissa was negative, this has been denoted by
 ; setting neg:0 to 1. Currently, this is handled by pushing
 ; #1.0 here and then later calling divf (again based on an
 ; examination of neg)
 movf neg,f 
 btfsc STATUS,Z 
 goto dontnegate11 
 movlw .0 
 PUSH
 movlw .0
 PUSH 
 
dontnegate11:

 banksel karg1

 movfw util ; mantissa
 PUSH
 banksel karg1

 movfw karg1 
 PUSH
 banksel karg1
 
 movf neg,f 
 btfsc STATUS,Z 
 goto dontnegate2 
 
 ;There is variable overlap b/w POWF and DIVF (e.g.
 ; loc001, loc002, etc.) but this is OK since we are
 ; finished using that static storage at this point
 ; here in POWF.

 HLUNLOCK ;no harm in this here since we are done w/ static vars
 ; this is a necessary step for bookkeeping, and also
 ; has the benefit of allowing interrupts to happen
 pagesel divf
 goto divf 

dontnegate2:
 HLUNLOCK
 return

FPCoreLook2:

 movlw high FPCoreTbl2 ;exec lookup 
 movwf PCLATH 
 movlw low FPCoreTbl2 
 addwf util,w 
 btfsc STATUS,C 
 incf PCLATH,f 
 movwf PCL 
FPCoreTbl2:
 retlw .0 ;(2^0/256)/128-128 = 0.000000
 retlw .0 ;(2^1/256)/128-128 = 0.347046
 retlw .1 ;(2^2/256)/128-128 = 0.695023
 retlw .1 ;(2^3/256)/128-128 = 1.043961
 retlw .1 ;(2^4/256)/128-128 = 1.393829
 retlw .2 ;(2^5/256)/128-128 = 1.744644
 retlw .2 ;(2^6/256)/128-128 = 2.096420
 retlw .2 ;(2^7/256)/128-128 = 2.449158
 retlw .3 ;(2^8/256)/128-128 = 2.802841
 retlw .3 ;(2^9/256)/128-128 = 3.157471
 retlw .4 ;(2^10/256)/128-128 = 3.513077
 retlw .4 ;(2^11/256)/128-128 = 3.869644
 retlw .4 ;(2^12/256)/128-128 = 4.227188
 retlw .5 ;(2^13/256)/128-128 = 4.585693
 retlw .5 ;(2^14/256)/128-128 = 4.945160
 retlw .5 ;(2^15/256)/128-128 = 5.305618
 retlw .6 ;(2^16/256)/128-128 = 5.667038
 retlw .6 ;(2^17/256)/128-128 = 6.029449
 retlw .6 ;(2^18/256)/128-128 = 6.392838
 retlw .7 ;(2^19/256)/128-128 = 6.757217
 retlw .7 ;(2^20/256)/128-128 = 7.122589
 retlw .7 ;(2^21/256)/128-128 = 7.488937
 retlw .8 ;(2^22/256)/128-128 = 7.856277
 retlw .8 ;(2^23/256)/128-128 = 8.224625
 retlw .9 ;(2^24/256)/128-128 = 8.593979
 retlw .9 ;(2^25/256)/128-128 = 8.964310
 retlw .9 ;(2^26/256)/128-128 = 9.335663
 retlw .10 ;(2^27/256)/128-128 = 9.708023
 retlw .10 ;(2^28/256)/128-128 = 10.081375
 retlw .10 ;(2^29/256)/128-128 = 10.455765
 retlw .11 ;(2^30/256)/128-128 = 10.831146
 retlw .11 ;(2^31/256)/128-128 = 11.207565
 retlw .12 ;(2^32/256)/128-128 = 11.584991
 retlw .12 ;(2^33/256)/128-128 = 11.963440
 retlw .12 ;(2^34/256)/128-128 = 12.342926
 retlw .13 ;(2^35/256)/128-128 = 12.723434
 retlw .13 ;(2^36/256)/128-128 = 13.104965
 retlw .13 ;(2^37/256)/128-128 = 13.487549
 retlw .14 ;(2^38/256)/128-128 = 13.871155
 retlw .14 ;(2^39/256)/128-128 = 14.255814
 retlw .15 ;(2^40/256)/128-128 = 14.641510
 retlw .15 ;(2^41/256)/128-128 = 15.028244
 retlw .15 ;(2^42/256)/128-128 = 15.416031
 retlw .16 ;(2^43/256)/128-128 = 15.804871
 retlw .16 ;(2^44/256)/128-128 = 16.194763
 retlw .17 ;(2^45/256)/128-128 = 16.585724
 retlw .17 ;(2^46/256)/128-128 = 16.977737
 retlw .17 ;(2^47/256)/128-128 = 17.370804
 retlw .18 ;(2^48/256)/128-128 = 17.764938
 retlw .18 ;(2^49/256)/128-128 = 18.160156
 retlw .19 ;(2^50/256)/128-128 = 18.556427
 retlw .19 ;(2^51/256)/128-128 = 18.953796
 retlw .19 ;(2^52/256)/128-128 = 19.352219
 retlw .20 ;(2^53/256)/128-128 = 19.751740
 retlw .20 ;(2^54/256)/128-128 = 20.152328
 retlw .21 ;(2^55/256)/128-128 = 20.554016
 retlw .21 ;(2^56/256)/128-128 = 20.956787
 retlw .21 ;(2^57/256)/128-128 = 21.360641
 retlw .22 ;(2^58/256)/128-128 = 21.765610
 retlw .22 ;(2^59/256)/128-128 = 22.171661
 retlw .23 ;(2^60/256)/128-128 = 22.578812
 retlw .23 ;(2^61/256)/128-128 = 22.987076
 retlw .23 ;(2^62/256)/128-128 = 23.396439
 retlw .24 ;(2^63/256)/128-128 = 23.806915
 retlw .24 ;(2^64/256)/128-128 = 24.218506
 retlw .25 ;(2^65/256)/128-128 = 24.631210
 retlw .25 ;(2^66/256)/128-128 = 25.045044
 retlw .25 ;(2^67/256)/128-128 = 25.459991
 retlw .26 ;(2^68/256)/128-128 = 25.876068
 retlw .26 ;(2^69/256)/128-128 = 26.293259
 retlw .27 ;(2^70/256)/128-128 = 26.711594
 retlw .27 ;(2^71/256)/128-128 = 27.131058
 retlw .28 ;(2^72/256)/128-128 = 27.551666
 retlw .28 ;(2^73/256)/128-128 = 27.973404
 retlw .28 ;(2^74/256)/128-128 = 28.396286
 retlw .29 ;(2^75/256)/128-128 = 28.820328
 retlw .29 ;(2^76/256)/128-128 = 29.245514
 retlw .30 ;(2^77/256)/128-128 = 29.671844
 retlw .30 ;(2^78/256)/128-128 = 30.099335
 retlw .31 ;(2^79/256)/128-128 = 30.527985
 retlw .31 ;(2^80/256)/128-128 = 30.957794
 retlw .31 ;(2^81/256)/128-128 = 31.388779
 retlw .32 ;(2^82/256)/128-128 = 31.820923
 retlw .32 ;(2^83/256)/128-128 = 32.254242
 retlw .33 ;(2^84/256)/128-128 = 32.688736
 retlw .33 ;(2^85/256)/128-128 = 33.124405
 retlw .34 ;(2^86/256)/128-128 = 33.561264
 retlw .34 ;(2^87/256)/128-128 = 33.999298
 retlw .34 ;(2^88/256)/128-128 = 34.438522
 retlw .35 ;(2^89/256)/128-128 = 34.878937
 retlw .35 ;(2^90/256)/128-128 = 35.320541
 retlw .36 ;(2^91/256)/128-128 = 35.763351
 retlw .36 ;(2^92/256)/128-128 = 36.207367
 retlw .37 ;(2^93/256)/128-128 = 36.652573
 retlw .37 ;(2^94/256)/128-128 = 37.098999
 retlw .38 ;(2^95/256)/128-128 = 37.546616
 retlw .38 ;(2^96/256)/128-128 = 37.995468
 retlw .38 ;(2^97/256)/128-128 = 38.445526
 retlw .39 ;(2^98/256)/128-128 = 38.896805
 retlw .39 ;(2^99/256)/128-128 = 39.349304
 retlw .40 ;(2^100/256)/128-128 = 39.803040
 retlw .40 ;(2^101/256)/128-128 = 40.257996
 retlw .41 ;(2^102/256)/128-128 = 40.714188
 retlw .41 ;(2^103/256)/128-128 = 41.171616
 retlw .42 ;(2^104/256)/128-128 = 41.630295
 retlw .42 ;(2^105/256)/128-128 = 42.090210
 retlw .43 ;(2^106/256)/128-128 = 42.551361
 retlw .43 ;(2^107/256)/128-128 = 43.013779
 retlw .43 ;(2^108/256)/128-128 = 43.477448
 retlw .44 ;(2^109/256)/128-128 = 43.942368
 retlw .44 ;(2^110/256)/128-128 = 44.408554
 retlw .45 ;(2^111/256)/128-128 = 44.875992
 retlw .45 ;(2^112/256)/128-128 = 45.344711
 retlw .46 ;(2^113/256)/128-128 = 45.814697
 retlw .46 ;(2^114/256)/128-128 = 46.285950
 retlw .47 ;(2^115/256)/128-128 = 46.758499
 retlw .47 ;(2^116/256)/128-128 = 47.232315
 retlw .48 ;(2^117/256)/128-128 = 47.707413
 retlw .48 ;(2^118/256)/128-128 = 48.183807
 retlw .49 ;(2^119/256)/128-128 = 48.661484
 retlw .49 ;(2^120/256)/128-128 = 49.140472
 retlw .50 ;(2^121/256)/128-128 = 49.620743
 retlw .50 ;(2^122/256)/128-128 = 50.102325
 retlw .51 ;(2^123/256)/128-128 = 50.585205
 retlw .51 ;(2^124/256)/128-128 = 51.069397
 retlw .52 ;(2^125/256)/128-128 = 51.554901
 retlw .52 ;(2^126/256)/128-128 = 52.041733
 retlw .53 ;(2^127/256)/128-128 = 52.529877
 retlw .53 ;(2^128/256)/128-128 = 53.019333
 retlw .54 ;(2^129/256)/128-128 = 53.510132
 retlw .54 ;(2^130/256)/128-128 = 54.002258
 retlw .54 ;(2^131/256)/128-128 = 54.495712
 retlw .55 ;(2^132/256)/128-128 = 54.990509
 retlw .55 ;(2^133/256)/128-128 = 55.486649
 retlw .56 ;(2^134/256)/128-128 = 55.984131
 retlw .56 ;(2^135/256)/128-128 = 56.482956
 retlw .57 ;(2^136/256)/128-128 = 56.983139
 retlw .57 ;(2^137/256)/128-128 = 57.484680
 retlw .58 ;(2^138/256)/128-128 = 57.987579
 retlw .58 ;(2^139/256)/128-128 = 58.491852
 retlw .59 ;(2^140/256)/128-128 = 58.997482
 retlw .60 ;(2^141/256)/128-128 = 59.504486
 retlw .60 ;(2^142/256)/128-128 = 60.012848
 retlw .61 ;(2^143/256)/128-128 = 60.522614
 retlw .61 ;(2^144/256)/128-128 = 61.033752
 retlw .62 ;(2^145/256)/128-128 = 61.546265
 retlw .62 ;(2^146/256)/128-128 = 62.060181
 retlw .63 ;(2^147/256)/128-128 = 62.575485
 retlw .63 ;(2^148/256)/128-128 = 63.092194
 retlw .64 ;(2^149/256)/128-128 = 63.610291
 retlw .64 ;(2^150/256)/128-128 = 64.129807
 retlw .65 ;(2^151/256)/128-128 = 64.650711
 retlw .65 ;(2^152/256)/128-128 = 65.173050
 retlw .66 ;(2^153/256)/128-128 = 65.696793
 retlw .66 ;(2^154/256)/128-128 = 66.221954
 retlw .67 ;(2^155/256)/128-128 = 66.748550
 retlw .67 ;(2^156/256)/128-128 = 67.276566
 retlw .68 ;(2^157/256)/128-128 = 67.806015
 retlw .68 ;(2^158/256)/128-128 = 68.336899
 retlw .69 ;(2^159/256)/128-128 = 68.869217
 retlw .69 ;(2^160/256)/128-128 = 69.402985
 retlw .70 ;(2^161/256)/128-128 = 69.938202
 retlw .70 ;(2^162/256)/128-128 = 70.474869
 retlw .71 ;(2^163/256)/128-128 = 71.012985
 retlw .72 ;(2^164/256)/128-128 = 71.552567
 retlw .72 ;(2^165/256)/128-128 = 72.093613
 retlw .73 ;(2^166/256)/128-128 = 72.636108
 retlw .73 ;(2^167/256)/128-128 = 73.180099
 retlw .74 ;(2^168/256)/128-128 = 73.725555
 retlw .74 ;(2^169/256)/128-128 = 74.272476
 retlw .75 ;(2^170/256)/128-128 = 74.820892
 retlw .75 ;(2^171/256)/128-128 = 75.370804
 retlw .76 ;(2^172/256)/128-128 = 75.922195
 retlw .76 ;(2^173/256)/128-128 = 76.475082
 retlw .77 ;(2^174/256)/128-128 = 77.029480
 retlw .78 ;(2^175/256)/128-128 = 77.585358
 retlw .78 ;(2^176/256)/128-128 = 78.142761
 retlw .79 ;(2^177/256)/128-128 = 78.701675
 retlw .79 ;(2^178/256)/128-128 = 79.262100
 retlw .80 ;(2^179/256)/128-128 = 79.824036
 retlw .80 ;(2^180/256)/128-128 = 80.387512
 retlw .81 ;(2^181/256)/128-128 = 80.952499
 retlw .82 ;(2^182/256)/128-128 = 81.519028
 retlw .82 ;(2^183/256)/128-128 = 82.087097
 retlw .83 ;(2^184/256)/128-128 = 82.656708
 retlw .83 ;(2^185/256)/128-128 = 83.227844
 retlw .84 ;(2^186/256)/128-128 = 83.800552
 retlw .84 ;(2^187/256)/128-128 = 84.374802
 retlw .85 ;(2^188/256)/128-128 = 84.950607
 retlw .86 ;(2^189/256)/128-128 = 85.527969
 retlw .86 ;(2^190/256)/128-128 = 86.106903
 retlw .87 ;(2^191/256)/128-128 = 86.687408
 retlw .87 ;(2^192/256)/128-128 = 87.269485
 retlw .88 ;(2^193/256)/128-128 = 87.853134
 retlw .88 ;(2^194/256)/128-128 = 88.438370
 retlw .89 ;(2^195/256)/128-128 = 89.025192
 retlw .90 ;(2^196/256)/128-128 = 89.613617
 retlw .90 ;(2^197/256)/128-128 = 90.203629
 retlw .91 ;(2^198/256)/128-128 = 90.795227
 retlw .91 ;(2^199/256)/128-128 = 91.388443
 retlw .92 ;(2^200/256)/128-128 = 91.983276
 retlw .93 ;(2^201/256)/128-128 = 92.579712
 retlw .93 ;(2^202/256)/128-128 = 93.177765
 retlw .94 ;(2^203/256)/128-128 = 93.777435
 retlw .94 ;(2^204/256)/128-128 = 94.378738
 retlw .95 ;(2^205/256)/128-128 = 94.981659
 retlw .96 ;(2^206/256)/128-128 = 95.586227
 retlw .96 ;(2^207/256)/128-128 = 96.192429
 retlw .97 ;(2^208/256)/128-128 = 96.800278
 retlw .97 ;(2^209/256)/128-128 = 97.409775
 retlw .98 ;(2^210/256)/128-128 = 98.020920
 retlw .99 ;(2^211/256)/128-128 = 98.633728
 retlw .99 ;(2^212/256)/128-128 = 99.248184
 retlw .100 ;(2^213/256)/128-128 = 99.864319
 retlw .100 ;(2^214/256)/128-128 = 100.482132
 retlw .101 ;(2^215/256)/128-128 = 101.101608
 retlw .102 ;(2^216/256)/128-128 = 101.722763
 retlw .102 ;(2^217/256)/128-128 = 102.345596
 retlw .103 ;(2^218/256)/128-128 = 102.970139
 retlw .104 ;(2^219/256)/128-128 = 103.596359
 retlw .104 ;(2^220/256)/128-128 = 104.224274
 retlw .105 ;(2^221/256)/128-128 = 104.853897
 retlw .105 ;(2^222/256)/128-128 = 105.485229
 retlw .106 ;(2^223/256)/128-128 = 106.118271
 retlw .107 ;(2^224/256)/128-128 = 106.753036
 retlw .107 ;(2^225/256)/128-128 = 107.389511
 retlw .108 ;(2^226/256)/128-128 = 108.027725
 retlw .109 ;(2^227/256)/128-128 = 108.667664
 retlw .109 ;(2^228/256)/128-128 = 109.309326
 retlw .110 ;(2^229/256)/128-128 = 109.952744
 retlw .111 ;(2^230/256)/128-128 = 110.597900
 retlw .111 ;(2^231/256)/128-128 = 111.244797
 retlw .112 ;(2^232/256)/128-128 = 111.893463
 retlw .113 ;(2^233/256)/128-128 = 112.543869
 retlw .113 ;(2^234/256)/128-128 = 113.196060
 retlw .114 ;(2^235/256)/128-128 = 113.850006
 retlw .115 ;(2^236/256)/128-128 = 114.505722
 retlw .115 ;(2^237/256)/128-128 = 115.163223
 retlw .116 ;(2^238/256)/128-128 = 115.822510
 retlw .116 ;(2^239/256)/128-128 = 116.483582
 retlw .117 ;(2^240/256)/128-128 = 117.146439
 retlw .118 ;(2^241/256)/128-128 = 117.811096
 retlw .118 ;(2^242/256)/128-128 = 118.477554
 retlw .119 ;(2^243/256)/128-128 = 119.145828
 retlw .120 ;(2^244/256)/128-128 = 119.815903
 retlw .120 ;(2^245/256)/128-128 = 120.487808
 retlw .121 ;(2^246/256)/128-128 = 121.161530
 retlw .122 ;(2^247/256)/128-128 = 121.837067
 retlw .123 ;(2^248/256)/128-128 = 122.514450
 retlw .123 ;(2^249/256)/128-128 = 123.193665
 retlw .124 ;(2^250/256)/128-128 = 123.874710
 retlw .125 ;(2^251/256)/128-128 = 124.557617
 retlw .125 ;(2^252/256)/128-128 = 125.242371
 retlw .126 ;(2^253/256)/128-128 = 125.928986
 retlw .127 ;(2^254/256)/128-128 = 126.617447
 retlw .127 ;(2^255/256)/128-128 = 127.307785
 
 END
 

#undefine karg1
#undefine karg2
#undefine exam
#undefine util
#undefine neg
#undefine totest
