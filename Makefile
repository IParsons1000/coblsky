#
# (c)2026 Ira Parsons
# coblsky makefile
#

CBLC ?= gcobol

CBLFLAGS ?=
CBLFLAGS += -g -O3
CBLFLAGS += -dialect ibm

LDFLAGS ?=
LDFLAGS += -lssl -lcrypto

SRC := coblsky.cbl network.cbl http.cbl string.cbl xrpc.cbl

RM ?= rm -rf

CRTFILE ?= server.crt
KEYFILE ?= server.key

KEYLEN ?= 2048

.PHONY: keygen clean remake

all: coblsky

coblsky:
	$(CBLC) $(CBLFLAGS) -o coblsky -main $(SRC) $(LDFLAGS)

keygen:
	openssl genrsa -out $(KEYFILE) $(KEYLEN)
	openssl req -new -x509 -key $(KEYFILE) -out $(CRTFILE) -days 365 -subj "/C=US/ST=Test/L=Local/O=DevOrg/OU=Dev/CN=localhost"

clean:
	$(RM) coblsky *.o

spotless: clean
	$(RM) $(CRTFILE) $(KEYFILE)

remake: clean all
