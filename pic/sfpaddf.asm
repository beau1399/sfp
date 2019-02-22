;
; 16-bit Float Addition
;
; Copyright (c) 2011 James Beau Wilkinson
;
; Licensed under the GNU General Public License ("Greater GPL")
;
#include "hloe.inc"
 EXTERN loc000,loc001,loc002,loc003,loc004,loc005,loc006,loc007,loc008,loc009
 EXTERN loc010,loc011,loc012,loc013,loc014,loc015,loc016,loc017
 
 GLOBAL addf
sfp_add CODE
#define min loc000
#define ein1 loc001
#define min2 loc002
#define ein2 loc003
#define neg loc004 ; bit 0 = "neg1" (means 1st arg <0) bit 1 = "neg2" (2nd arg <0)
#define util loc005
#define mout loc006
#define multiplier loc007
#define fulmin loc008
#define fulmin2 loc009
#define rev loc010
#define min_lower loc011
#define fulminH loc012
#define fulmin2H loc013
#define minres loc014
#define min2_lower loc015
#define big_c loc016
#define mout_hi loc017
 ; 
 ;void addf 
 ;(
 ; char min, char ein, 
 ; char min2, char ein2, 
 ; char * mout, char * eout 
 ;) 
 ; 
addf: 
 HLLOCK ;NOT REENTRANT
 POP
 banksel min
 movwf ein2 
 ; The assembly language implementation contains 
 ; some optimizations that a real C compiler 
 ; probably couldn't generate. A real compiler 
 ; could not be this opportunistic during parsing 
 ; of the call stack. 
 ; 
 ; if(ein2==128) {mout=min; eout=ein;} 
 ; 
 
 POP
 banksel min
 movwf min2 
 POP
 banksel min
 movwf ein1 
 ; 
 ; if(ein1==128) {mout=min2; eout=ein2;} 
 ; 
 POP
 banksel min
 movwf min 
 ; 
 ;{ 
 ; int minres=0; 
 ; 
 bcf minres,0 
 ; 
 ; *mout=0; 
 ; 
 clrf mout 
 ; 
 ; int neg,neg2,rev; 
 ;
 
 ; neg=min&128; 
 clrf neg
 btfsc min,7
 bsf neg,0
 ; 
 ; neg2=min2&128; 
 ; 
 btfsc min2,7
 bsf neg,1
;if(ein1>ein2){ 
 btfsc ein2,7 ;ein2 is right-side arg (argr) 
 goto yzpt44
 ;argr>0
 btfss ein1,7
 goto yzpt65
 ;argl<0
 goto ein_lt_ein2
yzpt65: 
 ;stdlogic
 movfw ein1
 subwf ein2,w ;ein2-ein1 
 btfss STATUS,C 
 goto ein_lt_ein1 ; C Clear means ein1>ein2 i.e. enter IF clause
lz_ein15:
 goto ein_lt_ein2 ; skip IF clause
yzpt44: ;argr<=0
 ; if argl>=0 return true
 ; else stdlogic
 btfsc ein1,7
 goto yzpt65 ; left and right args <=0; apply stdlogic (unsigned compare)
ein_lt_ein1: ; right arg <0, left arg not; enter IF clause
 
;In-place XOR-based swap
; ein=ein^ein2;
 movf ein2,w
 xorwf ein1,f
; ein2=ein^ein2;
 movf ein1,w
 xorwf ein2,f
; ein=ein^ein2;
 movf ein2,w
 xorwf ein1,f
; min=min^min2;
 movf min2,w
 xorwf min,f
; min2=min^min2;
 movf min,w
 xorwf min2,f
; min=min^min2;
 movf min2,w
 xorwf min,f
 
 ; 
 ; rev=1; 
 ; 
 bsf rev,0 
 ; 
 ; } 
 ; 
 goto ein_lt_ein2_done 
ein_lt_ein2: 
 ; 
 ; else rev=0; 
 ; 
 clrf rev 
ein_lt_ein2_done: 
 ; 
 ;//Get rid of sign bit for now 
 ;min&=127; 
 ; 
 movfw min 
 andlw .127 
 movwf min 
 ; 
 ;min2&=127; 
 ; 
 movfw min2 
 andlw .127 
 movwf min2 
 ; 
 ;int fulmin=128+min; 
 ; 
 clrf fulminH ; 16-bit integer math 
 movfw min 
 addlw .128 
 btfsc STATUS,C 
 incf fulminH,f ;carry this stmt. only.. feeling is that C=1 happens 
 ; for the large case for the "add" opcode, in contrast 
 ; to the "sub" opcode 
 movwf fulmin 
 ; 
 ;int fulmin2=128+min2; 
 ; 
 clrf fulmin2H 
 movfw min2 
 addlw .128 
 btfsc STATUS,C 
 incf fulmin2H,f ;carry this stmt. only 
 
 movwf fulmin2 
 
 ;Shift smaller exponent upward to match larger; mantissa
 ; of smaller number will shrink correspondingly, possibly
 ; to a number less than 128. This is the main reason for 
 ; the shift to 'full' mantissae, in which the hidden bit
 ; is actually reflected by a 1 in bit 7.
; min_lower=0;
 clrf min_lower
; min2_lower=0;
 clrf min2_lower
 
whi77:
; if(ein==ein2) goto eein2outw;
 movfw ein1 
 xorwf ein2,w 
 btfsc STATUS,Z 
 goto eein2outw ;SET Z
 
; min_lower/=2;
 bcf STATUS,C
 rrf min_lower,f
; C=fullmin&1; 
; fullmin/=2; 
 bcf STATUS,C
 rrf fulmin,f
; if(!C) goto nocar001;
 btfss STATUS,C
 goto nocar001
 
; min_lower|=128;
 bsf min_lower,7
nocar001:
; ein++; //No need for bounds check b/c this is
; // the smaller exponent getting incremented
 incf ein1,f
; goto whi77;
 goto whi77
 
eein2outw: 
 ; 
 ; //Undo any reversal 
 ; if(rev) 
 ; { 
 ; 
 btfss rev,0 
 goto if_2_done 
;In-place XOR-based swap 
; fullmin=fullmin^fullmin2;
 movf fulmin2,w
 xorwf fulmin,f
; fullmin2=fullmin^fullmin2;
 movf fulmin,w
 xorwf fulmin2,f
; fullmin=fullmin^fullmin2;
 movf fulmin2,w
 xorwf fulmin,f
 
; min2_lower=min_lower;
 movfw min_lower 
 movwf min2_lower 
 ;;min_lower=0;
 clrf min_lower
 
 ; 
 ; } 
 ; 
 
if_2_done: 
 
 banksel min_lower
 
 
 ; //Handle the four "species" of problem, with
 ; // respect to n eg and n eg2.
nrev0: 
; if(!neg) goto nextspeci0;
 btfss neg,0
 goto nextspeci0; ;neg[0] clear, i.e. !neg
 
; if(!neg2) goto nextspeci0;
 btfss neg,1
 goto nextspeci0; ;Z set
 
; Double n egative... set "minres" and then handle
; as if two positives
; minres=true;
 bsf minres,0
 goto nextspeci2
 
 ;;
 ; NEW SPECIES 2
 ;;
 
nextspeci0:
 
; if(!neg) goto nextspeci1;
 btfss neg,0
 goto nextspeci1 
 
rrrout0:
 ;//parm 2- parm 1 
 ;//C=fullmin>fullmin2; (actually ends up opposite on PIC C=!borrow)
 ;*mout=(fullmin2-fullmin); 
 movfw fulmin 
 subwf fulmin2,w 
 movwf mout 
 
 ; if(fullmin<=fullmin2) goto nc11rr; GOTO when no borrow, i.e. when C
 btfsc STATUS,C
 goto nc11rr ;!C
 
 ; minres=true; 
 bsf minres,0 
 
 ; goto rrrout1;
 goto rrrout1 
 
nc11rr:
 ; if(!*mout) goto specidone0;
 movf mout,f
 btfsc STATUS,Z
 goto specidone0 ;Z set
mouty:
 ; if((*mout)&128) goto nn91;
 btfsc mout,7 
 goto nn91 ;Bit 7 set
 
 
 ; (*mout)*=2;
 bcf STATUS,C
 rlf mout 
 
 ; if(!(min_lower&128)) goto yym43;
 btfss min_lower,7 
 goto yym43 ;Bit 7 clear
 ; --*mout;
 decf mout,f 
 ; if(*mout!=255) goto yym43; 
 movlw .255
 xorwf mout,w
 btfss STATUS,Z
 goto yym43 ;!=
 
 ; minres=true;
 bsf minres,0
 
 ; goto rrrout1; 
 goto rrrout1
 
; yym43:
yym43:
 ; min_lower*=2;
 bcf STATUS,C
 rlf min_lower,f 
 ; --ein;
 decf ein1,f 
 ; goto mouty;
 goto mouty 
nn91:
 ; if(!(min_lower&128)) goto trup5;
 btfss min_lower,7 
 goto trup5 ;Bit 7 clear
 
 ; --*mout;
 decf mout,f
 ; if(!(*mout==255)) goto fltu54;
 movlw .255
 xorwf mout,w
 btfss STATUS,Z
 goto fltu54 ;!=

 ; minres=true;
 bsf minres,0 
 
 ; goto rrrout1;
 goto rrrout1 
 
fltu54:
 ; if(*mout!=127) goto trup5; 
 movlw .127
 xorwf mout,w
 btfss STATUS,Z
 goto trup5 ;!=

 ; /*Undid normalization */
 ; (*mout)*=2;
 bcf STATUS,C
 rlf mout,f
 ; --ein;
 decf ein1,f 
 
 ; if((min_lower&64)) goto trup5;
 btfsc min_lower,6
 goto trup5 

 ; ++*mout;
 incf mout,f 
 
trup5:
 ; goto specidone0;
 goto specidone0; 
nextspeci1:
 
 ;"Species" 3
 ; if(!neg2) goto nextspeci2;
 btfss neg,1
 goto nextspeci2 

 ; //Arg 1 - Arg 2
rrrout1:
 ; *mout=(fullmin-fullmin2); 
 movfw fulmin2
 subwf fulmin,w 
 movwf mout 
 
 ; if(fullmin2<=fullmin) goto rmxd3;
 btfsc STATUS,C
 goto rmxd3 ;C, i.e. no borrow, i.e. fm1 >= fm2
 
 ; minres=true; 
 bsf minres,0
 
 ; goto rrrout0;
 goto rrrout0 
rmxd3:
 ; if(!*mout) goto specidone0; 
 movf mout,f 
 btfsc STATUS,Z 
 goto specidone0 ;Z set
 
moutx:
 ; if((*mout)&128) goto nn91b;
 btfsc mout,7
 goto nn91b
 
 
 ; (*mout)*=2;
 bcf STATUS,C
 rlf mout,f 
 
 ; if(!(min2_lower&128)) goto spyr5; 
 btfss min2_lower,7
 goto spyr5
 ; --*mout;
 decf mout,f 
 
 ; if(*mout!=255) goto spyr5;
 movlw .255
 xorwf mout,w
 btfss STATUS,Z
 goto spyr5 ;!=
 
 
 ; minres=true;
 bsf minres,0
 
 ; goto rrrout0;
 goto rrrout0; 
 
spyr5:
 ; min2_lower*=2;
 bcf STATUS,C
 rlf min2_lower,f
 
; --ein;
 decf ein1,f
 
 ; goto moutx;
 goto moutx 
nn91b:
 ; if(!(min2_lower&128)) goto cxaa;
 btfss min2_lower,7
 goto cxaa
 
 ; --*mout;
 decf mout,f 
 
 ; if(*mout!=255) goto iwrtt;
 movlw .255
 xorwf mout,w
 btfss STATUS,Z
 goto iwrtt ;!=
 ; minres=true;
 bsf minres,0
 
 ; goto rrrout0;
 goto rrrout0; 
iwrtt:
 ; if(*mout!=127) goto cxaa;
 movlw .127
 xorwf mout,w
 btfss STATUS,Z
 goto cxaa ;!=
 
 ; //Undid normalization 
 ; (*mout)*=2;
 bcf STATUS,C
 rlf mout,f 
 ; --ein;
 decf ein1,f 
 ; if(min2_lower&64) goto cxaa;
 btfsc min2_lower,6
 goto cxaa 
 
 
 ; ++*mout;
 incf mout,f 
 
cxaa:
 ; goto specidone0;
 goto specidone0
tpc0lea:
 ; *mout=(fullmin2-fullmin);
 movfw fulmin
 subwf fulmin2,w 
 movwf mout 
 
 ; minres=true;
 bsf minres,0 
 ; goto specidone0;
 goto specidone0
 
nextspeci2:
; //Two positives. Just add mantissae
; mout_hi=0;
 clrf mout_hi
 
; *mout=(byte)(fullmin+fullmin2); 
 movf fulmin,w
 addwf fulmin2,w
 movwf mout
 
 ; if(!(((int)fullmin+(int)fullmin2)>255)) goto cxab;
 btfss STATUS,C 
 goto cxab ;!too big, C=0
 
 ; ++mout_hi;
 incf mout_hi,f 
 
cxab:
 ; if((int)min_lower+(int)min2_lower > 255) goto bihhg; 
 movf min_lower,w
 addwf min2_lower,w
 btfsc STATUS,C
 goto bihhg ;Set C, too big
 
 
 ; if((min_lower+min2_lower)&128) goto bihhg;
 andlw .128 
 btfss STATUS,Z
 goto bihhg ;Non-zero
 
 ; goto bihh0; 
 goto bihh0 
 
bihhg:
 ; ++*mout;
 incf mout,f 
 
 ; if(*mout) goto ppmt3;
 movf mout,f
 btfss STATUS,Z
 goto bihh0 ;SIC (same thing both labels)
 ; ++mout_hi;
 incf mout_hi,f
bihh0:
 ; if(!mout_hi) goto specidone0;
 movf mout_hi,f
 btfsc STATUS,Z
 goto specidone0 
 
 ; //Terms too big; div and go back
 ; C=fullmin&1; 
 ; fullmin/=2;
 clrf big_c
 bcf STATUS,C
 rrf fulmin,f
 btfsc STATUS,C
 bsf big_c,0
 
 ; min_lower/=2;
 bcf STATUS,C
 rrf min_lower,f
 
 ; if(!C) goto ddnyy;
 btfss big_c,0
 goto ddnyy

 
 ; min_lower|=128;
 bsf min_lower,7 
 
ddnyy:
 ; C=fullmin2&1;
 ; fullmin2/=2;
 clrf big_c
 bcf STATUS,C
 rrf fulmin2,f
 btfsc STATUS,C
 bsf big_c,0
 
 ; min2_lower/=2;
 bcf STATUS,C
 rrf min2_lower,f
 
 ; if(!C) goto ddnzz;
 btfss big_c,0
 goto ddnzz
 
 ; min_lower|=128;
 bsf min_lower,7 
 
ddnzz:
 ; ++ein;
 incf ein1,f 
 
 ; goto nextspeci2;
 goto nextspeci2
specidone0:
 movfw mout 
 ; if(*mout==0) 
 ; { 
 btfss STATUS,Z 
 goto nomoutzeer 
 ; 
 ; *mout=0; 
 ; 
 movlw .0 
 PUSH
 ; 
 ; *eout=0x80; 
 ; 
 movlw 0x80 
 PUSH
 ; 
 ; ret urn; 
 ; 
 goto re455tu
 ; 
 ; } 
 ; 
nomoutzeer: 
 ; 
 ; //Take out the HB... recall that we built *mout from fullbit / fullbit2 
 ; (*mout)-=128; 
 ; 
 movfw mout
 addlw -.128 ;same as subtracting 128 
 movwf mout 
 
 ; 
 ; if(minres) (*mout)|=128; 
 ; 
 btfsc minres,0 
 bsf mout,7
 
 movfw mout 
 PUSH
 ; 
 ; *eout=ein; 
 ; 
 banksel min
 movfw ein1 
 PUSH
 
re455tu:
 HLUNLOCK
 return 
#undefine min 
#undefine ein1 
#undefine min2 
#undefine ein2 
#undefine neg 
#undefine util 
#undefine mout 
#undefine multiplier 
#undefine fulmin 
#undefine fulmin2 
#undefine rev 
#undefine min_lower 
#undefine fulminH 
#undefine fulmin2H 
#undefine minres 
#undefine min2_lower 
#undefine big_c 
#undefine mout_hi 
 END
