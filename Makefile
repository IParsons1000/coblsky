#
# (c)2026 Ira Parsons
# coblsky makefile
#

all:
	gcobol -g -dialect ibm -o coblsky -main coblsky.cbl network.cbl

clean:
	rm -rf coblsky *.o
