*>
*> (c)2026 Ira Parsons
*> xrpc.cbl - xrpc processing routines
*>

*>***************************************************************************
*>* XRPC-HANDLE
*>*  - Parse and respond to xrpc request
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. XRPC-HANDLE.

DATA DIVISION.
LINKAGE SECTION.

    COPY dd-http.

    COPY dd-string REPLACING ==(PFX)== BY ==TARGET==.

    COPY dd-string REPLACING ==(PFX)== BY ==BODY==.

PROCEDURE DIVISION USING HTTP-OPTIONS, TARGET-STRING, BODY-STRING.

    DISPLAY "XRPC Endpoint: " TARGET-DAT(1:TARGET-LEN).

    GOBACK.

END PROGRAM XRPC-HANDLE.
