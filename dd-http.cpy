	*>
	*> (c)2026 Ira Parsons
	*> dd-http.cpy - http data structures
	*>

    01 HTTP-OPTIONS.
	    05 HTTP-STATUS-CODE         PIC 9(3) COMP-5.
		05 HTTP-REASON-TEXT.
		    10 HTTP-REASON-TEXT-LEN PIC S9(5) COMP-5.
			10 HTTP-REASON-TEXT-DAT PIC X(32).