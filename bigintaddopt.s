/*--------------------------------------------------------------------*/
/* bigintadd.s                                                        */
/* Author: Sasha Allen and Tobias Seabold                                            */
/*--------------------------------------------------------------------*/
        .equ    FALSE, 0
        .equ    TRUE, 1
        .equ    MAX_DIGITS, 32768
//----------------------------------------------------------------------
        .section .rodata

//----------------------------------------------------------------------
        .section .data


//----------------------------------------------------------------------
        .section .bss
	
//----------------------------------------------------------------------
        .section .text

        //--------------------------------------------------------------
        /* Return the larger of lLength1 and lLength2. */
        //--------------------------------------------------------------

        // Must be a multiple of 16
        .equ    LARGER_STACK_BYTECOUNT, 32
        
        // Local variable stack offsets:
        .equ    LLARGER, 8
        LLARGER .req x19

        // Parameter stack offsets:
        .equ    LLENGTH2,   16
        LLENGTH2 .req x21
        .equ    LLENGTH1,    24
        LLENGTH1 .req x20

        .global BigInt_larger
        
        
BigInt_larger:
 
		// Prolog
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
//        str     x20, [sp, LLENGTH1]
  //      str     x21, [sp, LLENGTH2]

        // long lLarger;
     
			  // if (lLength1 < lLength2) goto length1Smaller;
        cmp     x0, x1
        blt     length1Smaller
        
        // lLarger = lLength1;
        ldr     x0, [x20]
        str     x0, [x19]
				
			  // goto endLarger;
			  b    endLarger
			      
	length1Smaller:
			  // lLarger = lLength2;
        str     x21, [x19]
			  
			  // goto endLarger;
			 b endLarger
			      
	endLarger:
	      // Epilog and return lLarger
        ldr     x0, [x19]
        ldr     x30, [sp]
        add     sp, sp, LARGER_STACK_BYTECOUNT
        ret

        .size    BigInt_larger, (. -  BigInt_larger)
 

        //--------------------------------------------------------------
        /* Assign the sum of oAddend1 and oAddend2 to oSum.  oSum should be
		       distinct from oAddend1 and oAddend2.  Return 0 (FALSE) if an
           overflow occurred, and 1 (TRUE) otherwise. */
        //--------------------------------------------------------------

  
        .global BigInt_add

BigInt_add:

                // Must be a multiple of 16                                                                                                                                                                             
        .equ    ADD_STACK_BYTECOUNT, 64

	// Local variables stack offsets:                                                                                                                                                                       
        .equ    ULCARRY,  8
        .equ    ULSUM,    16
        .equ    LINDEX,   24
        .equ    LSUMLENGTH, 32

        // Parameter stack offsets:                                                                                                                                                                             
        .equ    OSUM,     40
        .equ    OADDEND2, 48
        .equ    OADDEND1, 56
        .equ LLENGTH, 0
// Prolog
        sub     sp, sp, ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x0, [sp, OADDEND1]
        str     x1, [sp, OADDEND2]
        str     x2, [sp, OSUM]

        
        // unsigned long ulCarry;
				// unsigned long ulSum;
			  // long lIndex;
			  // long lSumLength;
			  
			  /* Determine the larger length. */
		    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
	        ldr     x0, [sp, OADDEND1]
            ldr     x0, [x0]
	        ldr     x1, [sp, OADDEND2]
            ldr     x1, [x1]
			bl      BigInt_larger
	        str x0, [sp, LSUMLENGTH]
        // x0 contains lSumLength?
        // x1 contains lSumLength address?
        
        /* Clear oSum's array if necessary. */
        // if (oSum->lLength <= lSumLength) goto endClear;
        ldr     x2, [sp, OSUM]
        ldr     x1, [x2]
        ldr     x0, [sp, LSUMLENGTH]
        cmp     x1, x0
        ble     endClear
        
        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        ldr x0, [sp, OSUM]
        add x0, x0, 8
        mov w1, 0
        mov  x2, MAX_DIGITS
        lsl x2, x2, 3 
        bl memset

              
        // goto endClear;
        b endClear
        
endClear:
        /* Perform the addition. */
			  // ulCarry = 0;
			  // lIndex = 0;
		mov     x2, 0
        str     x2, [sp, ULCARRY]
        mov     x3, 0
        str     x3, [sp, LINDEX]
			  
loopAddition:
        // if (!(lIndex < lSumLength)) goto endLoopAddition;
        ldr     x0, [sp, LSUMLENGTH]
        ldr     x1, [sp, LINDEX]
        cmp     x1, x0
        bge     endLoopAddition
        // ulSum = ulCarry;
        ldr     x0, [sp, ULCARRY]
        str     x0, [sp, ULSUM]
        // ulCarry = 0;
        mov     x1, 0
        str     x1, [sp, ULCARRY]
			  
			  // ulSum += oAddend1->aulDigits[lIndex];
			  ldr     x0, [sp, ULSUM] // x0 is ulSum
        ldr     x1, [sp, LINDEX] // x1 is lIndex
        ldr     x2, [sp, OADDEND1] // x2 is oAddend1
				add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x3 is oAddend1->aulDigits[lIndex]
        ldr     x0, [sp, ULSUM]

        add     x0, x0, x3 // updates ulSum in x0
        str x0, [sp, ULSUM]

	// if (ulSum >= oAddend1->aulDigits[lIndex]) goto noOverflow1; /* Check for overflow. */
        ldr x0, [sp, ULSUM]

        // added code
        ldr     x1, [sp, LINDEX] // x1 is lIndex
        ldr     x2, [sp, OADDEND1] // x2 is oAddend1
		add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x3 is oAddend1->aulDigits[lIndex]

        cmp x0, x3
        bhs noOverflow1
        // ulCarry = 1;
        mov     x3, 1
        str     x3, [sp, ULCARRY]
        // goto noOverflow1;
        b noOverflow1
        
noOverflow1:
        // ulSum += oAddend2->aulDigits[lIndex];
        ldr     x0, [sp, ULSUM] // x0 is ulSum
        ldr     x1, [sp, LINDEX] // x1 is lIndex
        ldr     x2, [sp, OADDEND2] // x2 is oAddend1
		add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x2 is oAddend1->aulDigits[lIndex]
        add     x0, x0, x3 // updates ulSum in x0

        // if (ulSum < oAddend2->aulDigits[lIndex]) goto noOverflow2; /* Check for overflow. */
        str x0, [sp, ULSUM]
        ldr x0, [sp, ULSUM]

         // added code
        ldr     x1, [sp, LINDEX] // x1 is lIndex
        ldr     x2, [sp, OADDEND2] // x2 is oAddend1
		add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x2 is oAddend1->aulDigits[lIndex]

        cmp x0, x3
        bhs noOverflow2 //bhs?
        // ulCarry = 1;
        mov     x4, 1
        str     x4, [sp, ULCARRY]
        // goto noOverflow2;
			  b noOverflow2

noOverflow2:
				// oSum->aulDigits[lIndex] = ulSum;
				ldr     x0, [sp, OSUM] // x0 is oSum
				ldr     x1, [sp, LINDEX] // x1 is lIndex
				add     x0, x0, 8 // offset to reach oSum->aulDigits
				ldr     x2, [sp, ULSUM] // x2 is ulSum
        str     x2, [x0, x1, lsl 3] // x2 is oSum->aulDigits[lIndex]
				// lIndex++;
				ldr     x0, [sp, LINDEX]
        add     x0, x0, 1
        str     x0, [sp, LINDEX]
        // goto loopAddition;
        b loopAddition

endLoopAddition:
				/* Check for a carry out of the last "column" of the addition. */
			  // if (ulCarry != 1) goto endCarryOut;
			  ldr     x0, [sp, ULCARRY] // x0 is ulCarry
        cmp     x0, 1
        bne     endCarryOut
        // if (lSumLength != MAX_DIGITS) goto endMaxDigits;
        ldr     x0, [sp, LSUMLENGTH]
        cmp     x0, MAX_DIGITS
        bne     endMaxDigits
        // return FALSE;
        mov     w0, FALSE
        ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret
        // goto endMaxDigits;
 endMaxDigits:
        // oSum->aulDigits[lSumLength] = 1;
        ldr     x0, [sp, OSUM] // x0 is oSum
				ldr     x1, [sp, LSUMLENGTH] // x1 is lSumLength
				add     x0, x0, 8 // offset to reach oSum->aulDigits
				mov     x2, 1
        str     x2, [x0, x1, lsl 3] // x2 is oSum->aulDigits[lSumLength]
        // lSumLength++;
        ldr     x0, [sp, LSUMLENGTH]
        add     x0, x0, 1
        str     x0, [sp, LSUMLENGTH]
        // goto endCarryOut;
        b endCarryOut
 endCarryOut:
				/* Set the length of the sum. */
			  // oSum->lLength = lSumLength;
	ldr     x0, [sp, OSUM] // x0 is oSum
			  ldr     x1, [sp, LSUMLENGTH] // x1 is lSumLength
			  str     x1, [x0]
			  
			  // return TRUE;
			  mov     w0, 1
			  ldr     x30, [sp]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)	
			  
