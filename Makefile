#
# (c)2026 Ira Parsons
# coblsky makefile
#

CBLC ?= gcobol

CBLFLAGS ?=
CBLFLAGS += -g -O2
CBLFLAGS += -dialect ibm

LDFLAGS ?=
LDFLAGS += -lssl -lcrypto

RM ?= rm -rf

.PHONY: keygen clean remake

all: coblsky

coblsky:
	$(CBLC) $(CBLFLAGS) -o coblsky -main coblsky.cbl network.cbl $(LDFLAGS)

keygen:
	openssl genrsa -out server.key 2048
	openssl req -new -x509 -key server.key -out server.crt -days 365 -subj "/C=US/ST=Test/L=Local/O=DevOrg/OU=Dev/CN=localhost"

clean:
	$(RM) coblsky *.o

remake: clean all
