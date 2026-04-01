*>
*> (c)2026 Ira Parsons
*> string.cbl - string processing routines
*>

*> gcobol chokes on returning clauses, so everything's passing a pointer for now

*>***************************************************************************
*>* STRING-STRCHR
*>*  - Find first appearance of character within string
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. STRING-STRCHR.

DATA DIVISION.
LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==STR==.

    01 C PIC X.

	01 I PIC S9(5) COMP-5. *> int

PROCEDURE DIVISION USING STR-STRING, C, I.

    PERFORM VARYING I FROM 1 BY 1 UNTIL (I IS GREATER THAN STR-LEN) OR (STR-DAT(I:1) EQUALS C)
	    CONTINUE
	END-PERFORM.

    IF I IS GREATER THAN STR-LEN THEN
	    MOVE -1 TO I.

    GOBACK.

END PROGRAM STRING-STRCHR.

*>***************************************************************************
*>* STRING-STRSTR
*>*  - Find first appearance of substring within string
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. STRING-STRSTR.

DATA DIVISION.
LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==SRC==.
	COPY dd-string REPLACING ==(PFX)== BY ==DST==.

	01 I PIC S9(5) COMP-5. *> int

PROCEDURE DIVISION USING SRC-STRING, DST-STRING, I.

    PERFORM VARYING I FROM 1 BY 1 UNTIL (I IS GREATER THAN (SRC-LEN - DST-LEN + 1)) OR (SRC-DAT(I:DST-LEN) EQUALS DST-DAT(1:DST-LEN))
	    CONTINUE
	END-PERFORM.

    IF I IS GREATER THAN (SRC-LEN - DST-LEN + 1) THEN
	    MOVE -1 TO I
	ELSE
	    COMPUTE I = I + DST-LEN - 1;

    GOBACK.

END PROGRAM STRING-STRSTR.
