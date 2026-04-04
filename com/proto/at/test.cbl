*>
*> (c)2026 Ira Parsons
*> test.cbl - com.proto.at.test lexicon handler
*>

*>***************************************************************************
*>* COM-PROTO-AT-TEST
*>*  - Handle request to com.proto.at.test
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. COM-PROTO-AT-TEST.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 TEST-REQUEST.
	    05 TEST-FIELD PIC X(256).

    COPY dd-string REPLACING ==(PFX)== BY ==KEY==.
    COPY dd-string REPLACING ==(PFX)== BY ==VAL==.

    01 ERR-INVALID-REQUEST PIC X(256) VALUE z"InvalidRequest".
	01 MSG-INVALID-REQUEST PIC X(256) VALUE z"Your request was invalid.".

LINKAGE SECTION.

    COPY dd-http.

    COPY dd-string REPLACING ==(PFX)== BY ==BODY==.

PROCEDURE DIVISION USING HTTP-OPTIONS, BODY-STRING.

>>IF USE_CJSON EQUAL 1
    MOVE z"test" TO KEY-DAT.
	MOVE 5 TO KEY-LEN.
    CALL "JSON-PARSE" USING BODY-STRING, KEY-STRING, VAL-STRING.
>>ELSE
    JSON PARSE BODY-STRING
	    *> globbed weirdly because gcobol can't behave itself
	    INTO TEST-REQUEST NAME TEST-REQUEST IS OMITTED
		ON EXCEPTION GOBACK
	END-JSON.
>>END-IF

    IF VAL-LEN EQUAL -1 THEN
	    GOBACK.

    CALL "XRPC-THROW-ERROR" USING BODY-STRING, ERR-INVALID-REQUEST, MSG-INVALID-REQUEST.

    GOBACK.

END PROGRAM COM-PROTO-AT-TEST.
