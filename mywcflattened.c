/*--------------------------------------------------------------------*/
/* mywc.c                                                             */
/* Author: Bob Dondero                                                */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long lLineCount = 0;      /* Bad style. */
static long lWordCount = 0;      /* Bad style. */
static long lCharCount = 0;      /* Bad style. */
static int iChar;                /* Bad style. */
static int iInWord = FALSE;      /* Bad style. */

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

int main(void)
{
   startofloop1:
	if((iChar = getchar()) != EOF) goto finalIf;
	lCharCount++;
	if (isspace(iChar)) goto space;
	if (!iInWord) goto notSpaceNotInWord;
	goto lastPartofLoop;

space:
	if (iInWord) goto spaceInWord;
	goto lastPartofLoop;

spaceInWord:
	lWordCount++;
            iInWord = FALSE;
	goto lastPartofLoop;

notSpaceNotInWord:
	iInWord = TRUE;
goto lastPartofLoop;

lastPartofLoop:
	if (iChar != '\n') goto startofloop1;
	lLineCount++;

finalIf:
	if (!iInWord) goto endfinalIf;
lWordCount++;
goto endfinalIf;

endfinalIf:
printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
return 0;	
}
