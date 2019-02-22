;
; Base-2 Logarithms for 16-bit Float
;

#include "hloe.inc"

 GLOBAL logf
 EXTERN loc000,loc001,loc002,loc003,loc004,loc005,loc006,loc007,loc008

sfp_log CODE 

#define arg1 loc000
#define karg1 loc001
#define util loc002
#define exam loc003
#define neg loc004
#define rev loc005
#define mout loc006
#define moutL loc007
#define moutH loc008

 ; 
 ; logf 
 ; 
 ; Domain is >0 to sfpmax
 ;
 ; Takes a single float, i.e. 2 bytes 
 ; 
logf: 

 ; util=ein; 
 POP
 HLLOCK ;not reentrant b/c of use of globals
 banksel arg1
 movwf util ; this is the exp; EXP == UTIL 

 ; *mout=min;
 POP
 movwf mout ;MOUT == MANTISSA

 ; // If passed 1 (0 and 0) then return log(1) i.e. 0
 ; if(*mout) goto nzmdss;
 movf mout,f
 btfss STATUS,Z
 goto nzmdss

 ; if(util) goto nzmdss;
 movf util,f
 btfss STATUS,Z
 goto nzmdss 

 ; *mout=128;
 ; *eout=-128;
 movlw .128
 PUSH
 PUSH
 HLUNLOCK

 ; return;
 return 

nzmdss:

 ; moutL=lookcore[*mout]; 
 call look_core 
 movwf moutL 

 ; moutH=lookcoreh[*mout];
 movf mout,w
 call look_core_hi
 movwf moutH 

 ; express ein as a 16-bit number

 ; neg=0;
 clrf neg
 
 ; if(!(util&128)) goto nonegtlog;
 btfss util,7
 goto nonegtlog

 ; neg|=1; 
 bsf neg,0
 
 ;util=~util;
 comf util,f ;negate to ease process of making
 
 ;util++;
 incf util,f ; 16-bit fixed point number
 
nonegtlog:

 btfsc util,7
 goto fi5tt2
 btfsc util,6
 goto fi5tt3
 btfsc util,5
 goto fi5tt4
 btfsc util,4
 goto fi5tt5
 btfsc util,3
 goto fi5tt6
 btfsc util,2
 goto fi5tt7
 btfsc util,1
 goto fi5tt8
 btfsc util,0
 goto fi5tt9
 goto fi5ttz
 
fi5tt2:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt3:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt4:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt5:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt6:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt7:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt8:
 bcf STATUS,C
 rrf moutH
 rrf moutL
fi5tt9:
 ; C=moutH&1; 
 ; moutH/=2;
 bcf STATUS,C
 rrf moutH
 
 ; c1=moutL&1;
 ; moutL/=2;
 ; if(C)moutL|=128;
 rrf moutL

 ; if(!c1)goto fi5ttz;
 btfss STATUS,C
 goto fi5ttz
 
 ; ++moutL;
 incf moutL,f
 
 ; if(moutL)goto fi5ttz;
 movf moutL,f
 btfsc STATUS,Z
 ; ++moutH;
 incf moutH,f
fi5ttz:

 ; //If neg, moutH:L should have opposite sign as well
 ; if(!neg) goto m1gd6;
 btfss neg,0
 goto m1gd6
 ; moutH=~moutH;
 comf moutH,f
 ; moutL=~moutL;
 comf moutL,f
 ; ++moutL;
 incf moutL,f
 ; if(moutL) goto m1gd6;
 btfsc STATUS,Z
 ; ++moutH;
 incf moutH,f
 m1gd6:
 
 ; if(util<128) goto gkbb11;
 btfss util,7
 goto gkbb11

 ; rev=(byte)-1;
 movlw -.1
 movwf rev

 ; moutH+=util; //256ths
 movf util,w
 addwf moutH,f

 ; goto kkbbg3;
 goto kkbbg3
 gkbb11:

 ; if(util<64) goto gkbb22;
 btfss util,6
 goto gkbb22

 ; rev=(byte)-2;
 movlw -.2
 movwf rev

 ; moutH+=util*2; //256ths
 bcf STATUS,C
 rlf util,w
 addwf moutH,f

 goto kkbbg3;
 gkbb22:
 ; if(util<32) goto gkbb33;
 btfss util,5
 goto gkbb33

 ; rev=(byte)-3;
 movlw -.3
 movwf rev

 ; moutH+=util*4; //256ths
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,w
 addwf moutH,f

 goto kkbbg3;
 gkbb33:
 ; if(util<16) goto gkbb44;
 btfss util,4
 goto gkbb44

 ; rev=(byte)-4;
 movlw -.4
 movwf rev

 ; moutH+=util*8; //256ths
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,w
 addwf moutH,f

 goto kkbbg3
 gkbb44:

 ; if(util<8) goto gkbb55;
 btfss util,3
 goto gkbb55

 ; rev=(byte)-5;
 movlw -.5
 movwf rev

 ; moutH+=util*16; //256ths TODO easier ways here?
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,w
 addwf moutH,f
 goto kkbbg3
 gkbb55:

 ; if(util<4) goto gkbb66;
 btfss util,2
 goto gkbb66

 ; rev=(byte)-6;
 movlw -.6
 movwf rev

 ; moutH+=util*32; //256ths
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,f
 bcf STATUS,C
 rlf util,w
 addwf moutH,f
 goto kkbbg3

 gkbb66:
 
 ; if(util<2) goto gkbb77;
 btfss util,1
 goto gkbb77

 ; rev=(byte)-7;
 movlw -.7
 movwf rev

 ; if(!(util&2)) goto ncrre;
 ; moutH+=128;
 btfss util,1
 goto ncrre
 movlw .128
 addwf moutH,f
 
 ;ncrre:
 ; if(!(util&1)) goto kkbbg3;
 ; moutH+=64; 
ncrre: 
 btfss util,0
 goto kkbbg3
 movlw .64
 addwf moutH,f
 goto kkbbg3

gkbb77:

 ; if(util<1) goto gkbb88;
 btfss util,0
 goto gkbb88

 ; rev=(byte)-8;
 movlw -.8
 movwf rev

 ; moutH+=util*128; //256ths
 movlw .128
 addwf moutH,f
 ;ncrrd: 
 goto kkbbg3
gkbb88:
 ; rev=(byte)-9;
 movlw -.9
 movwf rev
kkbbg3:

 ; // Return number is now present in moutH/L pair as
 ; // a 16-bit fixed point number 
 ; if(!moutH) goto nrndmg00;
 movf moutH,f
 btfsc STATUS,Z
 goto nrndmg00
 
normaa:
 ; if(!moutH) goto normaout;
 movf moutH,w ; check for completion of process
 btfsc STATUS,Z
 goto normaout

 ; C=moutH&1;
 ; moutH/=2;
 ; c1=moutL&1; //Implicit on many CPUs, where c1 will not actually require storage
 ; moutL/=2;
 ; if(C)moutL|=128;
 bcf STATUS,C
 rrf moutH,f ; allow bottom bit of moutH... 
 rrf moutL,f ; ... to rotate into moutL

 ; ++rev;
 incf rev,f ;inc eout 
 ; goto normaa;
 goto normaa
 
 
normaout:
 ; if(!c1) goto nrndmg00;
 btfss STATUS,C ; round up, if necessary, after last RRF
 goto nrndmg00

 ;++moutL; 
 incf moutL,f

 ;if(moutL) goto nrndmg00;
 ; movf moutL,f
 btfss STATUS,Z
 goto nrndmg00

 
 ; //The rounding put moutL up to 0, which is really 256;
 ; // We effect an overall right shift putting the bottom
 ; // bit of moutH back into the top bit of mouL. Exponent
 ; // rev is incremented to compensate.
 ; ++moutH; 
 incf moutH,f
 
 ; ++rev;
 incf rev,f

 ; moutL=128;
 movlw .128
 movwf moutL
 
nrndmg00:
 ; // moutL now holds an 8-bit integral version of the 
 ; // correct return mantissa
 ; //ncmoul:
 ; moutL&=127;
 bcf moutL,7
 
 ; if(neg) moutL|=128;
 btfsc neg,0
 bsf moutL,7
 
 ; *mout=moutL;
 movf moutL,w
 PUSH
 ; *eout=rev;
 movf rev,w
 PUSH
 HLUNLOCK
 return
 
look_core: 
 movlw high FPCoreTbl ;exec lookup 
 movwf PCLATH 
 movlw low FPCoreTbl 
 addwf mout,w 
 btfsc STATUS,C 
 incf PCLATH,f 
 movwf PCL 
FPCoreTbl: 
 retlw .0
 retlw .224
 retlw .186
 retlw .142
 retlw .93 
 retlw .39
 retlw .235
 retlw .170
 retlw .100
 retlw .25
 retlw .200
 retlw .115
 retlw .25 
 retlw .186
 retlw .86
 retlw .237
 retlw .129
 retlw .15
 retlw .152
 retlw .30
 retlw .159
 retlw .27
 retlw .148
 retlw .8
 retlw .120
 retlw .228
 retlw .76
 retlw .176
 retlw .16
 retlw .108
 retlw .197
 retlw .32
 retlw .106
 retlw .183
 retlw .2
 retlw .70
 retlw .137
 retlw .199
 retlw .32
 retlw .58
 retlw .111
 retlw .160
 retlw .206
 retlw .248
 retlw .32
 retlw .68
 retlw .101
 retlw .131
 retlw .157
 retlw .181
 retlw .202
 retlw .219
 retlw .234
 retlw .246
 retlw .200
 retlw .8
 retlw .8
 retlw .16
 retlw .6
 retlw .8
 retlw .250
 retlw .239
 retlw .226
 retlw .210
 retlw .193
 retlw .171
 retlw .148
 retlw .122
 retlw .94
 retlw .63
 retlw .30
 retlw .250
 retlw .212
 retlw .171
 retlw .129
 retlw .83
 retlw .36
 retlw .242
 retlw .190
 retlw .136
 retlw .80
 retlw .21
 retlw .217
 retlw .154
 retlw .89
 retlw .22
 retlw .209
 retlw .138
 retlw .64
 retlw .245
 retlw .168
 retlw .88
 retlw .16
 retlw .180
 retlw .95
 retlw .8
 retlw .175
 retlw .84
 retlw .247
 retlw .153
 retlw .56
 retlw .214
 retlw .114
 retlw .12
 retlw .165
 retlw .59
 retlw .208
 retlw .99
 retlw .245
 retlw .133
 retlw .19
 retlw .159
 retlw .42
 retlw .179
 retlw .59
 retlw .193
 retlw .69
 retlw .200
 retlw .73
 retlw .201
 retlw .70
 retlw .195
 retlw .62
 retlw .183
 retlw .47
 retlw .165
 retlw .27
 retlw .142 


look_core_hi: 
 movlw high FPCoreTblHi ;exec lookup 
 movwf PCLATH 
 movlw low FPCoreTblHi 
 addwf mout,w 
 btfsc STATUS,C 
 incf PCLATH,f 
 movwf PCL 
FPCoreTblHi: 
 retlw .0
 retlw .2
 retlw .5
 retlw .8
 retlw .11
 retlw .14
 retlw .16
 retlw .19
 retlw .22
 retlw .25
 retlw .27
 retlw .30
 retlw .33
 retlw .35
 retlw .38
 retlw .40
 retlw .43
 retlw .46
 retlw .48
 retlw .51
 retlw .53
 retlw .56
 retlw .58
 retlw .61
 retlw .63
 retlw .65
 retlw .68
 retlw .70
 retlw .73
 retlw .75
 retlw .77
 retlw .80
 retlw .82
 retlw .84
 retlw .87
 retlw .89
 retlw .91
 retlw .93
 retlw .96
 retlw .98
 retlw .100
 retlw .102
 retlw .104
 retlw .106
 retlw .109
 retlw .111
 retlw .113
 retlw .115
 retlw .117
 retlw .119
 retlw .121
 retlw .123
 retlw .125
 retlw .127
 retlw .129
 retlw .132
 retlw .134
 retlw .136
 retlw .138
 retlw .140
 retlw .141
 retlw .143
 retlw .145
 retlw .147
 retlw .149
 retlw .151
 retlw .153
 retlw .155
 retlw .157
 retlw .159
 retlw .161
 retlw .162
 retlw .164
 retlw .166
 retlw .168
 retlw .170
 retlw .172
 retlw .173
 retlw .175
 retlw .177
 retlw .179
 retlw .181
 retlw .182
 retlw .184
 retlw .186
 retlw .188
 retlw .189
 retlw .191
 retlw .193
 retlw .194
 retlw .196
 retlw .198
 retlw .200
 retlw .201
 retlw .203
 retlw .205
 retlw .206
 retlw .208
 retlw .209
 retlw .211
 retlw .213
 retlw .214
 retlw .216
 retlw .218
 retlw .219
 retlw .221
 retlw .222
 retlw .224
 retlw .225
 retlw .227
 retlw .229
 retlw .230
 retlw .232
 retlw .233
 retlw .235
 retlw .236
 retlw .238
 retlw .239
 retlw .241
 retlw .242
 retlw .244
 retlw .245
 retlw .247
 retlw .248
 retlw .250
 retlw .251
 retlw .253
 retlw .254

 END