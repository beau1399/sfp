/****************************************************************************************

16-Bit Small Floating Point ("SFP") for 8-Bit Devices

Copyright (c)2011 James Beau Wilkinson

Licensed under the GNU General Public License ("Greater GPL")

* Fully shift-based multiply and divide
* Table-based logarithms and powers
* 100% correct rounding
* Exhaustively exercised in distributed testing
* Symmetrical design reduces bit arithmetic
* 15-byte peak memory usage (plus code)
* Super-wide dynamic range (10^39)
* Flat function call model (zero internal calls)
* Optional reentrant implementation
* Three lightweight, non-conformant subsets
* Modular design; each operation is free-standing

Build Example:
c:\mingw\bin\g++ sfp.cpp

The library presented below consists of a set of static methods that collectively 
define a real number type designed for maximum portability to hardware with minimal 
capabilities. It is written in "primitive C," lacking control structures, types 
having >8 bits, and anything else difficult to hand-compile (if necessary) into a 
typical 8-bit assembly or machine language, e.g. on a system for which a full C 
compiler is not available. (Everything done here does assume an 8-bit signed "char" 
type.)

The library aims to improve on the performance and availability offered by more
typical real number types on minimal hardware. Even where higher-level languages are 
available for 8-bit integer-based microcontrollers, for example, it is typically
IEEE 754 single-precision floating point, and the 24-bit mantissa used is unwieldy for
an 8-bit device. Finally, because of the small size of the type, it has proven practical
to comprehensively test it for accuracy. This lends a measure of confidence in a 
problem domain where high-profile failures have occured.

Several experimental applications have been written around this type. A PID position
controller, for example, was written and used to drive a tray assembly scavenged out
of a CD-ROM drive. A photoresistor and lamp were used to create a position sensor.
This used SFP on a PIC 16F690 to drive the same hardware as an earlier, fixed-point 
system, with dramatically better stability, speed, etc. The code was also much more
intuitive, with no application-specific floating point translations or bounds checking
necessary, just unadorned real number literals and calls strung together. 

SFP was also used in conjunction with some other lightweight high-level structures to 
calculate very large factorials on the PIC. The PIC implementation has been executed on
a variety of members of the most recent two major generations of PIC 8-bit 
microcontroller, including the 16F690, 16F688, 16F689, and 16F1827. 

Finally, a partial 6800-family version has been written and executed on a wide variety 
of hardware, including a TRS-80 Color Computer 2 and a Heathkit ET-3400. The latter 
device, with its 512 bytes of RAM, hex keypad, and 7-segment LED-based display is 
probably not typically associated with great computational ability. 

The 6800 family as a whole plays a very wide variety of roles in the lab, industrial, 
and embedded arenas, and it is hoped that a full assembly language implementation can 
eventually be disseminated for both the 6800 and PIC microcontroller families. The 
building blocks are already presented in this file.

The library is based around a 16-bit floating point data type, with an 8-bit exponent 
and an 8-bit mantissa. The exponent is a 2's complement number (for easy addition and
subtraction) while the mantissa consists of magnitude in bits 0-6 with the sign in bit 
7. Note that the mantissa is an unsigned 7-bit number with an implicit denominator of 
128, such that the number mantissa=M, exponent=E in this type represents:

+/- (((M&127)+128)/128) * (2^E)

The smallest representable quantity is thus:

+/- ((0+128)/128) * (2^-128) = 2^-128

And the maximum representable quantity is:

+/- ((127+128)/128) * (2^127) = ~2^128

The supported operations are addition, subtraction, multiplication, division, 
exponentiation (2^X), and logarithms.

In general, these primitive C methods have a signature like this:

typedef unsigned char byte; 
void sfp_sub 
(
byte min, char ein, 
byte min2, char ein2, 
byte *mout, char *eout
);

Paramenters "min" "ein" the input mantissa and exponent for the left-hand operand.
The paramenters "min2" "ein2" the input mantissa and exponent for the right-hand 
operand. Pointers "mout" and "eout" point to the output mantissa and exponent, 
respectively.

Recent developments have even demonstrated a role for the 16-bit, half-precision 
floating point, even on some very high-performance hardware, and this type has now 
even been codified into the IEEE standard. This half-precision variant was used
as the starting point for all decisions about numeric representation. 

Targeted changes, which are enumerated in their entirety below this paragraph, were 
made. Most of these relate to the role anticipated for SFP, i.e. low-cost / 
low-power 8-bit computing devices like the PIC and 6800 families:

-The mantissa occupies a single byte in SFP, versus the IEEE design, where 
the mantissa is larger than the exponent and spans parts of both bytes. 
This symmetry-of-design reduces considerably the amount of underlying bit 
arithmetic that must be performed.

-The exponent is expressed in standard two's complement, vs. "exponent bias"
(a.k.a. "excess") format. This allows single-operation addition and
subtraction of exponents, which are important operations. The main operation
facilitated by the IEEE's "excess" notation is comparison, which is not
directly implemented here.

-More bits are allocated to the exponent. This increases dynamic range to
a level suitable for general-purpose use.

-IEEE does not mandate a rounding strategy for "library" functions, including
the logarithm function. SFP uses the same rounding strategy for logarithms 
as for the other functions.

-IEEE has special values set aside for codes (infinity, NaN, etc.) In 
SFP, out-of-domain conditions either "bump" intuitively into the extrema of 
the SFP type instead (if BOUNDSCHECK is defined and such a result exists), 
or are undefined.

Other aspects of IEEE are adopted without major change:

-The normalization strategy is the same, i.e. the mantissae range from 
128 to 256 with the top bit assumed, and each number has a single,
"normalized" representation. 

-The representation of the mantissa and sign bit is identical in format
to IEEE.

-The IEEE "round-to-nearest" or "RN" strategy is used. (Round-to-even is 
not enforced, a fact which has no impact on accuracy or precision.)

-Selection of a radix of 2 is shared with IEEE and all other modern float
formats.

See http://www.mrob.com/pub/math/floatformats.html - SFP has fewer mantissa bits -
and thus less precision - than all the commercial types, but many more mantissa bits 
than any of the purely instructional types. Dynamic range is superior, e.g. it 
outdoes the IBM 360 mainframe "Double" by a full order of magnitude here, and 
resides between IEEE 32-bit and 64-bit floating point formats in this measure.


Table of Comparisons:

TYPE   SIZE  EPSILON* MIN      MAX***   RANGE   PRECIS.
----------------------------------------------------------------
IEEE** 16bit 4.88e-04 6.10e-05 6.55e+04 6.8e+05 3.3 digits
IEEE** 32bit 5.96e-08 1.18e-38 3.40e+38 4.6e+38 7.2 digits
SFP    16bit 8.84e-02 2.94e-39 3.40e+38 3.3e+39 2.4 digits

* A measure of peak rounding error
** In "Round Nearest" mode; rounding for LOG, etc. not specified for IEEE types
*** Approximate (slight overestatement) in all cases

The real value of this library is not just in the C code present here; its real utility's 
also in the specific 8-bit assembly and machine language implementations that flow 
naturally from it. In these implementations, different parameter passing mechanisms, 
mnemonics, etc. will be used.

The memory model here is that of a shared RAM scratchpad access by all methods; the 
methods are thus not reentrant as written here. However, it would be trivial to fix this 
by changing the scratchpad register declarations into several sets of automatic variable
declarations within each function. Again, the value of the library is not the code shown
here, it is the variety of implementations (6800, PIC, etc.) that spring from it. (It 
should be noted, though, that a reentrant implementation might cause complications in
cases where coroutines are used; single-operation subtraction and negative exponentiation 
may therefore not be possible in such an implementation.)

Relatedly, none of the functions presented below call each other. In general, each 
function is standalone in nature, and can be implemented on a given system independently
of the rest of the library. 

There are two exceptions, i.e. cross functional dependencies: sfp_sub jumps into 
sfp_add, and allows it to finish processing and return to the caller, and sfp_pow does 
the same thing with sfp_div (to invert negative exponents). Nevertheless, in all cases, 
calls into the library functions will not call out, i.e. they will not push additional 
return addresses onto the call stack. This is a key asset on devices like the PIC, with 
a limited return address stack.

This program itself enters a comprehensive test loop at the top of "main()" which is 
designed to test its results for accuracy against the compiler's floating point system.
Based on a comprehensive execution of these tests extending over several days, the code
presented here can be confidently described as 100% faithful to its specification.

To be specific, this means that any given combination of parameters passed into any of 
the operation functions below can be expected to yield the best possible approximation 
possible. This has been tested against GCC "doubles" in the default (vs. "fast math") 
compilation mode.

Note that the negative exponentiation function concludes with a jump into sfp_divf() to
invert the result (i.e. to convert 2^K to 2^-K). This implies that the loss-of-precision
inherent to negative exponentiation is that of two operations, not just one, and this is
allowed for in the test code below.

****************************************************************************************/

#include <stdio.h>

#include <setjmp.h> //Used for coroutines sfp_add() and sfp_sub()
#include <math.h>
#include <stdlib.h>
#include <limits>

#define MAXREAL 3.3895313892515355e+038 // = 255/128*2^127

typedef unsigned char byte;

#undef QUIET //Provides for less verbose test output

//#define FASTMATH //Allows single-bit rounding errors; simplifies implementation

#define BOUNDSCHECK
//
// BOUNDSCHECK affects the complexity of each of the arithmetic functions.
// (Logarithm and power ops are not affected.)
//
// If "BOUNDSCHECK" is defined, the domain of all functions encompasses all 
// representable numbers, and correct results will be returned in all cases.
// This means that the closest representable number to the answer will be 
// returned; if the answer is too big to represent, the largest representable
// number will be returned, with appropriate sign. Similarly, if the number
// is too small to represent, the smallest representable number will be 
// returned, again with appropriate sign.
//
// If "BOUNDSCHECK" is not defined, exponent overflow is never checked for.
// This applies to the overall operation, as well as some intermediate 
// calculations that might exceed the range of the system even if the 
// eventual result would be representable. Nevertheless, it is still allowable
// to use some numbers of very large/small magnitude even without bounds
// checking. While the absolute limits have not been completely explored as
// of this time, conservatively it can be said (and is tested) that operations 
// having best results with exponents ranging from 2^-126 to 2^125, inclusive,
// should at an absolute minimum return correct results even without bounds
// checking.
//
// Another implication of turning off bounds checking is that division-by-zero
// becomes an error, with undefined results. Under bounds checking, the 
// largest representable number is returned if division-by-zero is attempted,
// and in general this "largest number" serves as a proxy for infinity. 
//
// Note the additions and multiplications resulting in a correct answer of zero
// are still supported, even with bounds checking turned off. This is supported
// by detecting inputs with the minimum values, and re-directing to logic 
// which treats these as a zero. In theory, this results in a loss-of-precision
// in some cases where 0 is returned by the unchecked version of an operation 
// even though the correct result is a very small but representable result that
// might be obtained even without bounds checking. This is justified by saying 
// that such small calculations are outside the domains of the unchecked versions
// of the functions, except for +/- 0 (i.e. the minimum representable numbers).
// 
// Additions to / subtractions from zero are undefined if BOUNDSCHECK is not 
// enabled; zero is represented as the minimum possible number, and this will
// result in out-of-bounds operation in the current implementation.
//

/****************************************************************************************
Scratchpad Allocation...

Whether these variables ends u being static based, as in this code, or stack
based, the important thing is the overall number of variables and
their minimization.. this serves as an upper bound on runtime memory
requirements.

Some architectures may require use of additional RAM, esp. to implement
expression evaluation. SOFTC on the 68xx is an example. Not all inequals.
can be evaluated without storing "C" away somewhere in RAM... hence
"SOFTC." On many processors a register could be used for this; so, the
process is abstracted as a "C-language" inequality and details are left
for implementor to resolve.

What is shown here is a three-legged system of RAM allocation that ultimately 
does end up matching most of the implementation assembly code developed thus
far:

1) Fixed set of registers allocated here, with generic names

2) Necessary registers #defined to a friendly name before each function, 
starting with "loc000."

3) Friendly name #defined to garbage after function, as a sanity check

Primary advantage is that it allows us to easily track the upper bound on
overall RAM usage, while still using "friendly" names. 
****************************************************************************************/

byte loc000; /*15 bytes of RAM are required for the full library*/
byte loc001;
byte loc002;
byte loc003;
byte loc004;
byte loc005;
byte loc006;
byte loc007;
byte loc008;
byte loc009;
byte loc00A;
byte loc00B;
byte loc00C;
byte loc00D;
byte loc00E;

/****************************************************************************************
Register Allocation

The next set of variables is not expected to tie to actual memory
locations. They are expected to be registers, or implicit pieces 
of the machine-level operation.

Not all registers are explicitly declared here. Platforms vary
extensively in this area, and we are attempting to target the "least
common denominator" of available technology. 

In general, carries are fairly standardized and a carry register "C"
is thus provided. Most machines will have at least an accumulator too, 
but this is "trashed" by expression evaluation and thus cannot be
treated like a C-language variable. The decision was made that this
"trashing" should be allowed, which simplifies the "primitive C"
code in this file. This rules out having an "accumulator register" 
variable. 

Beyond carry and accumulator, hardware varies greatly, and it's not
within the scope of this project to make assumptions about such things.
****************************************************************************************/
bool C;

/****************************************************************************************
Multiple carry flags declared... used to simulate things like the PIC 
shifts, which "carry in" the contents of C in a way that would ba
difficult to reflect in C code built around a single bool.

In the worst case, these will need to be RAM variables; in the best
case (e.g. PIC) the operations written using these happen almost 
automatically.
****************************************************************************************/

bool c1,c2,c3; 
/****************************************************************************************
Converts a C++ double read in from user code to mantissa and exponent 
bytes per the format specified in the big comment above.

This method is written for general-purpose computers and thus uses
non-8-bit types like int and double, along with full use of structured
programming constructs like "while." Other methods in this file,
which are part of the real FP kernel that targets the 8-bit device,
do not have this luxury in this model "primitive C" code.
****************************************************************************************/
void sfp_from_ieee(double f, byte* mant_byte,char* exp_char)
{
 if(fabs(f)<powf((double)2.0,(double)-128.0))
 {
  //Less than smallest SFP value?
  if(f>=0.0)
  *mant_byte=0; 
  else
  *mant_byte=128;
  *exp_char=-128;
  return;
 }

 if(fabs(f)>=MAXREAL)
 {
  if(f>=0.0)
  *mant_byte=127; 
  else
  *mant_byte=255;
  *exp_char=127;
  return;
 }

 int exp,mant_min;
 int try_exp=128;

 (*mant_byte)=0;

 if(f < 0.0)
 {
  f=-f; 
  mant_min=1;
 }else
 {
  mant_min=0;
 }

 int char_ind=6;

 do
 {
  if(f>=pow((double)2,(double)try_exp))
  {
   //"Hidden bit" (implicit +128 in mantissa) is assumed here.
   f-=pow((double)2,(double)try_exp);
   exp=try_exp;
   --try_exp;
   break;
  }
  --try_exp;

 }while(1);

 do
 {
  if(f>=pow((double)2,(double)try_exp))
  {
   (*mant_byte)|=(int)(pow((double)2,char_ind--));
   f-=pow((double)2,(double)try_exp);
  }
  else 
  {
   (*mant_byte)&=(int)(255-pow((double)2,char_ind--));
  }

  --try_exp;
  if(char_ind<0)break;

 }while(1);

 //Rounding.. at this point, try_exp is one below the last
 // exponent that actually has a place in the mantissa. This
 // means that 2^try_exp is 1/2 the value of the last digit and
 // is thus exactly what we need to test against for rounding
 if(f>=pow((double)2,(double)try_exp))
 {
  (*mant_byte)+=1;
  if(*mant_byte==128)
  {
   (*mant_byte)=0;
   ++exp;
  }
 }

 if(mant_min) (*mant_byte)|=128; //Just set top bit... that's it.

 *exp_char=(char)exp;
}

/****************************************************************************************
This function is the inverse of sfp_from_ieee (immediately above). 

It converts 16-bit SFP floats "m" and "e" to a standard C++ IEEE double.
****************************************************************************************/
double sfp_to_ieee(byte m, char e)
{
 double signf=1.0l;
 { 
  if(m&128)
  {
   signf=-1.0l;
   m&=127;
  }

  return signf*((double)m+128.0l)/128.0l*pow(2.0l,(double)e);

 }
}

/****************************************************************************************
Outputs a user-friendly (i.e. decimal) representation
****************************************************************************************/
void sfp_print(byte m, char e)
{
 if(m&128)
 {
  printf("-");
  m&=127;
 }

 //The part in [] brackets need not be a part of every target implementation...
 // it is far quicker and easier just to dump M and E in raw form, which ends up
 // resembling scientific notation.
 printf("(%d / 128) * (2 ^ %d) [%f]",
 ((int)m+128),e,((double)m+128.0)/128.0*pow(2.0,(double)e)
 );
}

/****************************************************************************************
Compares SFP value m:e to GCC double "target" with debugging output.
****************************************************************************************/
double sfp_print_with_err(byte m, char e,double target)
{

#ifndef QUIET
 printf("\n--------------------\n%f\n",target);
#endif

 byte mo;
 char eo;
 double ret;

 ::sfp_from_ieee(target,&mo,&eo);

#ifndef QUIET
 ::sfp_print(mo,eo);
 puts("");
#endif
 { 
  if(m&128)
  {
#ifndef QUIET
   printf("-");
#endif
   m&=127;
  }

  --m;
#ifndef QUIET
  printf("(%d / 128) * (2 ^ %d) [%f, error=%f ]\n",
  ((int)m+128),e,((double)m+128.0)/128.0*pow(2.0,(double)e),
  fabs(fabs((double)m+128.0)/128.0*pow(2.0,(double)e)-fabs(target))
  );
#endif
  ++m;
#ifndef QUIET
  printf("(%d / 128) * (2 ^ %d) [%f, error=%f ]\n",
  ((int)m+128),e,((double)m+128.0)/128.0*pow(2.0,(double)e),
  fabs(fabs((double)m+128.0)/128.0*pow(2.0,(double)e)-fabs(target))
  );

#endif
  ret=
  fabs(fabs((double)m+128.0l)/128.0l*pow(2.0l,(double)e)-fabs(target));

  ++m;
#ifndef QUIET
  printf("(%d / 128) * (2 ^ %d) [%f, error=%f ]\n",
  ((int)m+128),e,((double)m+128.0)/128.0*pow(2.0,(double)e),
  fabs(fabs((double)m+128.0)/128.0*pow(2.0,(double)e)-fabs(target))
  );
#endif
 }
#ifndef QUIET
 printf("\n--------------------\n");
#endif
 return ret;
}

/****************************************************************************************

The "primitive C" portion of the library follows; in short, this next
portion of code is meant to be easily "hand-compilable" into a wide 
variety of target assembly and machine languages- even on 8-bit
devices. As such, brace-based control structures, 16- and 32-bit types,
library calls, etc. are studiously avoided. Any use of 'int' for 
example, should be commented. An example of a legitimate use of 'int'
might be an overflow check expressed something like

"if((int)some8bitNum + (int)other8bitNum > 255)

This ought to be trivially compilable on most 8-bit devices despite
their lack of the C 'int' type.

****************************************************************************************/

/*Memory map for both Add and Sub*/
#define mout_hi loc000
#define min_lower loc001
#define fullmin loc002
#define fullmin2 loc003
#define min2_lower loc004
#define rev loc005
#define minres loc006
#define neg loc007
#define neg2 loc008
#define rounded loc009
/****************************************************************************************
Subtraction
All sub functions require user to call ADD at least once first,
so that necessary SETJMP calls will get made. An SFP_INIT macro is provided to assist
with this, further below.
sfp_sub() is really just an alternate "top" for sfp_add, which contains the overall 
"combiner" facility. It handles some negation flags in a slightly different way to 
differentiate itself from sfp_add. It is grafted onto the "bottom" of sfp_add using 
setjmp() and longjmp(). That is, a user will call sfp_sub, and sfp_add() will end up 
returning the result. Identical call signatures allow this to work. As discussed below,
this often ends up being more straightforward in assembly language than it is in C.
****************************************************************************************/
static ::jmp_buf a2sbuf, a1z, a2z;
void sfp_sub
(
byte min, char ein, 
byte min2, char ein2, 
byte *mout, char *eout
)
{
 //Init. data
 minres=0;
 *mout=0;
 //Set flags based on sign
 neg=min&128;
 neg2=!(min2&128); //The key difference relative to ADDF 
 longjmp(a2sbuf,0); 
}
void sfp_add
(
byte min, char ein, 
byte min2, char ein2, 
byte *mout, char *eout
)
{
 //Check for zero args
 //Init. data
 minres=0;
 *mout=0;
 //Set flags based on sign
 neg=min&128;
 neg2=min2&128;
 //This is a label; in most asm implementations it can be an ordinary
 // label. The "setjmp" functionality is only required to "convince" the
 // C compiler to go ahead and jump out of the subroutine... this should
 // not be an issue in assembly language. Also, jumping from SUBF into
 // ADDF in this way does not violate our rule about not exercising the
 // call stack by calling helper functions from ADDF, SUBF, DIVF, MULF,
 // POW2F, or LOG2F; longjmp() evaluates to a JMP, BRA, or similar assembly
 // mnemonic, not a CALL or JSR.
 setjmp(a2sbuf);
 //Swap, if necessary, to put the larger exponent (if one exists) in ein2
 //N.B.: this is a comparison of chars, implying that it's done on a 2's comp.
 // basis. This rules out using, for example, the C flag in conjunction with 
 // the SUBWF or SUBLW instructions on the PIC. The subtraction operations on
 // the 6800 operate similarly, having "C" truth tables explicitly based on non-
 // 2's complement math shown in the data sheet. So, in both these cases a bit
 // of extra work is needed, e.g. performing an unsigned subtration and then
 // examining the top bit of the result.
 if(ein<=ein2) goto qv320;
 ein=ein^ein2;
 ein2=ein^ein2;
 ein=ein^ein2;
 min=min^min2;
 min2=min^min2;
 min=min^min2;
 rev=1;
 goto qv321;
qv320:
 rev=0;
qv321:
 //Get rid of sign bit for now 
 min&=127;
 min2&=127;
 //Create "real" mantissae, i.e. show the hidden bit
 fullmin=128+min;
 fullmin2=128+min2; 
 //Shift smaller exponent upward to match larger; mantissa
 // of smaller number will shrink correspondingly, possibly
 // to a number less than 128. This is the main reason for 
 // the shift to 'full' mantissae, in which the hidden bit
 // is actually reflected by a 1 in bit 7.
 min_lower=0;
 min2_lower=0;
whi77:
 if(ein==ein2) goto eein2outw;
 min_lower/=2;
 C=fullmin&1; 
 fullmin/=2; 
 if(!C) goto nocar001;
 min_lower|=128;
nocar001:
 ein++; //No need for bounds check b/c this is
 // the smaller exponent getting incremented
 goto whi77;
eein2outw: 
 //Undo any reversal
 if(!rev) goto nrev0;
 fullmin=fullmin^fullmin2;
 fullmin2=fullmin^fullmin2;
 fullmin=fullmin^fullmin2;
 min2_lower=min_lower;
 min_lower=0;
 //Handle the four "species" of problem, with
 // respect to neg and neg2.
nrev0: 
 if(!neg) goto nextspeci0;
 if(!neg2) goto nextspeci0;
 //Double negative... set "minres" and then handle
 // as if two positives
 minres=true;
 goto nextspeci2;
nextspeci0:
 if(!neg) goto nextspeci1;
 //2nd parm minus first; subtract, may set "minres"
rrrout0:
 //parm 2- parm 1
 *mout=(fullmin2-fullmin); 
 if(fullmin<=fullmin2) goto nc11rr;
 minres=true; 
 goto rrrout1;
nc11rr:
 if(!*mout) goto specidone0;
mouty:
 if((*mout)&128) goto nn91;
 (*mout)*=2;
 if(!(min_lower&128)) goto yym43;
 --*mout;
 if(*mout!=255) goto yym43; 
 minres=true;
 goto rrrout1; 
yym43:
 min_lower*=2;
#ifdef BOUNDSCHECK
 if(ein!=-128) goto bcaa;
 *mout=0; 
 if(!minres) goto bcab;
 *mout|=128; 
bcab:
 *eout=ein; 
 return;
bcaa:
#endif
 --ein;
 goto mouty;
nn91:
 if(!(min_lower&128)) goto trup5;
 --*mout;
 if(!(*mout==255)) goto fltu54;
 minres=true;
 goto rrrout1;
fltu54:
 if(*mout!=127) goto trup5; 
 /*Undid normalization */
 (*mout)*=2;
#ifdef BOUNDSCHECK
 if(ein!=-128) goto bcac;
 *mout=0; 
 if(!minres) goto bcad;
 *mout|=128; 
bcad:
 *eout=ein; 
 return;
bcac:
#endif
 --ein;
 if((min_lower&64)) goto trup5;
 ++*mout;
trup5:
 goto specidone0;
nextspeci1:
 if(!neg2) goto nextspeci2;
 //Arg1-Arg2 "species"
rrrout1:
 *mout=(fullmin-fullmin2); 
 if(fullmin2<=fullmin) goto rmxd3;
 minres=true; 
 goto rrrout0;
rmxd3:
 if(!*mout) goto specidone0; 
moutx:
 if((*mout)&128) goto nn91b;
 (*mout)*=2;
 if(!(min2_lower&128)) goto spyr5; 
 --*mout;
 if(*mout!=255) goto spyr5;
 minres=true;
 goto rrrout0;
spyr5:
 min2_lower*=2;
#ifdef BOUNDSCHECK
 if(ein!=-128) goto bcae;
 *mout=0; 
 if(!minres) goto bcaf;
 *mout|=128; 
bcaf:
 *eout=ein; 
 return;
bcae:
#endif
 --ein;
 goto moutx;
nn91b:
 if(!(min2_lower&128)) goto cxaa;
 --*mout;
 if(*mout!=255) goto iwrtt;
 minres=true;
 goto rrrout0;
iwrtt:
 if(*mout!=127) goto cxaa;
 //Undid normalization 
 (*mout)*=2;
#ifdef BOUNDSCHECK
 if(ein!=-128) goto bcag;
 *mout=0; 
 if(!minres) goto bcah;
 *mout|=128; 
bcah:
 *eout=ein; 
 return;
bcag:
#endif
 --ein;
 if(min2_lower&64) goto cxaa;
 ++*mout;
cxaa:
 goto specidone0;
 *mout=(fullmin2-fullmin);
 minres=true;
 goto specidone0;
nextspeci2:
 //Two positives. Just add mantissae
 mout_hi=0;
 *mout=(byte)(fullmin+fullmin2); 
 if(!(((int)fullmin+(int)fullmin2)>255)) goto cxab;
 ++mout_hi;
cxab:
 if((int)min_lower+(int)min2_lower > 255) goto bihhg; 
 if((min_lower+min2_lower)&128) goto bihhg;
 goto bihh0; 
bihhg:
 ++*mout;
 if(*mout) goto ppmt3;
 ++mout_hi;
ppmt3:
bihh0:
 if(!mout_hi) goto specidone0;
 //Terms too big; div and go back
 C=fullmin&1;
 fullmin/=2;
 min_lower/=2;
 if(!C) goto ddnyy;
 min_lower|=128;
ddnyy:
 C=fullmin2&1;
 fullmin2/=2;
 min2_lower/=2;
 if(!C) goto ddnzz;
 min_lower|=128;
ddnzz:
#ifdef BOUNDSCHECK
 if(ein!=127) goto bssfd;
 *mout=127; 
 if(!minres) goto de4yy;
 *mout|=128; 
de4yy:
 *eout=ein; 
 return;
bssfd: 
#endif
 ++ein;
 goto nextspeci2;
specidone0:
 if(*mout) goto moutf; 
 *mout=0;
 *eout=-128;
 return;
moutf:
 //Take out the implict 128 in numerator ("hidden bit")... 
 // We built *mout from fullbit / fullbit2 which contained true, pre "HB" values
 //
 (*mout)-=128;
 /*Set sign bit of mant. if necess.*/
 if(!minres) goto nm13ff5;
 (*mout)|=128; 
nm13ff5:
 *eout=ein;
 return;
}
/*Undef memory map for both Add and Sub*/
#undef mout_hi /*will cause a compilation error if used w/o */
#undef min_lower /* formal redefinition */
#undef fullmin 
#undef fullmin2
#undef min2_lower
#undef rev
#undef minres
#undef neg 
#undef neg2
#undef rounded
/****************************************************************************************
Division
****************************************************************************************/
#define util loc000
#define neg loc001
#define subtrahend loc002
#define quotient_lo loc003
#define eout_tmp loc004
#define save_denom loc005
#define quot_out_hi loc006
#define A_hi_msb loc007
#define run_total loc008
#define loop_count loc009
#define min2_lower loc00A
#define neg2 loc00B
#define rounded loc00C
#define b129 loc00D
#define b128 loc00E
void sfp_div
(
byte min, char ein, 
byte min2, char ein2, 
byte *mout, char *eout
)
{
 if(!(min&128) ) goto notminn1280;
 neg=1; 
 min&=127;
 goto minn1280;
notminn1280:
 neg=0;
minn1280:
 if(!(min2&128) ) goto notminn21280;
 neg2=1; 
 min2&=127;
 goto minn21280;
notminn21280:
 neg2=0;
minn21280:
#ifdef BOUNDSCHECK
 //Check for div by 0
 if(ein2!=-128) goto nzmd55;
 if(min2!=0) goto nzmd55;
 *mout=127;
 if(neg==neg2) goto nzmd66;
 *mout=255;
nzmd66: 
 *eout=127;
 return;
nzmd55:
#endif
 run_total=0;
#ifdef BOUNDSCHECK
 b128=false;
 b129=false;
 if(!((int)ein-(int)ein2 <-128) ) goto tffy6; 
 *eout=-128; 
 if(neg!=neg2) goto yuu4k;
 *mout=0;
 goto yuu5k;
yuu4k:
 *mout=128;
yuu5k:
 return; 
tffy6: 
 if(!((int)ein-(int)ein2 ==128) ) goto b5aek; 
 eout_tmp=127; 
 b128=true;
 goto b6aek; 
b5aek:
 if(!((int)ein-(int)ein2 > 127) ) goto b7aek;
 *eout=127; 
 if(neg!=neg2) goto b8aek;
 *mout=127;
 goto b9aek;
b8aek:
 *mout=255;
b9aek:
 return; 
b7aek:
 eout_tmp=ein-ein2;
b6aek:
#else
 eout_tmp=ein-ein2;
#endif
 //
 // DIV16
 //
 // [((min + 128 ) / (min2 + 128))*128 - 128 ]-> (quot_out_hi:mout) 
 //
 //We use "non-restoring" division, similar to SRT div as used in many
 // Intel pentiums. Difference is avoidance of lkup table; FP kernel
 // is big already, e.g. POW2F LOG2F.
 //
 //This expression consists of a number N such that 1<=N<2, divided 
 // by another such number P. The result will be a number (N/P) 
 // such that 1<=(N/P)<4. This result has to be expressed in integral
 // 128ths. Also, the ultimate result is "excess 128," meaning
 // that 0 implies 128/128, 1 implies 129/128, etc. The overall
 // range of the expression shown above is thus 0 to 511, i.e.
 // a 9-bit number, requiring use of the bottom bit of memory
 // location "quot_out_hi."
 min+=128;
 min2+=128;
 //Save denominator to see if rounding is necess. after loop
 // this mem. loc. is also used by div, mod (int ops) and powf, 
 // we don't call any of these and are not called either so this
 // is OK.
 save_denom=min2;
 quotient_lo=0;
 subtrahend=0;
 min2_lower=0;
 run_total=0;
 loop_count=0;
f4tp:
 if(loop_count>=16) goto f4dn;
 A_hi_msb=min&(128); //check top bit
 min2_lower*=2; 
 c1=((run_total&128)!=0);
 run_total*=2; 
 if(!c1) goto que4;
 ++min2_lower;
que4:
 min*=2;
 c1=((quotient_lo&128)!=0);
 quotient_lo*=2; 
 if(!c1) goto qu5e;
 ++min;
qu5e:
 if(!A_hi_msb) goto nry4;
 ++run_total;
 if(!run_total) ++min2_lower;
nry4:
 C=min2>run_total;
 min2_lower-=subtrahend;
 run_total-=min2;
 if(C) --min2_lower;
 if(!(min2_lower&128)) goto ga4g0;
 C=((int)min2+(int)run_total)>255;
 min2_lower+=subtrahend;
 run_total+=min2;
 if(C) ++min2_lower;
 quotient_lo&=0xFE;
 goto ga5g0;
ga4g0:
 quotient_lo|=0x01;
ga5g0:
 ++loop_count;
 goto f4tp;
f4dn:
 *mout= quotient_lo;
 quot_out_hi = (bool)(min&1); 
 save_denom/=2;
 if(!(save_denom<run_total) ) goto fr9rh;
 ++*mout;
 rounded=1;
 goto fr0rh;
fr9rh: 
 rounded=0;
fr0rh: 
 if(!quot_out_hi) goto notmult0; 
 if(!((*mout)&1 && !rounded)) goto prpgl;
 (*mout)/=2;
 (*mout)++;
 goto prpgm;
prpgl:
 (*mout)/=2;
prpgm:
 (*mout)|=128; //This is "quot_out_hi" shifting into top of *mout
 goto notmult1;
notmult0:
 --eout_tmp;
#ifdef BOUNDSCHECK
 if(eout_tmp!=127) goto rayg5;
 *eout=-128; *mout=0;
 if(neg==neg2) goto sg55l;
 *mout|=128;
sg55l:
 return;
rayg5:
#endif
notmult1:
retrydvifl:
 (*mout)-=128; //Test for neg. mant.
 if(!((*mout)&128)) goto nodivfcarr2;
 (*mout)+=128;
 --eout_tmp;
 *mout*=2;
 goto retrydvifl;
nodivfcarr2: 
 if(neg2==neg) goto div_sames;
 *mout|=128;
 div_sames:
#ifdef BOUNDSCHECK
 if(!b128) goto slcpx; 
 ++eout_tmp;
 if((((char)eout_tmp)>=0)) goto slcpx;
 *eout=127; 
 *mout=127;
 if(neg==neg2) goto slcpy;
 *mout|=128;
slcpy:
 return;
slcpx: 
#endif
 *eout=eout_tmp;
}
/*Undef. DIV16 mem. map*/
#undef util 
#undef neg 
#undef subtrahend 
#undef quotient_lo
#undef eout_tmp 
#undef save_denom
#undef quot_out_hi
#undef A_hi_msb 
#undef run_total 
#undef loop_count
#undef min2_lower
#undef neg2 
#undef rounded 
#undef b129 
#undef b128 
#undef loop_count 
#undef min2_lower
#undef neg 
#undef neg2 
#undef rounded
#undef b129
#undef b128
/****************************************************************************************
Multiplication
****************************************************************************************/
#define eout_tmp loc000
#define hi_byte loc001
#define real_min2 loc002
#define real_min loc003
#define make_mout loc004
#define mout_hi loc005
#define neg loc006
#define neg2 loc007
#define b129 loc008
#define b128 loc009
void sfp_mul
(
byte min, char ein, 
byte min2, char ein2, 
byte *mout, char *eout
)
{
 neg=0; /*Check for negs, */
 neg2=0; 
 if(!(min2&0x80)) goto ftfs1;
 neg2=1;
ftfs1:
 min2&=0x7F; /*Make parms absval */
 if(!(min&0x80)) goto ftfs2;
 neg=1;
ftfs2:
 min&=0x7F;
#ifndef BOUNDSCHECK
 //Check for 0 parm... this is mandatory to allow mul-by-0 with bounds
 // checking disabled.
 if(ein2==-128 && !min2 )goto mzee1; //Handle 0 in 2nd parm
 if(ein==-128 && !min )goto mzee2; //Handle 0 in 1st parm
#endif
 //Exponents get added, these are char b/c 
 // this should happen using 2's complem.
 eout_tmp=ein;
#ifdef BOUNDSCHECK
 b128=false;
 if(!((int)ein+(int)ein2 > 127)) goto ydhtn;
 *eout=127; 
 if(neg!=neg2) goto ybbaa;
 *mout=127;
 goto ybbab;
ybbaa:
 *mout=255;
ybbab:
 return; 
ydhtn:
 if(!((int)ein+(int)ein2 <-129) ) goto sue5c;
 *eout=-128;
 if(neg!=neg2) goto sue5d;
 *mout=0;
 goto sue5e;
sue5d:
 *mout=128;
sue5e:
 return; 
sue5c:
 if((int)ein+(int)ein2 !=-129) goto matr5;
 eout_tmp=0x80;//-128; 
 b129=true;
 goto matr6;
matr5:
 b129=false;
 eout_tmp+=ein2;//Using W...
matr6:
#else
 eout_tmp+=ein2; //W
#endif
 //Make real mantissae,i.e. add in hidden
 // bit; put in "real_min" and "real_min2" 
 real_min=min+128; //W
 real_min2=min2+128; //W
 //MUL16
 // (real number of 128ths min) * 
 // (real number of 128ths min2) -> 
 // mulhi:discarded
 //
 // This yields the (real mantissa out)
 // times 128; this is scaled down first
 // by taking the MSB and treating it 
 // as if it were an LSB (a net /256).
 // Also, eout_tmp is either incremented,
 // or mout is mult. by two, to yield
 // a net *2. The selection b/w these 
 // two options is made such that mout
 // ends up normalized.

 // Not a full implem. of "Booth's Algoritm" b/c 
 // it operates on unsigned numbers. Definitely 
 // similar, though, and resulted in a 5x performance 
 // improvement vs. repeated addition
 hi_byte=0;
 make_mout=0; 
 mout_hi=0; //Iterative loop counter 0...7
 // See this URL for details about the shift-based multiply
 // http://www.cs.rpi.edu/~hollingd/comporg.2000/Notes/Mult.PDF 
bptz2:
 if(!(real_min&1)) goto nyyu11;
 C=((int)make_mout+(int)real_min2>255);
 make_mout+=real_min2;
 if(C) ++hi_byte;
nyyu11:
 real_min/=2;
 c1=hi_byte&1;
 hi_byte/=2;
 C=make_mout&1;
 make_mout/=2;
 if(!c1) goto chri8;
 make_mout|=128;
chri8:
 //Carries out of make_mout (result hi byte) go into
 // to top of real_min (the determiner).
 if(!C) goto bbybm; 
 real_min|=128;
bbybm:
 mout_hi++;
 if(mout_hi<8) goto bptz2;
 real_min2=real_min; 
 *mout=make_mout;
 //Needs to be at least 128 b/c we are dealing with
 // "real" mantissae here and Hidden Bit will soon be subtracted
 // back out
 if(!(*mout&0x80)) goto nmfcar ;
 /*Increment eout, to scale mulhi */
 /* per comment above MUL16*/
 ++eout_tmp; 
#ifdef BOUNDSCHECK
 if((((char)eout_tmp))!=-128) goto a5crm;
 eout_tmp=127;
 b128=true;
a5crm:
#endif
 //ROUNDING - MARKED
 if(!(real_min2&128)) goto dv40e;
 ++*mout; 
dv40e:
 goto if1done;
nmfcar:
 *mout*=2;
 //Other part of this scaling is simply fact that exp.
 // incrementation prior to nmfcar label was skipped.
 //ROUNDING (Really just restoring correct bit of data)
 if(!(real_min2&64 )) goto iqt10;
 ++*mout;
iqt10:
 //ROUNDING - OK
 if(real_min2&128) ++*mout;
 if(*mout) goto cnc44;
 *mout=128;
 ++eout_tmp;
#ifdef BOUNDSCHECK
 if((((char)eout_tmp))!=-128) goto cnc45;
 if(!b128) goto cnc46;
 *eout=127; 
 *mout=127;
 if(neg==neg2) goto caaa0;
 *mout|=128;
caaa0:
 return;
cnc46:
 eout_tmp=127;
 b128=true;
cnc45:
#endif
cnc44:
if1done:
 (*mout)-=128;
 //Handle negation
 if(neg2==neg)goto msames;
 (*mout)|=128;
msames:
 *eout=eout_tmp;
#ifdef BOUNDSCHECK
 if(!b128) goto meew0;
 ++*eout;
 if(*eout>=0) goto meew0;
 *eout=127; 
 *mout=127;
 if(neg==neg2) goto meew1;
 *mout|=128;
meew1:
 return; 
meew0:
 if(!b129) goto meew2;
 --*eout;
 if(*eout<=0) goto meew2;
 *eout=-128; 
 *mout=0;
 if(neg==neg2) goto meew2;
 *mout|=128;
meew2:
#endif
 return;
#ifndef BOUNDSCHECK
mzee1:
mzee2:
#endif
 //return + or - zero
 *eout=-128;
 *mout=0;
 return;
}
/*Undef. MUL16 mem. map*/
#undef eout_tmp 
#undef hi_byte 
#undef real_min2 
#undef real_min 
#undef make_mout 
#undef mout_hi 
#undef neg 
#undef neg2 
#undef b129 
#undef b128 
/****************************************************************************************
Logarithms
****************************************************************************************/
byte lookcore[128]={
 0,
 224,
 186,
 142,
 93, 
 39,
 235,
 170,
 100,
 25,
 200,
 115,
 25, 
 186,
 86,
 237,
 129,
 15,
 152,
 30,
 159,
 27,
 148,
 8,
 120,
 228,
 76,
 176,
 16,
 108,
 197,
 32,
 106,
 183,
 2,
 70,
 137,
 199,
 32,
 58,
 111,
 160,
 206,
 248,
 32,
 68,
 101,
 131,
 157,
 181,
 202,
 219,
 234,
 246,
 200,
 8,
 8,
 16,
 6,
 8,
 250,
 239,
 226,
 210,
 193,
 171,
 148,
 122,
 94,
 63,
 30,
 250,
 212,
 171,
 129,
 83,
 36,
 242,
 190,
 136,
 80,
 21,
 217,
 154,
 89,
 22,
 209,
 138,
 64,
 245,
 168,
 88,
 16,
 180,
 95,
 8,
 175,
 84,
 247,
 153,
 56,
 214,
 114,
 12,
 165,
 59,
 208,
 99,
 245,
 133,
 19,
 159,
 42,
 179,
 59,
 193,
 69,
 200,
 73,
 201,
 70,
 195,
 62,
 183,
 47,
 165,
 27,
 142 
};
byte lookcoreh[128]={
 0,
 2,
 5,
 8,
 11,
 14,
 16,
 19,
 22,
 25,
 27,
 30,
 33,
 35,
 38,
 40,
 43,
 46,
 48,
 51,
 53,
 56,
 58,
 61,
 63,
 65,
 68,
 70,
 73,
 75,
 77,
 80,
 82,
 84,
 87,
 89,
 91,
 93,
 96,
 98,
 100,
 102,
 104,
 106,
 109,
 111,
 113,
 115,
 117,
 119,
 121,
 123,
 125,
 127,
 129,
 132,
 134,
 136,
 138,
 140,
 141,
 143,
 145,
 147,
 149,
 151,
 153,
 155,
 157,
 159,
 161,
 162,
 164,
 166,
 168,
 170,
 172,
 173,
 175,
 177,
 179,
 181,
 182,
 184,
 186,
 188,
 189,
 191,
 193,
 194,
 196,
 198,
 200,
 201,
 203,
 205,
 206,
 208,
 209,
 211,
 213,
 214,
 216,
 218,
 219,
 221,
 222,
 224,
 225,
 227,
 229,
 230,
 232,
 233,
 235,
 236,
 238,
 239,
 241,
 242,
 244,
 245,
 247,
 248,
 250,
 251,
 253,
 254
};
/*Define LOG16 mem. map*/
#define arg1 loc000
#define karg1 loc001
#define util loc002
#define exam loc003
#define neg loc004
#define rev loc005
#define moutL loc006
#define moutH loc007
#define tmputil loc008
void sfp_log 
(
byte min, char ein, 
byte *mout, char *eout
)
{
 util=ein; 
 *mout=min;
 // If passed 1 (0 and 0) then return log(1) i.e. 0
 if(*mout) goto nzmdss;
 if(util) goto nzmdss;
 *mout=128;
 *eout=-128;
 return;
nzmdss:
 moutL=lookcore[*mout];
 moutH=lookcoreh[*mout];
 neg=0;
 if(!(util&128)) goto nonegtlog;
 neg|=1;
 util=~util;
 util++;
nonegtlog: 
 if(util>=128) goto fi5tt2;
 if(util>=64) goto fi5tt3;
 if(util>=32) goto fi5tt4;
 if(util>=16) goto fi5tt5;
 if(util>=8) goto fi5tt6;
 if(util>=4) goto fi5tt7;
 if(util>=2) goto fi5tt8;
 if(util>=1) goto fi5tt9;
 goto fi5ttz;
fi5tt2:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt3:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt4:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt5:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt6:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt7:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt8:
 C=moutH&1;
 moutH/=2;
 moutL/=2;
 if(C) moutL|=128;
fi5tt9:
 C=moutH&1; 
 moutH/=2;
 c1=moutL&1;
 moutL/=2;
 if(C)moutL|=128;
 if(!c1)goto fi5ttz;
 ++moutL;
 if(moutL)goto fi5ttz;
 ++moutH;
fi5ttz:
 //If neg, moutH:L should have opposite sign as well
 if(!neg) goto m1gd6;
 moutH=~moutH;
 moutL=~moutL;
 ++moutL;
 if(moutL) goto m1gd6;
 ++moutH;
m1gd6:
 if(util<128) goto gkbb11;
 rev=(byte)-1;
 moutH+=util; //256ths
 goto kkbbg3;
gkbb11:
 if(util<64) goto gkbb22;
 rev=(byte)-2;
 //Effect moutH+=util*2; //256ths
 tmputil=util;  //If FASTMATH is defined, it's OK to trash util and tmputil!=necess.
 tmputil*=2;        // (here and elsewhere) 
 moutH+=tmputil;
 goto kkbbg3;
gkbb22:
 if(util<32) goto gkbb33;
 rev=(byte)-3;
 // Effect moutH+=util*4; //256ths
 tmputil=util;  //If FASTMATH is defined, it's OK to trash util and tmputil!=necess.
 tmputil*=2;        // (here and elsewhere) 
 tmputil*=2;
 moutH+=tmputil;
 goto kkbbg3;
gkbb33:
 if(util<16) goto gkbb44;
 rev=(byte)-4;
 //Effect moutH+=util*8; //256ths
 tmputil=util;  //If FASTMATH is defined, it's OK to trash util and tmputil!=necess.
 tmputil*=2;        // (here and elsewhere) 
 tmputil*=2;
 tmputil*=2;
 moutH+=tmputil;
 goto kkbbg3;
gkbb44:
 if(util<8) goto gkbb55;
 rev=(byte)-5;
 //256ths
 // Effect moutH+=util*16; 
 tmputil=util;
 tmputil*=2;
 tmputil*=2;
 tmputil*=2;
 tmputil*=2;
 moutH+=tmputil;
 goto kkbbg3;
gkbb55:
 if(util<4) goto gkbb66;
 rev=(byte)-6;
 //Effect moutH+=util*32; //256ths
 if(!(util&4)) goto ncrrf;
 moutH+=128;
ncrrf: 
 if(!(util&2)) goto ncrrg;
 moutH+=64;
ncrrg:
 if(!(util&1)) goto kkbbg3;
 moutH+=32;
 goto kkbbg3;
gkbb66:
 if(util<2) goto gkbb77;
 rev=(byte)-7; //256ths
 //Next 2 "ifs" effect 
 // "moutH+=util*64;" for this range of "util"
 if(!(util&2)) goto ncrre;
 moutH+=128;
ncrre:
 if(!(util&1)) goto kkbbg3;
 moutH+=64;
 goto kkbbg3;
gkbb77:
 if(util<1) goto gkbb88;
 rev=(byte)-8;
 //Next stmt. tantamount to moutH+=util*128; //256ths
 moutH+=128;
 goto kkbbg3;
gkbb88:
 rev=(byte)-9;
 // moutH+=util*256; //256ths
kkbbg3:
 // Return number is now present in moutH/L pair as
 // a 16-bit fixed point number 
 if(!moutH) goto nrndmg00;
normaa:
 if(!moutH) goto normaout;
 C=moutH&1;
 moutH/=2;
 c1=moutL&1; //Implicit on many CPUs, where c1 will not actually require storage
 moutL/=2;
 if(C)moutL|=128;
 ++rev;
 goto normaa;
normaout:
 if(!c1) goto nrndmg00;
#ifndef FASTMATH 
 //Hardcoding around one situation... interplay of rounding in table 
 //construction, plus 2x rounding here, is difficult to predict 
 // w/o resorting to this corner-case handler.
 if(moutH!=0) goto frwks4;
 if(moutL!=254) goto frwks4;
 if(rev!=5) goto frwks4;
 if(util!=64) goto frwks4;
 if(!neg) goto frwks4;
 if(*mout!=38) goto frwks4;
 //goto frwks5;
 goto nrndmg00;
#endif 
frwks4:
 ++moutL; 
 //frwks5:
 if(moutL) goto nrndmg00;
 //The rounding put moutL up to 0, which is really 256;
 // We effect an overall right shift putting the bottom
 // bit of moutH back into the top bit of mouL. Exponent
 // rev is incremented to compensate.
 ++moutH; 
 ++rev;
 moutL=128;
nrndmg00:
 // moutL now holds an 8-bit integral version of the 
 // correct return mantissa
 //ncmoul:
 moutL&=127;
 if(neg) moutL|=128;
 *mout=moutL;
 *eout=rev;
}
/*Undef. LOG16 mem. map*/
#undef arg1 
#undef karg1 
#undef util 
#undef exam 
#undef neg 
#undef rev 
#undef moutL 
#undef moutH 
#undef tmputil
/****************************************************************************************
Exponentiation
****************************************************************************************/
byte fpcorelk2[]=
{
 0 ,//((2^(0/256))-1)*128 = 0.000000 These are unadjusted rounded values, in contrast to 
 0 ,//((2^(1/256))-1)*128 = 0.347046 values in the logarithm table, which are manually 
 1 ,//etc.                           tuned to help yield expected results (one "corner 
 1 ,//                               case" is still hard-coded around, even there).
 1 ,//
 2 ,//                               In the case of POW, we don't use the table to tweak 
 2 ,//                               our way to 100% correctness; rather, a post-lookup
 2 ,//                               lattice of conditionals (if / gotos) is used.
 3 ,//
 3 ,//                               In the case of LOG, the 2nd lookup table allows a
 4 ,//                               more precise result, and is warranted. After all, 
 4 ,//                               it eliminates all corner cases but one. As for
 4 ,//                               POW, a second (256-entry) table would be more
 5 ,//                               costly than simply having ~70 conditional jumps, 
 5 ,//                               and might, as seen with LOG, still require corner
 5 ,//                               case logic. So, it is anticipated that the 
 6 ,//                               implementation currently provided is optimal.
 6 ,//
 6 ,//
 7 ,//
 7 ,//
 7 ,//
 8 ,//
 8 ,//
 9 ,//
 9 ,//
 9 ,//
 10 ,
 10 ,
 10 ,
 11 ,
 11 ,
 12 ,
 12 ,
 12 ,
 13 ,
 13 ,
 13 ,
 14 ,
 14 ,
 15 ,
 15 ,
 15 ,
 16 ,
 16 ,
 17 ,
 17 ,
 17 ,
 18 ,
 18 ,
 19 ,
 19 ,
 19 ,
 20 ,
 20 ,
 21 ,
 21 ,
 21 ,
 22 ,
 22 ,
 23 ,
 23 ,
 23 ,
 24 ,
 24 ,
 25 ,
 25 ,
 25 ,
 26 ,
 26 ,
 27 ,
 27 ,
 28 ,
 28 ,
 28 ,
 29 ,
 29 ,
 30 ,
 30 ,
 31 ,
 31 ,
 31 ,
 32 ,
 32 ,
 33 ,
 33 ,
 34 ,
 34 ,
 34 ,
 35 ,
 35 ,
 36 ,
 36 ,
 37 ,
 37 ,
 38 ,
 38 ,
 38 ,
 39 ,
 39 ,
 40 ,
 40 ,
 41 ,
 41 ,
 42 ,
 42 ,
 43 ,
 43 ,
 43 ,
 44 ,
 44 ,
 45 ,
 45 ,
 46 ,
 46 ,
 47 ,
 47 ,
 48 ,
 48 ,
 49 ,
 49 ,
 50 ,
 50 ,
 51 ,
 51 ,
 52 ,
 52 ,
 53 ,
 53 ,
 54 ,
 54 ,
 54 ,
 55 ,
 55 ,
 56 ,
 56 ,
 57 ,
 57 ,
 58 ,
 58 ,
 59 ,
 60 ,
 60 ,
 61 ,
 61 ,
 62 ,
 62 ,
 63 ,
 63 ,
 64 ,
 64 ,
 65 ,
 65 ,
 66 ,
 66 ,
 67 ,
 67 ,
 68 ,
 68 ,
 69 ,
 69 ,
 70 ,
 70 ,
 71 ,
 72 ,
 72 ,
 73 ,
 73 ,
 74 ,
 74 ,
 75 ,
 75 ,
 76 ,
 76 ,
 77 ,
 78 ,
 78 ,
 79 ,
 79 ,
 80 ,
 80 ,
 81 ,
 82 ,
 82 ,
 83 ,
 83 ,
 84 ,
 84 ,
 85 ,
 86 ,
 86 ,
 87 ,
 87 ,
 88 ,
 88 ,
 89 ,
 90 ,
 90 ,
 91 ,
 91 ,
 92 ,
 93 ,
 93 ,
 94 ,
 94 ,
 95 ,
 96 ,
 96 ,
 97 ,
 97 ,
 98 ,
 99 ,
 99 ,
 100 ,
 100 ,
 101 ,
 102 ,
 102 ,
 103 ,
 104 ,
 104 ,
 105 ,
 105 ,
 106 ,
 107 ,
 107 ,
 108 ,
 109 ,
 109 ,
 110 ,
 111 ,
 111 ,
 112 ,
 113 ,
 113 ,
 114 ,
 115 ,
 115 ,
 116 ,
 116 ,
 117 ,
 118 ,
 118 ,
 119 ,
 120 ,
 120 ,
 121 ,
 122 ,
 123 ,
 123 ,
 124 ,
 125 ,
 125 ,
 126 ,
 127 ,
 127
};
/*Define POW16 mem. map*/
#define karg1 loc000
#define karg2 loc001
#define exam loc002
#define util loc003
#define neg loc004
#ifndef FASTMATH
#define minproxy loc007
#endif
void sfp_pow
(
byte min, char ein, 
byte *mout, char *eout
)
{
 karg2=ein;
 if(karg2!=128) goto nonzpow;
 *mout=0;
 *eout=0;
 return;
nonzpow:
 karg1=min;
 neg=0;
 if(!(min&128)) goto n87m7x;
 neg=1;
n87m7x:
 karg1&=127;
 //Discard sign bit of mantissa... b/c our floating point
 // ;format uses a pure sign bit, vs. complementation, this
 // ;is all that is necessary
 karg1|=128;
 if(ein<7) goto gjjm44;
 if(neg)goto gjkm44; 
 *mout=*eout=127;
 return;
gjkm44:
 *mout=0;
 *eout=-128;
 return;
gjjm44:
 if(ein>=-8)goto gjjm45;
 *mout=0;
 *eout=0;
 return;
gjjm45:
 util=0; //karg1 = real mantissa (signless); karg2= ein
 exam=7-karg2;
 if(exam==0)goto shift0b;
 if(exam==1)goto shift1b;
 if(exam==2)goto shift2b;
 if(exam==3)goto shift3b;
 if(exam==4)goto shift4b;
 if(exam==5)goto shift5b;
 if(exam==6)goto shift6b;
 if(exam==7)goto shift7b;
 if(exam==8)goto shift8b; 
 if(exam==9)goto shift9b; 
 if(exam==10)goto shift10b; 
 if(exam==11)goto shift11b; 
 if(exam==12)goto shift12b; 
 if(exam==13)goto shift13b; 
 if(exam==14)goto shift14b; 
shift15b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift14b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift13b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift12b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift11b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift10b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift9b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift8b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift7b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift6b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift5b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift4b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift3b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift2b:
 C=karg1&1;
 karg1/=2;
 util/=2;
 if(C)util|=128;
shift1b:
 C=karg1&1;
 karg1/=2;
 c1=util&1;
 util/=2;
 if(C)util|=128;
 if(!c1) goto shift0b;
 util++; 
shift0b:
 util=fpcorelk2[util];
#ifndef FASTMATH //FASTMATH allows one-bit errors
 minproxy=min&127;
 if(ein!=-8)goto kpr0y0;
 if(minproxy==185) goto kpr0y1;
 if(minproxy==57) goto kpr0y1; 
 if(minproxy==58) goto kpr0y1; 
 if(minproxy==59) goto kpr0y1; 
 if(minproxy==60) goto kpr0y1; 
 if(minproxy==61) goto kpr0y1; 
 if(minproxy==62) goto kpr0y1; 
 if(minproxy==63) goto kpr0y1; 
 goto thepr0;
kpr0y1:
 ++util;
 goto thepr0;
kpr0y0:
 if(ein!=-6)goto kpr0y2;
 if(minproxy==10) goto kpr0y3; 
 if(minproxy==11) goto kpr0y3; 
 if(minproxy==12) goto kpr0y3; 
 if(minproxy==13) goto kpr0y3; 
 if(minproxy==14) goto kpr0y3; 
 if(minproxy==15) goto kpr0y3; 
 if(minproxy==101) goto kpr0y3; 
 if(minproxy==102) goto kpr0y3; 
 if(minproxy==103) goto kpr0y3; 
 if(minproxy==104) goto kpr0y3; 
 if(minproxy==105) goto kpr0y3; 
 if(minproxy==106) goto kpr0y3; 
 if(minproxy==107) goto kpr0y3; 
 if(minproxy==108) goto kpr0y3; 
 if(minproxy==109) goto kpr0y3; 
 if(minproxy==110) goto kpr0y3; 
 if(minproxy==111) goto kpr0y3; 
 goto thepr0;
kpr0y3:
 ++util;
 goto thepr0;
kpr0y2:
 if(ein!=-5)goto kpr0y4;
 if(minproxy==24) goto kpr0y5; 
 if(minproxy==25) goto kpr0y5; 
 if(minproxy==26) goto kpr0y5; 
 if(minproxy==27) goto kpr0y5; 
 if(minproxy==28) goto kpr0y5; 
 if(minproxy==29) goto kpr0y5; 
 if(minproxy==30) goto kpr0y5; 
 if(minproxy==31) goto kpr0y5; 
 if(minproxy==72) goto kpr0y5; 
 if(minproxy==73) goto kpr0y5; 
 if(minproxy==74) goto kpr0y5; 
 if(minproxy==75) goto kpr0y5; 
 if(minproxy==76) goto kpr0y5; 
 if(minproxy==120) goto kpr0y5; 
 goto thepr0;
kpr0y5:
 --util;
 goto thepr0;
kpr0y4:
 if(ein!=-4)goto kpr0y6;
 if(minproxy==60) goto kpr0y7; 
 if(minproxy==61) goto kpr0y7; 
 if(minproxy==124) goto kpr0y7; 
 if(minproxy==125) goto kpr0y7; 
 if(minproxy==126) goto kpr0y7; 
 if(minproxy==19) goto kpr0y8; 
 if(minproxy==41) goto kpr0y8; 
 if(minproxy==42) goto kpr0y8; 
 if(minproxy==43) goto kpr0y8; 
 if(minproxy==105) goto kpr0y8; 
 if(minproxy==106) goto kpr0y8; 
 if(minproxy==107) goto kpr0y8; 
 goto thepr0;
kpr0y7:
 --util;
 goto thepr0;
kpr0y8:
 ++util;
 goto thepr0;
kpr0y6:
 if(ein!=-3)goto kpr0y9;
 if(minproxy==30) goto kpr0y10; 
 if(minproxy==50) goto kpr0y10; 
 if(minproxy==51) goto kpr0y10; 
 if(minproxy==70) goto kpr0y10; 
 if(minproxy==71) goto kpr0y10; 
 if(minproxy==90) goto kpr0y10; 
 if(minproxy==91) goto kpr0y10; 
 if(minproxy==110) goto kpr0y10; 
 if(minproxy==111) goto kpr0y10; 
 if(minproxy==21) goto kpr0y11; 
 if(minproxy==41) goto kpr0y11; 
 goto thepr0;
kpr0y10:
 --util;
 goto thepr0;
kpr0y11:
 ++util;
 goto thepr0;
kpr0y9:
 if(ein!=-2)goto kpr0y12;
 if(minproxy==1) goto kpr0y13; 
 if(minproxy==15) goto kpr0y13; 
 if(minproxy==25) goto kpr0y13; 
 if(minproxy==29) goto kpr0y13; 
 if(minproxy==39) goto kpr0y13; 
 if(minproxy==43) goto kpr0y13; 
 if(minproxy==57) goto kpr0y13; 
 if(minproxy==61) goto kpr0y13; 
 if(minproxy==75) goto kpr0y13; 
 if(minproxy==79) goto kpr0y13; 
 if(minproxy==83) goto kpr0y13; 
 if(minproxy==105) goto kpr0y13; 
 if(minproxy==109) goto kpr0y13; 
 if(minproxy==113) goto kpr0y13; 
 if(minproxy==117) goto kpr0y13; 
 if(minproxy==121) goto kpr0y13; 
 if(minproxy==125) goto kpr0y13; 
 goto thepr0;
kpr0y13:
 --util;
 goto thepr0;
kpr0y12:
thepr0:
#endif
 //
 // karg1 will be return exp, 2nd parm pushed
 //
 // Lookup 2^(util/256), expressed in mantissa form (i.e. 0 means 128), to be ret. 
 // mantissa this will be a single unsigned byte; values less than 128 will have to be 
 // normalized by increasing karg1
 //
 // call FPCoreLook2 
 // banksel karg1
 // movwf util
 *mout=util; 
 *eout=karg1;
 // If the mantissa was negative, this has been denoted by
 // setting neg:0 to 1. Currently, this is handled by pushing
 // #1.0 here and then later calling divf (again based on an
 // examination of neg.)
 //
 // Although expressed as a call here, this is really not 
 // necessarily a true call in any given optimization. Because
 // we've nothing left to do here, we can simply set up the 
 // stack correctly and then execute a GOTO into sfp_divf().
 // It will pop of our caller's return address an return to it
 // naturally.
 if(!neg) goto ycurx5;
 sfp_div(0,0,util,karg1,mout,eout); 
ycurx5:
 ;
}
/*Define NEXT mem. map*/
/*NEXT Returns next largest SFP number in magnitude. Useful for 
  establishing error bounds, etc.*/
#define scratch loc000
void sfp_next
(
byte min, char ein, 
byte *mout, char *eout
)
{ 
 *eout=ein;
 *mout=min; 
 if(((*mout)&127)!=127) goto m0r33n; 
 (*mout)&=0x80;
 (*eout)++;
 goto m0r34d;
 m0r33n:
 (*mout)++;
 m0r34d:;
}
/*Undef. NEXT mem. map*/
#undef scratch

/****************************************************************************************

Testing

This section consists of "main" calling a series of test functions with names like 
sfp_exercise_div() and sfp_exercise_pow(). These functions take one or two IEEE doubles,
which are converted to SFP numbers and passed to one of the operation functions just 
defined in the "primitive C" section above. The result is compared against the result of
the same operation using the original IEEE doubles. The "correct" result is obtained by
taking the IEEE operand(s), obtaining their nearest SFP equivalent(s), and then invoking
the IEEE operation equivalent to the SFP operation being tested. The result (an IEEE 
double) is then converted to its nearest SFP equivalent, and this is the expected return
value of the SFP operation. 

****************************************************************************************/

void sfp_exercise_mul(double f, double f2)
{ 

 byte m; char e;
 byte m2; char e2;
 byte m3; char e3;
 byte mo;
 char eo;

 //IEEE has dedicated "infinity" values with which SFP cannot deal
 if(std::numeric_limits<double>::infinity( )==fabs(f)) return; 
 if(std::numeric_limits<double>::infinity( )==fabs(f2)) return;

 //Express operands in SFP 
 ::sfp_from_ieee(f,&m,&e);
 ::sfp_from_ieee(f2,&m2,&e2);

 //Calculate the closest real number (as IEEE double) to the 
 // "answer" given the fact that the operands will get 
 // approximated using SFP.
 double v=::sfp_to_ieee(m,e)*::sfp_to_ieee(m2,e2);

#ifndef BOUNDSCHECK
 //With checking off, 0 should still be detectable
 if((m==0 || m==128 )&& e==-128) v=0.0;
 if((m2==0 || m2==128 ) && e2==-128) v=0.0;
#endif

 //Routines should return MAXREAL when they exceed it
 if(v>MAXREAL) v=MAXREAL;
 if(v<-MAXREAL) v=-MAXREAL;

 ::sfp_mul(m,e,m2,e2,&mo,&eo);

 ::sfp_print_with_err(mo,eo,v); 

 ::sfp_from_ieee(v,&m3,&e3);

 //Compare the correct answer to the value returned from SFP library
 if(mo!=m3 || eo!=e3)
 {
  printf("%f * %f",f,f2); 
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }

}

void sfp_exercise_div(double f, double f2)
{ 

 byte m; char e;
 byte m2; char e2;
 byte m3; char e3;
 byte mo;
 char eo;

#ifndef BOUNDSCHECK
 //Don't allow /0 when bounds check is off
 if( (float)f2==0.0 ) return;
#endif

 //These don't exist in SFP
 if(std::numeric_limits<double>::infinity( )==fabs(f)) return; 
 if(std::numeric_limits<double>::infinity( )==fabs(f2)) return;

 ::sfp_from_ieee(f,&m,&e);
 ::sfp_from_ieee(f2,&m2,&e2);

 double v=::sfp_to_ieee(m,e)/::sfp_to_ieee(m2,e2);

 if(v>MAXREAL) v=MAXREAL;

 if(v<-MAXREAL) v=-MAXREAL;

 if(fabs(f2)<=pow(2,-128.0)) 
 {
  if(v>0.0) v=MAXREAL; else v=-MAXREAL;
 }

 ::sfp_div(m,e,m2,e2,&mo,&eo);

 ::sfp_print_with_err(mo,eo,v); 

 ::sfp_from_ieee(v,&m3,&e3);

 if(mo!=m3 || eo!=e3)
 { 
  printf("%f / %f",f,f2); 
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }
}

void sfp_exercise_add(double f, double f2)
{

 byte m; char e;
 byte m2; char e2;
 byte m3; char e3;
 byte mo;
 char eo;

 if(std::numeric_limits<double>::infinity( )==fabs(f)) return; 
 if(std::numeric_limits<double>::infinity( )==fabs(f2)) return;

 ::sfp_from_ieee(f,&m,&e);
 ::sfp_from_ieee(f2,&m2,&e2);

 ::sfp_add(m,e,m2,e2,&mo,&eo);

 ::sfp_from_ieee(f,&m,&e); 
 ::sfp_from_ieee(f2,&m2,&e2);

 double errd=::sfp_print_with_err(mo,eo,
 ::sfp_to_ieee(m,e)+::sfp_to_ieee(m2,e2)
 ); 

 double v=::sfp_to_ieee(m,e)+::sfp_to_ieee(m2,e2);

 ::sfp_from_ieee(v,&m3,&e3);

 if(mo!=m3 || eo!=e3)
 {
  // Straddles boundary, forgive... 
  if((2.0*(float)(errd)) <= ((float)(1.0/128.0*pow(2.0,eo))) ) 
  return;

  printf("%f + %f",f,f2); 
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }
}

void sfp_exercise_sub(double f, double f2)
{

 byte m; char e;
 byte m2; char e2;
 byte m3; char e3;
 byte mo;
 char eo;

 if(std::numeric_limits<double>::infinity( )==fabs(f)) return; 
 if(std::numeric_limits<double>::infinity( )==fabs(f2)) return;

 ::sfp_from_ieee(f,&m,&e);
 ::sfp_from_ieee(f2,&m2,&e2);

 ::sfp_sub(m,e,m2,e2,&mo,&eo);

 ::sfp_from_ieee(f,&m,&e); 
 ::sfp_from_ieee(f2,&m2,&e2);

 double errd=::sfp_print_with_err(mo,eo,
 ::sfp_to_ieee(m,e)-::sfp_to_ieee(m2,e2)
 ); 

 double v=::sfp_to_ieee(m,e)-::sfp_to_ieee(m2,e2);

 ::sfp_from_ieee(v,&m3,&e3);

 if(mo!=m3 || eo!=e3)
 {

  // Error is 0.5*epsilon.. straddles boundary, forgive... 
  if((2.0*(float)(errd)) <= ((float)(1.0/128.0*pow(2.0,eo))) ) 
  return;

  printf("%f - %f",f,f2); 
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }

}

void sfp_exercise_log(double f)
{

 byte m,m3; 
 char e,e3;
 byte mo;
 char eo;

 ::sfp_from_ieee(f,&m,&e);

 ::sfp_log(m,e,&mo,&eo);

 ::sfp_from_ieee(f,&m,&e);

 double v=log(::sfp_to_ieee(m,e))/log(2.0l);

 double errd=::sfp_print_with_err(mo,eo,v); 

 ::sfp_from_ieee(v,&m3,&e3);
 if(mo!=m3 || eo!=e3)
 {
  if(eo==e3 && (mo==0||mo==128) && (m3==0||m3==128)) return; //+0 / -0 are equiv.

#ifdef FASTMATH
  if(eo==e3&&(mo-m3==1||mo-m3==-1)) return; //Allow single-bit errors
#endif

  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }
}

void sfp_exercise_convert(byte m, char e)
{
 printf("CONVERTING m=%d, e=%d\n",m,e);
 double f=::sfp_to_ieee(m,e);

 byte m2;

 char e2;
 ::sfp_from_ieee(f,&m2,&e2);
 if(m!=m2 || e!=e2)
 {
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();
 }
}

void sfp_exercise_neg_pow(double f)
{
 byte m,m3; 
 char e,e3;
 byte mo;
 char eo;

 ::sfp_from_ieee(f,&m,&e);

 char eorig=e; 

 ::sfp_pow(m,e,&mo,&eo);

 ::sfp_from_ieee(-f,&m,&e); //m,e hold neg. parm

 double v=pow(2.0l,::sfp_to_ieee(m,e)); //v holds answer for neg parm

 ::sfp_from_ieee(v,&m,&e); //m,e hold answer for neg parm

 v=1.0/::sfp_to_ieee(m,e);

 double errd=::sfp_print_with_err(mo,eo,v); 

 ::sfp_from_ieee(v,&m3,&e3);

 if(mo!=m3 || eo!=e3)
 {
  double eterm=((float)(1.0/128.0*pow(2.0,eo)));
  if((2.0*(float)(errd)) <= eterm) return;

#ifdef FASTMATH
  return; //Not easy to quantify extent to which inaccuracy of FASTMATH 
  // is magnified by sfp_div()... must rely on tests of positive 
  // parms, plus tests of divf, for now.
#endif

  //Logic used to "find" correct answer above will sometimes yield an
  // erroneously high "correct" answer; must rely on tests of positive 
  // parms, plus tests of divf, for now, at least for this one case.
  if(mo==0&&m3==1&&eo==-128&&e3==-128) return;
  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar();

 }

}

void sfp_exercise_pow(double f)
{

 byte m,m3; 
 char e,e3;
 byte mo;
 char eo;

 if(f<0.0){sfp_exercise_neg_pow(f);return;}
 ::sfp_from_ieee(f,&m,&e);

 ::sfp_pow(m,e,&mo,&eo);

 ::sfp_from_ieee(f,&m,&e);

 double v=pow(2.0l,::sfp_to_ieee(m,e));

 double errd=::sfp_print_with_err(mo,eo,v); 

 ::sfp_from_ieee(v,&m3,&e3);

 if(mo!=m3 || eo!=e3)
 {

#ifdef FASTMATH
  if((mo-m3==1||m3-mo==1)&&(eo==e3)) return;
#endif
  double eterm=((float)(1.0/128.0*pow(2.0,eo)));
  if((2.0*(float)(errd)) <= eterm ) return;

  puts("\nEXCEPTION!!! EXCEPTION!!! EXCEPTION!!! EXCEPTION!!! \n");
  getchar(); 
 }
}

//Exercises all calls to setjmp; Must be a macro to get correct addresses
#define SFP_INIT sfp_exercise_add(1.0,1.0);

int main(int argc, char* argv[])
{

 SFP_INIT
 byte m,m2;
 char e,e2; 
 byte ucand_m=0;

/****************************************************************************************
Test Conversions
****************************************************************************************/
 char ucand_e=127;
 do
 {
  ucand_m=0; 
  do
  { 
   ::sfp_exercise_convert(ucand_m,ucand_e);
   if(++ucand_m==0) break; 
  }while(true);
  if(++ucand_e==127) break;
 }while(true);

/****************************************************************************************
Test Logarithms
****************************************************************************************/

 ucand_e=127;

 do
 {

  ucand_m=0; //194
  do
  { 
   double dg=::sfp_to_ieee(ucand_m,ucand_e);
   if(dg>0.0) ::sfp_exercise_log(dg);

   if(++ucand_m==0) break; 

  }while(true);

  if(++ucand_e==127) break;

 }while(true);

/****************************************************************************************
Test Exponentiation
****************************************************************************************/

 int errors=0;
 do
 {

  ucand_m=0; 
  do
  { 
   double dg=::sfp_to_ieee(ucand_m,ucand_e);
   ::sfp_exercise_pow(dg);

   if(++ucand_m==0) break; 

  }while(true);

  if(++ucand_e==127) break; 

 }while(true);

/****************************************************************************************
Test Arithmetic
****************************************************************************************/

 //Allows "/reverse" flag... the arithmetic test routine is very long-running, and
 // feature enables the application of two computers to the chore, one where the SFP
 // executable was started with "/reverse" and the other without. The two computers
 // will attack the problem from opposite ends (a simple form of distributed 
 // computing).

 bool reversed=(argc>1); 

 //Forward direction has cand_e going 127,-128,-127...126
 //Reverse direction has cand_e going 126,125,124...-128,127

 byte cand_m=0, cand_m2=0;

 char cand_e=-128, cand_e2=-128;

 if(reversed) cand_e=126; else cand_e=127; 

 do
 {

  cand_m=0; 
  do
  { 

   cand_e2=127; 
   do
   {
    cand_m2=0; 
    do
    {

     if(!(cand_e2%32) && !cand_m2)
     {
      printf("cand_e=%d cand_m=%d cand_e2=%d cand_m2=%d\n",
      cand_e,cand_m,cand_e2,cand_m2);
      fprintf(stderr,
      "cand_e=%d cand_m=%d cand_e2=%d cand_m2=%d\n",
      cand_e,cand_m,cand_e2,cand_m2);
     }

     //Test all SFP ops 
     double dg=::sfp_to_ieee(cand_m,cand_e);
     double dg2=::sfp_to_ieee(cand_m2,cand_e2);

#ifndef BOUNDSCHECK 
     // Range of unchecked functions listed as 2^(double)-126 to 
     // 2^(double)125
     if(fabs(dg+dg2)>=::powf(((double)2.0),(double)-126.0) &&
       fabs(dg+dg2)<=::powf(((double)2.0),(double)125.0) )
#endif
     {
      ::sfp_exercise_add(dg,dg2);
     }

#ifndef BOUNDSCHECK
     if(fabs(dg-dg2)>=::powf(((double)2.0),(double)-126.0) &&
       fabs(dg-dg2)<=::powf(((double)2.0),(double)125.0) )
#endif 
     {
      ::sfp_exercise_sub(dg,dg2);
     }

#ifndef BOUNDSCHECK
     if(fabs(dg*dg2)>=::powf(((double)2.0),(double)-126.0) &&
       fabs(dg*dg2)<=::powf(((double)2.0),(double)125.0) )
#endif
     {
      ::sfp_exercise_mul(dg,dg2);
     }

#ifndef BOUNDSCHECK
     if(fabs(dg/dg2)>=::powf(((double)2.0),(double)-126.0) &&
       fabs(dg/dg2)<=::powf(((double)2.0),(double)125.0) )
#endif
     {
      ::sfp_exercise_div(dg,dg2);
     }

     if(++cand_m2==0) break; 
    }while(true);

    if(++cand_e2==127) break; 

   }while(true);

   if(++cand_m==0) break; 
  }while(true);

  if(reversed)
  {
   if(--cand_e==126) break; 
  }
  else
  {
   if(++cand_e==127) break; 
  }

 }while(true);

 puts("Test complete.");
 getchar(); 
 return 0;

}
