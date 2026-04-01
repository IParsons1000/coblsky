*>
*> (c)2026 Ira Parsons
*> http.cbl - http processing routines
*>

*>***************************************************************************
*>* HTTP-HANDLE
*>*  - Parse HTTP message and respond accordingly
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. HTTP-HANDLE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I        PIC S9(5) COMP-5. *> int
	01 A        PIC S9(5) COMP-5. *> int

    01 REQ-TYPE PIC 9.

	COPY dd-string REPLACING ==(PFX)== BY ==CRLF-STR==.
	COPY dd-string REPLACING ==(PFX)== BY ==CURR-LINE==.
	01 CURR-LINE-OFF PIC S9(5) COMP-5 VALUE 1. *> offset of current line in packet data
	
	COPY dd-string REPLACING ==(PFX)== BY ==REQUEST-TARGET==.

	COPY dd-string REPLACING ==(PFX)== BY ==FDEL-STR==.
	COPY dd-string REPLACING ==(PFX)== BY ==FIELD-KEY==.
	COPY dd-string REPLACING ==(PFX)== BY ==FIELD-VAL==.

	COPY dd-string REPLACING ==(PFX)== BY ==TEMP==.

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-PACKET.

    PERFORM HANDLE-SETUP.

    *> handle header
    PERFORM HANDLE-STATUS-LINE.
	PERFORM HANDLE-FIELD-LINES.

    *> act accordingly
	PERFORM HANDLE-BODY.

    GOBACK.

HANDLE-SETUP.
    *> reinitialize variables
	MOVE 0 TO I.
	MOVE 0 TO A.
	MOVE 0 TO CURR-LINE-LEN.
	MOVE 1 TO CURR-LINE-OFF.

    *> http line delimeter
    MOVE 2 TO CRLF-STR-LEN.
	MOVE X"0D0A" TO CRLF-STR-DAT(1:2).

    *> http field delimeter
	MOVE 2 TO FDEL-STR-LEN.
	MOVE ": " TO FDEL-STR-DAT(1:2).

    EXIT PARAGRAPH.

HANDLE-STATUS-LINE.
    *> parse status line
    PERFORM HANDLE-GETLINE.

    IF I EQUALS -1 THEN
	    GOBACK.

	*> extract method
	CALL "STRING-STRCHR" USING CURR-LINE-STRING, BY VALUE " ", BY REFERENCE A.

    IF A IS LESS THAN 1 THEN
	    GOBACK.

    EVALUATE PACKET-DATA(1:A - 1)
	    WHEN "GET"
		    MOVE 0 TO REQ-TYPE
		WHEN "POST"
		    MOVE 1 TO REQ-TYPE
		WHEN OTHER
		    GOBACK
	END-EVALUATE.

    *> extract request target
	ADD 1 TO A.
	COMPUTE TEMP-LEN = CURR-LINE-LEN - A;
	MOVE CURR-LINE-DAT(A:TEMP-LEN) TO TEMP-DAT.
	CALL "STRING-STRCHR" USING TEMP-STRING, BY VALUE " ", BY REFERENCE I.

    IF I EQUALS -1 THEN
	    GOBACK.

    COMPUTE REQUEST-TARGET-LEN = I - 1;
    MOVE CURR-LINE-DAT(A:REQUEST-TARGET-LEN) TO REQUEST-TARGET-DAT.
	ADD I TO A.

    *> extract http version
	COMPUTE TEMP-LEN = CURR-LINE-LEN - A;
	MOVE CURR-LINE-DAT(A:TEMP-LEN) TO TEMP-DAT.

    IF (TEMP-LEN IS LESS THAN 8) OR (TEMP-DAT(1:8) NOT EQUALS "HTTP/1.1") THEN
	    GOBACK.

    EXIT-PARAGRAPH.

HANDLE-FIELD-LINES.
    *> evaluate field lines
	PERFORM HANDLE-GETLINE.

    IF I EQUALS -1 THEN
	    GOBACK.

    PERFORM UNTIL CURR-LINE-LEN IS LESS THAN 3
	    *> read in key and value
	    CALL "STRING-STRSTR" USING CURR-LINE-STRING, FDEL-STR-STRING, I

        IF I EQUALS -1 THEN
		    GOBACK
        END-IF

		COMPUTE FIELD-KEY-LEN = I - FDEL-STR-LEN;
		MOVE CURR-LINE-DAT(1:FIELD-KEY-LEN) TO FIELD-KEY-DAT
		ADD 1 TO I
		COMPUTE FIELD-VAL-LEN = CURR-LINE-LEN - CRLF-STR-LEN - FIELD-KEY-LEN - FDEL-STR-LEN;
		MOVE CURR-LINE-DAT(I:FIELD-VAL-LEN) TO FIELD-VAL-DAT

		*> act on header	
		EVALUATE FIELD-KEY-DAT(1:FIELD-KEY-LEN)
		    WHEN "Host"
			    CONTINUE
		    WHEN OTHER
			    CONTINUE
		END-EVALUATE

        *> load next line
        PERFORM HANDLE-GETLINE

        IF I EQUALS -1 THEN
		    GOBACK
		END-IF
	END-PERFORM.

    *> look for end of header
	IF CURR-LINE-LEN NOT EQUALS 2 THEN
	    DISPLAY CURR-LINE-LEN
	    GOBACK.

    EXIT-PARAGRAPH.

HANDLE-BODY.
    *> load body
	ADD CURR-LINE-LEN TO CURR-LINE-OFF.

	IF CURR-LINE-OFF IS GREATER THAN OR EQUAL TO PACKET-LEN THEN
	    MOVE 0 TO TEMP-LEN
	ELSE
		COMPUTE TEMP-LEN = PACKET-LEN - CURR-LINE-OFF;
		MOVE PACKET-DATA(CURR-LINE-OFF:TEMP-LEN) TO TEMP-DAT.

    *> process request
	EVALUATE REQUEST-TARGET-DAT
	    WHEN "/"
			MOVE 18 TO TEMP-LEN
			MOVE z"<html>test</html>" TO TEMP-DAT(1:18)
		    CONTINUE
		WHEN OTHER
		    CONTINUE
    END-EVALUATE.

    CALL "HTTP-PACKAGE" USING BY REFERENCE NETWORK-PACKET, BY VALUE "200", BY REFERENCE TEMP-STRING.

    EXIT-PARAGRAPH.

HANDLE-GETLINE.
    *> find end of line
	ADD CURR-LINE-LEN TO CURR-LINE-OFF.
	COMPUTE TEMP-LEN = PACKET-LEN - CURR-LINE-OFF + 1;
	MOVE PACKET-DATA(CURR-LINE-OFF:TEMP-LEN) TO TEMP-DAT.
	CALL "STRING-STRSTR" USING TEMP-STRING, CRLF-STR-STRING, I.

	IF I EQUALS -1 THEN
	    EXIT PARAGRAPH.

	MOVE I TO CURR-LINE-LEN.
	MOVE PACKET-DATA(CURR-LINE-OFF:CURR-LINE-LEN) TO CURR-LINE-DAT.

    EXIT PARAGRAPH.

END PROGRAM HTTP-HANDLE.

*>***************************************************************************
*>* HTTP-PACKAGE
*>*  - Form status and body into http message
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. HTTP-PACKAGE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 STATUS-CODE-STR PIC X(3).

    COPY dd-string REPLACING ==(PFX)== BY ==CRLF-STR==.

LINKAGE SECTION.

    COPY dd-network.

    01 STATUS-CODE PIC X(3).

    COPY dd-string REPLACING ==(PFX)== BY ==BODY==.

PROCEDURE DIVISION USING NETWORK-PACKET, STATUS-CODE, BODY-STRING.

    PERFORM PACKAGE-SETUP.

    *> create header
	PERFORM PACKAGE-STATUS-LINE.
	PERFORM PACKAGE-FIELD-LINES.

    *> add body
	PERFORM PACKAGE-BODY.

    GOBACK.

PACKAGE-SETUP.

    *> clear packet
	MOVE 0 TO PACKET-LEN.
	MOVE 1 TO I.

    EXIT PARAGRAPH.

PACKAGE-STATUS-LINE.

    *> add version
	ADD 8 TO PACKET-LEN.
	MOVE "HTTP/1.1" TO PACKET-DATA(I:8).
	ADD 8 TO I.

    ADD 1 TO PACKET-LEN.
	MOVE " " TO PACKET-DATA(I:1).
	ADD 1 TO I.

    *> add status code
	ADD 3 TO PACKET-LEN.
	MOVE STATUS-CODE(1:3) TO PACKET-DATA(I:3).
	ADD 3 TO I.

    ADD 1 TO PACKET-LEN.
	MOVE " " TO PACKET-DATA(I:1).
	ADD 1 TO I.

    *> add reason string
	EVALUATE STATUS-CODE
	    WHEN 200
		    ADD 2 TO PACKET-LEN
			MOVE "OK" TO PACKET-DATA(I:2)
			ADD 2 TO I
		WHEN OTHER
		    CONTINUE
	END-EVALUATE.

    *> add crlf
	ADD 2 TO PACKET-LEN.
	MOVE X"0D0A" TO PACKET-DATA(I:2).
	ADD 2 TO I.

    EXIT PARAGRAPH.

PACKAGE-FIELD-LINES.

    *> add headers (placeholder)
	PERFORM 0 TIMES
		*> add field name
		*> ADD KEY-LEN TO PACKET-LEN
		*> MOVE KEY-DAT(1:KEY-LEN) TO PACKET-DATA(I:KEY-LEN)
		*> ADD KEY-LEN TO I

		*> add delimeter
		ADD 2 TO PACKET-LEN
		MOVE ": " TO PACKET-DATA(I:2)
		ADD 2 TO I

		*> add field value
		*> ADD VAL-LEN TO PACKET-LEN
		*> MOVE VAL-DAT(1:VAL-LEN) TO PACKET-DATA(I:VAL-LEN)
		*> ADD VAL-LEN TO I
		*> add crlf

		ADD 2 TO PACKET-LEN
		MOVE X"0D0A" TO PACKET-DATA(I:2)
		ADD 2 TO I
	END-PERFORM.

    *> add blank line
	ADD 2 TO PACKET-LEN.
	MOVE X"0D0A" TO PACKET-DATA(I:2).
	ADD 2 TO I.

    EXIT PARAGRAPH.

PACKAGE-BODY.

    ADD BODY-LEN TO PACKET-LEN.
	MOVE BODY-DAT(1:BODY-LEN) TO PACKET-DATA(I:BODY-LEN).

    EXIT PARAGRAPH.

END PROGRAM HTTP-PACKAGE.
