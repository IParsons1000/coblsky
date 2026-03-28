*>
*> (c)2026 Ira Parsons
*> network.cbl - networking routines
*>

*>***************************************************************************
*>* NETWORK-INIT
*>*  - Perform networking-specific initialization tasks
*>*  - Create OpenSSL context
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-INIT.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5 VALUE 0. *> int

    01 SSL-METHOD       PIC 9(10) COMP-5.    *> (void *) SSL_METHOD

    01 SSL_FILETYPE_PEM PIC 9(5) COMP-5 VALUE 1.
	01 SSL-CERT-FILE    PIC X(11) VALUE z"server.crt".
    01 SSL-PKEY-FILE    PIC X(11) VALUE z"server.key".

    01 SSL-ERR-BUF      PIC X(256).
	01 SSL-ERR-NUM      PIC 9(5) COMP-5. *> long

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SSL-CONTEXT.

    *> setup ssl context
    PERFORM INIT-TLS.

    GOBACK.

>>CALL-CONVENTION C
INIT-TLS.
	*> create ssl context
	CALL "TLS_server_method" RETURNING SSL-METHOD.
	CALL "SSL_CTX_new" USING BY VALUE SSL-METHOD RETURNING NETWORK-SSL-CONTEXT.

	IF NETWORK-SSL-CONTEXT EQUALS 0 THEN
        PERFORM INIT-TLS-ERR
		EXIT PARAGRAPH.

	*> configure context
	CALL "SSL_CTX_use_certificate_file" USING BY VALUE NETWORK-SSL-CONTEXT, BY REFERENCE SSL-CERT-FILE, BY VALUE SSL_FILETYPE_PEM RETURNING I.

	IF I NOT EQUALS 1 THEN
		PERFORM INIT-TLS-ERR
		EXIT PARAGRAPH.

	CALL "SSL_CTX_use_PrivateKey_file" USING BY VALUE NETWORK-SSL-CONTEXT, BY REFERENCE SSL-PKEY-FILE, BY VALUE SSL_FILETYPE_PEM RETURNING I.

	IF I NOT EQUALS 1 THEN
		PERFORM INIT-TLS-ERR
		EXIT PARAGRAPH.

	EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

>>CALL-CONVENTION C
INIT-TLS-ERR.
    *> retrieve ssl error string
	CALL "ERR_get_error" RETURNING SSL-ERR-NUM.
	CALL "ERR_error_string_n" USING BY VALUE SSL-ERR-NUM, BY REFERENCE SSL-ERR-BUF, BY VALUE 256.

    DISPLAY SSL-ERR-BUF.

	MOVE 0 TO NETWORK-SSL-CONTEXT.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

END PROGRAM NETWORK-INIT.

*>***************************************************************************
*>* NETWORK-OPEN
*>*  - Create socket
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-OPEN.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 PORT            PIC 9(5) COMP-5.  *> int
	01 INADDR_ANY      PIC 9(5) COMP-5.  *> int
	01 AF_INET         PIC 9(5) COMP-5.  *> int
	01 SOCK_STREAM     PIC 9(5) COMP-5.  *> int
	01 SOL_SOCKET      PIC 9(5) COMP-5.  *> int
	01 SO_REUSEADDR    PIC 9(5) COMP-5.  *> int
	01 BACKLOG         PIC 9(5) COMP-5.  *> int

	01 SOCKOPT_VAL_LEN PIC 9(5) COMP-5.  *> size_t

	01 I               PIC S9(5) COMP-5. *> int
	
	01 PERROR-SOCKET   PIC A(7) VALUE z"socket".
	01 PERROR-SOCKOPT  PIC A(11) VALUE z"setsockopt".
	01 PERROR-BIND     PIC A(5) VALUE z"bind".
	01 PERROR-LISTEN   PIC A(7) VALUE z"listen".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SOCKET.

    *> configure socket
	IF SIN-PORT EQUALS 0 THEN
	    IF SOCK-SECURED EQUALS 1 THEN
		    MOVE 443 TO PORT *> HTTPS port
		ELSE
	        MOVE 8080 TO PORT. *> HTTP port
			*>MOVE 80 TO PORT. *> HTTP port

	MOVE 0 TO INADDR_ANY. *> INADDR_ANY
	MOVE 2 TO AF_INET. *> AF_INET
	MOVE 1 TO SOCK_STREAM. *> SOCK_STREAM
	MOVE 1 TO SOL_SOCKET. *> SOL_SOCKET
	MOVE 2 TO SO_REUSEADDR. *> SO_REUSEADDR
	MOVE 64 TO BACKLOG. *> BACKLOG
	
	MOVE AF_INET TO SIN-FAMILY.
	CALL "htons" USING BY VALUE PORT RETURNING SIN-PORT.
	CALL "htonl" USING BY VALUE INADDR_ANY RETURNING SIN-ADDR.
	
	MOVE LENGTH OF SOCKADDR-IN TO SOCKADDR-IN-LEN.

	*> create socket
	CALL "socket" USING BY VALUE AF_INET, BY VALUE SOCK_STREAM, BY VALUE 0 RETURNING SOCK-FD. *> create tcp socket

	IF SOCK-FD EQUALS -1 THEN
		CALL "perror" USING PERROR-SOCKET
	    GOBACK.
	
	*> set socket options to allow server restarts
	*> reusing SOCK_STREAM = 1 = sockopt val
	MOVE LENGTH OF SOCK_STREAM TO SOCKOPT_VAL_LEN.
	CALL "setsockopt" USING BY VALUE SOCK-FD, SOL_SOCKET, SO_REUSEADDR, BY REFERENCE SOCK_STREAM, BY VALUE SOCKOPT_VAL_LEN RETURNING I.

	IF I NOT EQUALS 0 THEN
		CALL "perror" USING PERROR-SOCKOPT
	    MOVE -1 TO SOCK-FD
		GOBACK.
	
	*> bind socket
	CALL "bind" USING BY VALUE SOCK-FD, BY REFERENCE SOCKADDR-IN, BY VALUE SOCKADDR-IN-LEN RETURNING I.

	IF I NOT EQUALS 0 THEN
		CALL "perror" USING PERROR-BIND
		MOVE -1 TO SOCK-FD
		GOBACK.
	
	*> listen on socket
	CALL "listen" USING BY VALUE SOCK-FD, BACKLOG RETURNING I.

	IF I NOT EQUALS 0 THEN
		CALL "perror" USING PERROR-LISTEN
		MOVE -1 TO SOCK-FD
		GOBACK.
		
	GOBACK.
	
END PROGRAM NETWORK-OPEN.

*>***************************************************************************
*>* NETWORK-CONNECT
*>*  - Accept a new connection on a given socket
*>*  - Perform TLS handshake if required
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-CONNECT.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5 VALUE 0. *> int

    01 SSL-ERR-BUF      PIC X(256).
	01 SSL-ERR-NUM      PIC 9(5) COMP-5. *> long

	01 PERROR-ACCEPT  PIC A(7)  VALUE z"accept".
	01 PERROR-CLOSE   PIC A(12) VALUE z"close(conn)".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SSL-CONTEXT, NETWORK-SOCKET, NETWORK-CONNECTION.

CONNECT-ACCEPT.
	*> accept connection
	CALL "accept" USING BY VALUE SOCK-FD, BY REFERENCE SOCKADDR-IN, SOCKADDR-IN-LEN RETURNING CONN-FD.
	
	IF CONN-FD EQUALS -1 THEN
		CALL "perror" USING PERROR-ACCEPT
		GOBACK.

    IF SOCK-SECURED EQUALS 1 THEN
	    PERFORM CONNECT-TLS.

    GOBACK.

>>CALL-CONVENTION C
CONNECT-TLS.
	*> init tls on socket
	CALL "SSL_new" USING BY VALUE NETWORK-SSL-CONTEXT RETURNING CONN-SSL.

	IF CONN-SSL EQUALS 0 THEN
		PERFORM CONNECT-TLS-ERR
		EXIT PARAGRAPH.

	CALL "SSL_set_fd" USING BY VALUE CONN-SSL, BY VALUE CONN-FD.

    *> wait for handshake
	CALL "SSL_accept" USING BY VALUE CONN-SSL RETURNING I.
	IF I NOT EQUALS 1 THEN
		PERFORM CONNECT-TLS-ERR
		EXIT PARAGRAPH.

	EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

>>CALL-CONVENTION C
CONNECT-TLS-ERR.
    *> retrieve ssl error string
	CALL "ERR_get_error" RETURNING SSL-ERR-NUM.
	CALL "ERR_error_string_n" USING BY VALUE SSL-ERR-NUM, BY REFERENCE SSL-ERR-BUF, BY VALUE 256.

    DISPLAY SSL-ERR-BUF.

	*> close connection
	CALL "close" USING BY VALUE CONN-FD RETURNING I.

	IF I EQUALS -1 THEN
		CALL "perror" USING PERROR-CLOSE.

    MOVE -1 TO CONN-FD.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

END PROGRAM NETWORK-CONNECT.

*>***************************************************************************
*>* NETWORK-RECEIVE
*>*  - Read packet from connection
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-RECEIVE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I       PIC S9(5) COMP-5.             *> int
    01 BUFSIZE PIC S9(5) COMP-5 VALUE 65536. *> int

	01 SSL-ERR-BUF    PIC X(256).
	01 SSL-ERR-NUM    PIC 9(5) COMP-5. *> long

	01 PERROR-READ    PIC A(5) VALUE z"read".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-CONNECTION, NETWORK-PACKET.

    *> read packet
    IF CONN-SSL NOT EQUALS 0 THEN
	    PERFORM RECEIVE-TLS
	ELSE
	    PERFORM RECEIVE-RAW.

	GOBACK.

RECEIVE-RAW.
	CALL "read" USING BY VALUE CONN-FD, BY REFERENCE PACKET-DATA, BY VALUE BUFSIZE RETURNING PACKET-LEN.

	IF PACKET-LEN EQUALS -1 THEN
	    CALL "perror" USING PERROR-READ.

    EXIT PARAGRAPH.

>>CALL-CONVENTION C
RECEIVE-TLS.
    CALL "SSL_read" USING BY VALUE CONN-SSL, BY REFERENCE PACKET-DATA, BY VALUE BUFSIZE RETURNING PACKET-LEN.

    IF PACKET-LEN EQUALS -1 THEN
		*> retrieve ssl error string
		CALL "ERR_get_error" RETURNING SSL-ERR-NUM
		CALL "ERR_error_string_n" USING BY VALUE SSL-ERR-NUM, BY REFERENCE SSL-ERR-BUF, BY VALUE 256

		DISPLAY SSL-ERR-BUF.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

END PROGRAM NETWORK-RECEIVE.

*>***************************************************************************
*>* NETWORK-SEND
*>*  - Write packet to socket
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-SEND.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

	01 PERROR-WRITE PIC A(6) VALUE z"write".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SSL-CONTEXT, NETWORK-CONNECTION, NETWORK-PACKET.

    *> write packet
	CALL "write" USING BY VALUE CONN-FD, BY REFERENCE PACKET-DATA, BY VALUE PACKET-LEN RETURNING I.
	
	IF I EQUALS -1 THEN
	    CALL "perror" USING PERROR-WRITE.
	
	GOBACK.

END PROGRAM NETWORK-SEND.

*>***************************************************************************
*>* NETWORK-DISCONNECT
*>*  - Close connection
*>*  - Free OpenSSL structures associated with socket
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-DISCONNECT.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int

	01 SSL-ERR-BUF      PIC X(256).
	01 SSL-ERR-NUM      PIC 9(5) COMP-5. *> long

	01 PERROR-CLOSE PIC A(12) VALUE z"close(conn)".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-CONNECTION.

    *> disconnect tls
	IF CONN-SSL NOT EQUALS 0 THEN
	    PERFORM DISCONNECT-TLS.

    *> close connection
	CALL "close" USING BY VALUE CONN-FD RETURNING I.

    IF I EQUALS -1 THEN
        CALL "perror" USING PERROR-CLOSE.
	
	GOBACK.

>>CALL-CONVENTION C
DISCONNECT-TLS.
    *> teardown ssl context
	MOVE 0 TO I.
	PERFORM UNTIL I NOT EQUALS 0
	    CALL "SSL_shutdown" USING BY VALUE CONN-SSL RETURNING I
	END-PERFORM.

	IF I IS LESS THAN 0 THEN
	    PERFORM DISCONNECT-TLS-ERR.

    *> free ssl memory structures
    CALL "SSL_free" USING BY VALUE CONN-SSL.

    *> reset pointer
	MOVE 0 TO CONN-SSL.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

>>CALL-CONVENTION C
DISCONNECT-TLS-ERR.
    *> retrieve ssl error string
	CALL "ERR_get_error" RETURNING SSL-ERR-NUM.
	CALL "ERR_error_string_n" USING BY VALUE SSL-ERR-NUM, BY REFERENCE SSL-ERR-BUF, BY VALUE 256.

    DISPLAY SSL-ERR-BUF.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

END PROGRAM NETWORK-DISCONNECT.

*>***************************************************************************
*>* NETWORK-CLOSE
*>*  - Close socket
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-CLOSE.

DATA DIVISION.
WORKING-STORAGE SECTION.

    01 I PIC S9(5) COMP-5. *> int
	
	01 PERROR-CLOSE PIC A(12) VALUE z"close(sock)".

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SOCKET.

    *> close socket
    CALL "close" USING BY VALUE SOCK-FD RETURNING I.

    IF I EQUALS -1 THEN
        CALL "perror" USING PERROR-CLOSE.

    GOBACK.

END PROGRAM NETWORK-CLOSE.

*>***************************************************************************
*>* NETWORK-FINI
*>*  - Network-specific shutdown tasks
*>*  - Free OpenSSL context
*>***************************************************************************

IDENTIFICATION DIVISION.
PROGRAM-ID. NETWORK-FINI.

DATA DIVISION.

LINKAGE SECTION.

    COPY dd-network.

PROCEDURE DIVISION USING NETWORK-SSL-CONTEXT.

    PERFORM FINI-TLS.

    GOBACK.

>>CALL-CONVENTION C
FINI-TLS.
    *> teardown ssl
    CALL "SSL_CTX_free" USING BY VALUE NETWORK-SSL-CONTEXT.

    EXIT PARAGRAPH.
>>CALL-CONVENTION COBOL

END PROGRAM NETWORK-FINI.
