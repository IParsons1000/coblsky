*>
*> (c)2026 Ira Parsons
*> cjson.cbl - json processing routines (cJSON)
*>

*> this is a placeholder until regular cobol json parsing support is added to gcobol
*>  or the compiler is changed

*>***************************************************************************
*>* JSON-PARSE-STRING
*>*  - Return string value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-PARSE-STRING.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.
    COPY dd-string REPLACING ==(PFX)== BY ==KEY==.
    COPY dd-string REPLACING ==(PFX)== BY ==VAL==.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-STRING.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
	CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_GetObjectItem" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ITEM, BY REFERENCE VAL-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING VAL-DAT RETURNING VAL-LEN.

    *> remove quotes
    MOVE VAL-DAT(2:VAL-LEN - 1) TO VAL-DAT(1:VAL-LEN - 2).
    SUBTRACT 2 FROM VAL-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-PARSE-STRING.

*>***************************************************************************
*>* JSON-PARSE-INT
*>*  - Return integer value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-PARSE-INT.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

    COPY dd-string REPLACING ==(PFX)== BY ==VAL==.

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.
    COPY dd-string REPLACING ==(PFX)== BY ==KEY==.
    01 VAL-NUM PIC S9(5) COMP-5.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-NUM.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
	CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_GetObjectItem" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
		GOBACK.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ITEM, BY REFERENCE VAL-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING VAL-DAT RETURNING VAL-LEN.

    *> cast
    COMPUTE VAL-NUM = FUNCTION NUMVAL(VAL-DAT(1:VAL-LEN));

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-PARSE-INT.

*>***************************************************************************
*>* JSON-PARSE-DOUBLE
*>*  - Return double value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-PARSE-DOUBLE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

    COPY dd-string REPLACING ==(PFX)== BY ==VAL==.

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.
    COPY dd-string REPLACING ==(PFX)== BY ==KEY==.
    01 VAL-NUM USAGE IS COMP-2.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-NUM.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
	CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_GetObjectItem" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
		GOBACK.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ITEM, BY REFERENCE VAL-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING VAL-DAT RETURNING VAL-LEN.

    *> cast
    COMPUTE VAL-NUM = FUNCTION NUMVAL(VAL-DAT(1:VAL-LEN));

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-PARSE-DOUBLE.

*>***************************************************************************
*>* JSON-GENERATE-STRING
*>*  - Insert string value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-GENERATE-STRING.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.

    01 KEY-STRING PIC X(256).

    COPY dd-string REPLACING ==(PFX)== BY ==VAL==.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-STRING.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
    IF JSON-LEN IS GREATER THAN 0 THEN
	    CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT
	ELSE
	    CALL "cJSON_CreateObject" RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> create item
	CALL "cJSON_CreateString" USING VAL-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_AddItemToObject" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-STRING, BY VALUE CJSON-ITEM.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ROOT, BY REFERENCE JSON-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING JSON-DAT RETURNING JSON-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-GENERATE-STRING.

*>***************************************************************************
*>* JSON-GENERATE-INT
*>*  - Insert integer value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-GENERATE-INT.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

    01 VAL-DBL USAGE IS COMP-2.

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.

    01 KEY-STRING PIC X(256).

    01 VAL-NUM PIC S9(5) COMP-5.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-NUM.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
    IF JSON-LEN IS GREATER THAN 0 THEN
	    CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT
	ELSE
	    CALL "cJSON_CreateObject" RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> create item
    MOVE VAL-NUM TO VAL-DBL.
	CALL "cJSON_CreateNumber" USING VAL-DBL RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_AddItemToObject" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-STRING, BY VALUE CJSON-ITEM.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ROOT, BY REFERENCE JSON-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING JSON-DAT RETURNING JSON-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-GENERATE-INT.

*>***************************************************************************
*>* JSON-GENERATE-DOUBLE
*>*  - Insert double value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-GENERATE-DOUBLE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

    01 CJSON-ROOT PIC 9(10) COMP-5. *> void*
    01 CJSON-ITEM PIC 9(10) COMP-5. *> void*

LINKAGE SECTION.

    COPY dd-string REPLACING ==(PFX)== BY ==JSON==.

    01 KEY-STRING PIC X(256).

    01 VAL-NUM USAGE IS COMP-2.

PROCEDURE DIVISION USING JSON-STRING, KEY-STRING, VAL-NUM.

>>IF GCOBOL IS DEFINED
>>CALL-CONVENTION C
>>END-IF
*>>>IF COBC IS DEFINED
*>>>CALL-CONVENTION STDCALL
*>>>END-IF
    *> load json
    IF JSON-LEN IS GREATER THAN 0 THEN
	    CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT
	ELSE
	    CALL "cJSON_CreateObject" RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUAL 0 THEN
		GOBACK.

    *> create item
	CALL "cJSON_CreateNumber" USING VAL-NUM RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUAL 0 THEN
		GOBACK.

    *> load item
	CALL "cJSON_AddItemToObject" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-STRING, BY VALUE CJSON-ITEM.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ROOT, BY REFERENCE JSON-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUAL 1 THEN
		GOBACK.

    CALL "strlen" USING JSON-DAT RETURNING JSON-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-GENERATE-DOUBLE.
