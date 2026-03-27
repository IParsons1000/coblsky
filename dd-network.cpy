	*>
	*> (c)2026 Ira Parsons
	*> dd-network.cpy - networking data structures
	*>
	
	01 NETWORK-SHARED.
		05 SOCKADDR-IN.
			10 SIN-FAMILY       PIC 9(2)  COMP-5. *> 2 bytes
			10 SIN-PORT         PIC 9(2)  COMP-5. *> 2 bytes
			10 SIN-ADDR         PIC 9(5)  COMP-5. *> 4 bytes
			10 SIN-ZEROES       PIC 9(10) COMP-5. *> Alignment padding
		05 SOCKADDR-IN-LEN      PIC 9(5)  COMP-5. *> 4 bytes
		
		05 SOCK-FD              PIC S9(5) COMP-5. *> int
		
	01 NETWORK-PACKET.
	    05 CONN-FD              PIC S9(5) COMP-5. *> int
	    05 PACKET-LEN           PIC 9(5)  COMP-5. *> int
		05 PACKET-DATA OCCURS 1 to 65536 TIMES
		  DEPENDING ON PACKET-LEN PIC X.          *> char[65536]