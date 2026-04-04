#
# (c)2026 Ira Parsons
# coblsky makefile
#

USE_CJSON := 1

CBLC ?= gcobol

CBLFLAGS ?=
CBLFLAGS += -g -O3
CBLFLAGS += -dialect ibm
CBLFLAGS += -I.

ifeq ($(USE_CJSON),1)
CBLFLAGS += -DUSE_CJSON=1
endif

LDFLAGS ?=
LDFLAGS += -lssl -lcrypto

ifeq ($(USE_CJSON),1)
LDFLAGS += -lcjson
endif

SRC := coblsky.cbl network.cbl http.cbl string.cbl xrpc.cbl \
       com/proto/at/test.cbl

ifeq ($(USE_CJSON),1)
SRC += cjson.cbl
endif

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
