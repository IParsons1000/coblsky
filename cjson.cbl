*>
*> (c)2026 Ira Parsons
*> cjson.cbl - json processing routines (cJSON)
*>

*> this is a placeholder until regular cobol json parsing support is added to gcobol
*>  or the compiler is changed

*>***************************************************************************
*>* JSON-PARSE
*>*  - Return value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-PARSE.

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

>>CALL-CONVENTION C
    *> load json
	CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUALS 0 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    *> load item
	CALL "cJSON_GetObjectItem" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUALS 0 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ITEM, BY REFERENCE VAL-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUALS 1 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    CALL "strlen" USING VAL-DAT RETURNING VAL-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-PARSE.

*>***************************************************************************
*>* JSON-GENERATE
*>*  - Insert value associated with key in json object
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. JSON-GENERATE.

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

>>CALL-CONVENTION C
    *> load json
    IF JSON-LEN IS GREATER THAN 0 THEN
	    CALL "cJSON_Parse" USING JSON-DAT RETURNING CJSON-ROOT
	ELSE
	    CALL "cJSON_CreateObject" RETURNING CJSON-ROOT.

    IF CJSON-ROOT EQUALS 0 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    *> create item
	CALL "cJSON_CreateString" USING VAL-DAT RETURNING CJSON-ITEM.

    IF CJSON-ITEM EQUALS 0 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    *> load item
	CALL "cJSON_AddItemToObject" USING BY VALUE CJSON-ROOT, BY REFERENCE KEY-STRING, BY VALUE CJSON-ITEM.

    *> convert item to something readable
	CALL "cJSON_PrintPreallocated" USING BY VALUE CJSON-ROOT, BY REFERENCE JSON-DAT, BY VALUE 2048, BY VALUE 0 RETURNING I.

    IF I NOT EQUALS 1 THEN
	    MOVE -1 TO VAL-LEN
		GOBACK.

    CALL "strlen" USING JSON-DAT RETURNING JSON-LEN.

	*> cleanup
	CALL "cJSON_Delete" USING BY VALUE CJSON-ROOT.
>>CALL-CONVENTION COBOL

    GOBACK.

END PROGRAM JSON-GENERATE.
