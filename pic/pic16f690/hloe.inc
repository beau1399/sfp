
#define HLOE_STACK_SIZE .80
#define HLOE_STACK2_SIZE .80
#include <p16f690.inc>
#include <kernel.inc>
#ifndef HLOE_KERNEL_INC
 EXTERN stack, alt_stack, alt_fsr, hloe3, savesp, in_isr, savesp2, W_Save, STATUS_Save
 EXTERN FSR_Save, ALT_Save 
#endif
 
 
