//----------------------------------------------------------------------
// mywc.s
// Author: Tobias Seabold and Sasha Allen
//----------------------------------------------------------------------

        .equ    FALSE, 0
        .equ    TRUE, 1
        .equ    EOF, -1

//----------------------------------------------------------------------
        .section .rodata


printfMessageStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------

        .section .data

lLineCount:
        .quad   0
lWordCount:
        .quad   0
lCharCount:
        .quad   0
iInWord:
        .quad   FALSE


//----------------------------------------------------------------------
        .section .bss

iChar:
        .skip   4 
	

//----------------------------------------------------------------------
        .section .text

        //--------------------------------------------------------------
        // Read ARRAY_LENGTH integers from stdin, and write them in
        // reverse order to stdout. Return 0.
        //--------------------------------------------------------------

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main

main:
        // Prolog
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

startofloop1:
	// if((iChar = getchar()) == EOF) goto finalIf;
	bl      getchar
        	adr     x0, iChar
        	str    w0, [x0]
        	ldr     x0, [x0]
        	cmp     x0, EOF
        	beq     finalIf

	// lCharCount++;
	adr     x0, lCharCount
            ldr     x1, [x0]
            add     x1, x1, 1
            str     x1, [x0]


	// if (isspace(iChar)) goto space;
	ldr     x0, [sp, iChar]
        	bl      isspace
        	cmp     x0, 1
        	beq     space


	// if (!iInWord) goto notSpaceNotInWord;
	adr     x0, [sp, iInWord]
            ldr     x0, [x0]
            cmp     x0, 0
            beq    notSpaceNotInWord

	// goto lastPartofLoop;
	b       lastPartofLoop

space:
	// if (iInWord) goto spaceInWord;
	adr     x0, iInWord
            ldr     x0, [x0]
            cmp     x0, 0
            bgt    notSpaceNotInWord

	// goto lastPartofLoop;
	b       lastPartofLoop

spaceInWord:
	// lWordCount++;
	adr     x0, lWordCount
            ldr     x1, [x0]
            add     x1, x1, 1
            str     x1, [x0]


            // iInWord = FALSE;
	mov     x0, FALSE
       	adr     x1, iInWord
        	str     w0, [x1]

	// goto lastPartofLoop;
	b       lastPartofLoop

notSpaceNotInWord:
	// iInWord = TRUE;
	mov     x0, TRUE
       	adr     x1, iInWord
        	str     w0, [x1]

// goto lastPartofLoop;
b       lastPartofLoop

lastPartofLoop:
	// if (iChar != '\n') goto startofloop1;
	adr     x0, iChar
            ldr     x0, [x0]
            cmp     x0, [0x0A]
            bne    startofloop1


	// lLineCount++;
	adr     x0, lLineCount
            ldr     x1, [x0]
            add     x1, x1, 1
            str     x1, [x0]

// goto startofloop1;
b       startofloop1

finalIf:
	// if (!iInWord) goto endfinalIf;
	adr     x0, iInWord
            ldr     x0, [x0]
            cmp     x0, 0
            beq    notSpaceNotInWord

// lWordCount++;
adr     x0, lWordCount
            ldr     x1, [x0]
            add     x1, x1, 1
            str     x1, [x0]

// goto endfinalIf;
b       endfinalIf

endfinalIf:
// printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
adr     x0, printfMessageStr
adr     x1, lLineCount
ldr     w1, [x1]
adr     x2, lWordCount
ldr     w2, [x2]
adr     x3, lCharCount
ldr     w3, [x3]
bl      printf

// Epilog and return 0
mov     w0, 0
ldr     x30, [sp]
add     sp, sp, MAIN_STACK_BYTECOUNT
ret
.size   main, (. - main)	