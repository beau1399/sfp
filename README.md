# SFP

SFP is a 16-bit floating point type and associated library. It is "symmetrical" in that it uses 8 bits for the mantissa and 8 bits for the exponent. 

This has the advantage of simplifying the implementation of the library code on 8-bit devices. To that same end, the provided C++ code is written (outside of unit tests) using a branch-based, 8-bit subset of the C++ language which is designed to be hand-assembled for even the most primitive of devices, with relative ease.

In addition to the reference C++ implementation, an assembly language implementation written in Microchip Technology "PIC" assembly language is provided. This targets the 8-bit "mid range" device families, whose names typically start with "16" or "18."

Here are some highlights of the SFP system presented here:

* Super-wide dynamic range (10<sup>39</sup>)
* 2.4 digit precision
* Fully shift-based multiply and divide
* Table-based logarithm and exponentiation functions
* Correct rounding of results to nearest SFP approximation
* Fully covered by included unit tests
* Exhaustively exercised in distributed testing
* Symmetrical design reduces bit arithmetic
* 15-byte peak memory usage (plus code)
* Flat function call model (zero internal calls)
* Optional reentrant implementation
* Three lightweight, non-conformant subsets
* Modular design; each operation is free-standing

Visit the [project site](http://beauscode.blogspot.com/2013/01/sfp-portable-lightweight-real-number.html).
