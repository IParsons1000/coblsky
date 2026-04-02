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
LINKAGE SECTION.

    COPY dd-http.

    COPY dd-string REPLACING ==(PFX)== BY ==BODY==.

PROCEDURE DIVISION USING HTTP-OPTIONS, BODY-STRING.

    GOBACK.

END PROGRAM COM-PROTO-AT-TEST.
