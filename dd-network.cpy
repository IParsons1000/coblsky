	*>
	*> (c)2026 Ira Parsons
	*> dd-network.cpy - networking data structures
	*>

    01 NETWORK-SSL-CONTEXT      PIC 9(10) COMP-5. *> void*

	01 NETWORK-SOCKET.
		05 SOCKADDR-IN.
			10 SIN-FAMILY       PIC 9(2)  COMP-5. *> 2 bytes
			10 SIN-PORT         PIC 9(2)  COMP-5. *> 2 bytes
			10 SIN-ADDR         PIC 9(5)  COMP-5. *> 4 bytes
			10 SIN-ZEROES       PIC 9(10) COMP-5. *> Alignment padding (8)
		05 SOCKADDR-IN-LEN      PIC 9(5)  COMP-5. *> 4 bytes
		05 SOCK-SECURED         PIC 9     COMP-5. *> bool
		05 SOCK-FD              PIC S9(5) COMP-5. *> int

	01 NETWORK-CONNECTION.
	    05 CONN-FD              PIC S9(5) COMP-5. *> int
		05 CONN-SSL             PIC 9(10) COMP-5. *> void*

	01 NETWORK-PACKET.
	    05 PACKET-LEN           PIC 9(5)  COMP-5. *> int
		05 PACKET-DATA          PIC X(65536).     *> char[65536]