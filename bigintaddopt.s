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
        LLARGER .req x19

        // Parameter stack offsets:
        LLENGTH2 .req x21
  
        LLENGTH1 .req x20

        .global BigInt_larger
        
        
        
BigInt_larger:
 
		// Prolog
        sub     sp, sp, LARGER_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, 8]
        str     x20, [sp, 16]
        str     x21, [sp, 24]


        mov     LLENGTH1, x0
        mov     LLENGTH2, x1

        // long lLarger;
        // if (lLength1 < lLength2) goto length1Smaller;
        cmp     LLENGTH1, LLENGTH2
        blt     length1Smaller
        
        // lLarger = lLength1;
        mov LLARGER, LLENGTH1
				
			  // goto endLarger;
			  b    endLarger
			      
	length1Smaller:
			  // lLarger = lLength2;
        mov LLARGER, LLENGTH2
			  
			  // goto endLarger;
			 b endLarger
			      
	endLarger:
	      // Epilog and return lLarger
        mov     x0, LLARGER
        ldr     x30, [sp]
        ldr     x19, [sp, 8]
        ldr     x20, [sp, 16]
        ldr     x21, [sp, 24]
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
        ULCARRY .req x19
        ULSUM .req x20
        LINDEX .req x21
        LSUMLENGTH .req x22

        // Parameter stack offsets:                                                                                                                                                                             
        OSUM .req x23
        OADDEND2 .req x24
        OADDEND1 .req x25
        LLENGTH  .req x26
// Prolog
        sub     sp, sp, ADD_STACK_BYTECOUNT
        str     x30, [sp]
        str     x19, [sp, 8]
        str     x20, [sp, 16]
        str     x21, [sp, 24]
        str     x22, [sp, 32]
        str     x23, [sp, 40]
        str     x24, [sp, 48]
        str     x25, [sp, 56]
        str     x26, [sp, 64]
        mov    OADDEND1, x0
        mov    OADDEND2, x1
        mov    OSUM, x2

        
        // unsigned long ulCarry;
				// unsigned long ulSum;
			  // long lIndex;
			  // long lSumLength;
			  
			  /* Determine the larger length. */
        // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
        

        mov x0, OADDEND1
        mov x1, OADDEND2
	    bl      BigInt_larger
	    mov LSUMLENGTH, x0
        // x0 contains lSumLength?
        // x1 contains lSumLength address?
        
        /* Clear oSum's array if necessary. */
        // if (oSum->lLength <= lSumLength) goto endClear;
        cmp     OSUM, LSUMLENGTH
        ble     endClear
        
        // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        mov x0, OSUM
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
        mov     ULCARRY, 0
        mov     LINDEX, 0
			  
loopAddition:
        // if (!(lIndex < lSumLength)) goto endLoopAddition;
        cmp     LINDEX, LSUMLENGTH
        bge     endLoopAddition
        // ulSum = ulCarry;
        mov    ULSUM, ULCARRY
        // ulCarry = 0;
        mov     ULCARRY, 0
			  
			  // ulSum += oAddend1->aulDigits[lIndex];
	// mov     x0, [sp, ULSUM] // x0 is ulSum
        mov     x0, ULSUM
        mov     x1, LINDEX
        // mov     x1, [sp, LINDEX] // x1 is lIndex
        // mov     x2, [sp, OADDEND1] // x2 is oAddend1
        mov     x2, OADDEND1
				add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x3 is oAddend1->aulDigits[lIndex]
        // ldr     x0, [sp, ULSUM]
        mov     x0, ULSUM

        add     x0, x0, x3 // updates ulSum in x0
        // str x0, [sp, ULSUM]
        mov ULSUM, x0

	// if (ulSum >= oAddend1->aulDigits[lIndex]) goto noOverflow1; /* Check for overflow. */
        // ldr x0, [sp, ULSUM]
        mov x0, ULSUM

        // added code
        // ldr     x1, [sp, LINDEX] // x1 is lIndex
        mov x1, LINDEX
        // ldr     x2, [sp, OADDEND1] // x2 is oAddend1
        mov x2, OADDEND1
	add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x3 is oAddend1->aulDigits[lIndex]

        cmp x0, x3
        bhs noOverflow1
        // ulCarry = 1;
        mov     ULCARRY, 1

        // goto noOverflow1;
        b noOverflow1
        
noOverflow1:
        // ulSum += oAddend2->aulDigits[lIndex];
        //ldr     x0, [sp, ULSUM] // x0 is ulSum
        mov     x0, ULSUM
        // ldr     x1, [sp, LINDEX] // x1 is lIndex
        mov     x1, LINDEX
        // ldr     x2, [sp, OADDEND2] // x2 is oAddend1
        mov     x2, OADDEND2
	add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x2 is oAddend1->aulDigits[lIndex]
        add     x0, x0, x3 // updates ulSum in x0

        // if (ulSum < oAddend2->aulDigits[lIndex]) goto noOverflow2; /* Check for overflow. */
        // str x0, [sp, ULSUM]
        mov ULSUM, x0
        // ldr x0, [sp, ULSUM]
        mov x0, ULSUM

         // added code
        // ldr     x1, [sp, LINDEX] // x1 is lIndex
        mov     x1, LINDEX
        // ldr     x2, [sp, OADDEND2] // x2 is oAddend1
        mov     x2, OADDEND2
	add     x2, x2, 8 // offset to reach oAddend1->aulDigits
        ldr     x3, [x2, x1, lsl 3] // x2 is oAddend1->aulDigits[lIndex]

        cmp x0, x3
        bhs noOverflow2 //bhs?
        // ulCarry = 1;
        mov     x4, 1
        // str     x4, [sp, ULCARRY]
        mov     ULCARRY, x4
        // goto noOverflow2;
			  b noOverflow2

noOverflow2:
				// oSum->aulDigits[lIndex] = ulSum;

        // ldr     x0, [sp, OSUM] // x0 is oSum
        mov     x0, OSUM
        // ldr     x1, [sp, LINDEX] // x1 is lIndex
        mov     x1, LINDEX
        add     x0, x0, 8 // offset to reach oSum->aulDigits
        // ldr     x2, [sp, ULSUM] // x2 is ulSum
        mov     x2, ULSUM
        str     x2, [x0, x1, lsl 3] // x2 is oSum->aulDigits[lIndex]
				// lIndex++;
	// ldr     x0, [sp, LINDEX]
        mov     x0, LINDEX
        add     x0, x0, 1
        // str     x0, [sp, LINDEX]
        mov LINDEX, x0
        // goto loopAddition;
        b loopAddition

endLoopAddition:
/* Check for a carry out of the last "column" of the addition. */
        // if (ulCarry != 1) goto endCarryOut
        cmp     ULCARRY, 1
        bne     endCarryOut
        // if (lSumLength != MAX_DIGITS) goto endMaxDigits;
        cmp     LSUMLENGTH, MAX_DIGITS
        bne     endMaxDigits
        // return FALSE;
        mov     w0, FALSE
        ldr     x30, [sp]
        ldr     x19, [sp, 8]
        ldr     x20, [sp, 16]
        ldr     x21, [sp, 24]
        ldr     x22, [sp, 32]
        ldr     x23, [sp, 40]
        ldr     x24, [sp, 48]
        ldr     x25, [sp, 56]
        ldr     x26, [sp, 64]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret
        // goto endMaxDigits;
 endMaxDigits:
        // oSum->aulDigits[lSumLength] = 1;
        // ldr     x0, [sp, OSUM] // x0 is oSum
        mov     x0, OSUM
        // ldr     x1, [sp, LSUMLENGTH] // x1 is lSumLength
        mov     x1, LSUMLENGTH
        add     x0, x0, 8 // offset to reach oSum->aulDigits
				mov     x2, 1
        str     x2, [x0, x1, lsl 3] // x2 is oSum->aulDigits[lSumLength]
        // lSumLength++;
        // ldr     x0, [sp, LSUMLENGTH]
        mov     x0, LSUMLENGTH
        add     x0, x0, 1
        // str     x0, [sp, LSUMLENGTH]
        mov     LSUMLENGTH, x0
        // goto endCarryOut;
        b endCarryOut
 endCarryOut:
				/* Set the length of the sum. */
			  // oSum->lLength = lSumLength;
	// ldr     x0, [sp, OSUM] // x0 is oSum
        mov     x0, OSUM
        // ldr     x1, [sp, LSUMLENGTH] // x1 is lSumLength
        mov     x1, LSUMLENGTH
        str     x1, [x0]
			  
			  // return TRUE;
			  mov     w0, 1
	ldr     x30, [sp]
        ldr     x19, [sp, 8]
        ldr     x20, [sp, 16]
        ldr     x21, [sp, 24]
        ldr     x22, [sp, 32]
        ldr     x23, [sp, 40]
        ldr     x24, [sp, 48]
        ldr     x25, [sp, 56]
        ldr     x26, [sp, 64]
        add     sp, sp, ADD_STACK_BYTECOUNT
        ret

        .size   BigInt_add, (. - BigInt_add)	
			  
