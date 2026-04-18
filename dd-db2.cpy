	*>
	*> (c)2026 Ira Parsons
	*> dd-db2.cpy - db2 data structures
	*>

    01 DB-CONNECTION.
        05 SQLCA SYNC.
            10 SQLCAID      PIC X(8)  VALUE "SQLCA   ".
            10 SQLCABC      PIC S9(9) COMP-5 VALUE 136.
            10 SQLCODE      PIC S9(9) COMP-5.
            10 SQLERRM.
                15 SQLERRML PIC S9(4) COMP-5.
                15 SQLERRMC PIC X(70).
            10 SQLERRP      PIC X(8).
            10 SQLERRD OCCURS 6 TIMES PIC S9(9) COMP-5.
            10 SQLWARN.
                15 SQLWARN0 PIC X.
                15 SQLWARN1 PIC X.
                15 SQLWARN2 PIC X.
                15 SQLWARN3 PIC X.
                15 SQLWARN4 PIC X.
                15 SQLWARN5 PIC X.
                15 SQLWARN6 PIC X.
                15 SQLWARN7 PIC X.
                15 SQLWARN8 PIC X.
                15 SQLWARN9 PIC X.
                15 SQLWARNA PIC X.
            10 SQLSTATE     PIC X(5).
