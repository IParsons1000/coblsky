#
# (c)2026 Ira Parsons
# coblsky makefile
#

PROGRAM ?= coblsky

CBLC ?= gcobol
#CBLC ?= cobc

USE_CJSON := 1
USE_DB2 := 1

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
CBLFLAGS += -x cobol
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

ifeq ($(USE_DB2),1)
LDFLAGS += -I/opt/ibm/db2/V11.5/include/cobol_a
LDFLAGS += -L/opt/ibm/db2/V11.5/lib64
LDFLAGS += -lcrypt -ldb2 -ldb2gmf
endif

ifeq ($(CBLC),gcobol)
LDFLAGS += -static-libgcobol
endif

SRC := coblsky.cbl network.cbl http.cbl string.cbl xrpc.cbl \
       com/proto/at/test.cbl

ifeq ($(USE_CJSON),1)
SRC += cjson.cbl
endif

ifeq ($(USE_DB2),1)
CBLFLAGS += -Idb/db2
SRC += db/db2/db2.cbl
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
	# insecure building is necessary as an equivalent to --privileged=true for build so that db2start will work
	docker buildx create --buildkitd-flags '--allow-insecure-entitlement security.insecure' --name coblsky-builder
	docker buildx use coblsky-builder
	docker buildx build --allow security.insecure -t $(PROGRAM) .

docker-run:	
	docker run -itd \
	  --name $(PROGRAM) \
	  --env-file=docker.env \
	  --publish 8443:8443 \
	  --privileged=true \
	  $(PROGRAM)
	docker cp $(PROGRAM):/src/server.crt .

docker-clean:
	-docker stop $(PROGRAM)
	-docker buildx stop coblsky-builder
	-docker rm -f $(PROGRAM)
	-docker buildx rm -f coblsky-builder

clean:
	$(RM) -rf coblsky *.o *.i *.c *.h *.so

spotless: clean
	$(RM) -rf $(CRTFILE) $(KEYFILE)

remake: clean all
