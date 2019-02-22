
#define HLOE_STACK_SIZE .80
#define HLOE_STACK2_SIZE .80
#include <p16f1827.inc>

#include <kernel16f1827.inc>

#ifndef HLOE_KERNEL_INC 
 EXTERN stack, alt_stack, hloe3, savesp, in_isr, savesp2, W_Save, STATUS_Save, FSR_Save
#endif