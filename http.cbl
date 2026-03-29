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
	01 PREV-WRD PIC S9(5) COMP-5. *> int
    01 LINE-END PIC S9(5) COMP-5. *> int

    01 REQ-TYPE PIC 9.

	COPY dd-string REPLACING ==(PFX)== BY ==CRLF-STR==.
	COPY dd-string REPLACING ==(PFX)== BY ==REQUEST-TARGET==.
	COPY dd-string REPLACING ==(PFX)== BY ==TEMP==.

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-PACKET.

    MOVE 2 TO CRLF-STR-LEN.
	MOVE X"0D0A" TO CRLF-STR-DAT(1:2).

    *> parse status line
	CALL "STRING-STRSTR" USING NETWORK-PACKET, CRLF-STR-STRING, LINE-END.

	IF LINE-END EQUALS -1 THEN
	    GOBACK.

	*> extract method
	MOVE LINE-END TO TEMP-LEN.
	MOVE PACKET-DATA(1:LINE-END) TO TEMP-DAT.
	CALL "STRING-STRCHR" USING TEMP-STRING, BY VALUE " ", BY REFERENCE PREV-WRD.

    IF PREV-WRD IS LESS THAN 1 THEN
	    GOBACK.

    EVALUATE PACKET-DATA(1:PREV-WRD - 1)
	    WHEN "GET"
		    MOVE 0 TO REQ-TYPE
		WHEN "POST"
		    MOVE 1 TO REQ-TYPE
		WHEN OTHER
		    GOBACK
	END-EVALUATE.

    *> extract request target
	ADD 1 TO PREV-WRD.
	COMPUTE TEMP-LEN = LINE-END - PREV-WRD.
	MOVE PACKET-DATA(PREV-WRD:TEMP-LEN) TO TEMP-DAT.
	CALL "STRING-STRCHR" USING TEMP-STRING, BY VALUE " ", BY REFERENCE I.

    IF I EQUALS -1 THEN
	    GOBACK.

    COMPUTE REQUEST-TARGET-LEN = I - 1.
    MOVE PACKET-DATA(PREV-WRD:REQUEST-TARGET-LEN) TO REQUEST-TARGET-DAT.
	ADD I TO PREV-WRD.

    *> extract http version
	COMPUTE TEMP-LEN = LINE-END - PREV-WRD - 2.
	MOVE PACKET-DATA(PREV-WRD:LINE-END - PREV-WRD) TO TEMP-DAT.

    IF (TEMP-LEN IS LESS THAN 8) OR (TEMP-DAT(1:TEMP-LEN) NOT EQUALS "HTTP/1.1") THEN
	    GOBACK.

    *> evaluate headers
	DISPLAY REQUEST-TARGET-DAT(1:REQUEST-TARGET-LEN).

    GOBACK.

END PROGRAM HTTP-HANDLE.
