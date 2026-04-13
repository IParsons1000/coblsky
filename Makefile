#
# (c)2026 Ira Parsons
# coblsky makefile
#

PROGRAM ?= coblsky

CBLC ?= gcobol
#CBLC ?= cobc

USE_CJSON := 1

CBLFLAGS ?=
CBLFLAGS += -g -O3
CBLFLAGS += -I.
CBLFLAGS += -o $(PROGRAM)

ifeq ($(USE_CJSON),1)
CBLFLAGS += -DUSE_CJSON=1
endif

ifeq ($(CBLC),gcobol)
CBLFLAGS += -DGCOBOL
CBLFLAGS += -dialect ibm
CBLFLAGS += -main
else ifeq ($(CBLC),cobc)
CBLFLGAS += -DCOBC
CBLFLAGS += -std=ibm -F
CBLFLAGS += -vvv -x -e COBLSKY
endif

LDFLAGS ?=
LDFLAGS += -lssl -lcrypto

ifeq ($(USE_CJSON),1)
LDFLAGS += -lcjson
endif

ifeq ($(CBLC),gcobol)
LDFLAGS += -static-libgcobol
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
	$(CBLC) $(CBLFLAGS) $(SRC) $(LDFLAGS)

keygen:
	openssl genrsa -out $(KEYFILE) $(KEYLEN)
	openssl req -new -x509 -key $(KEYFILE) -out $(CRTFILE) -days 365 -subj "/C=US/ST=Test/L=Local/O=DevOrg/OU=Dev/CN=localhost"

docker: docker-clean docker-build docker-run

docker-build:

docker-run:	
	  --name $(PROGRAM) \
	  --restart unless-stopped \
	  --env-file=docker.env \
	  --publish 8443:8443 \
	  --privileged=true \
	  $(PROGRAM)

docker-clean:
	-sudo docker stop $(PROGRAM)
	-sudo docker rm -f $(PROGRAM)
	-docker stop $(PROGRAM)

clean:
	$(RM) -rf coblsky *.o *.i *.c *.h *.so

spotless: clean
	$(RM) -rf $(CRTFILE) $(KEYFILE)

remake: clean all
