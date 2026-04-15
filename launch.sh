#!/bin/sh
#
# (c)2026 Ira Parsons
# launch.sh - coblsky/db2 launch script
#

./coblsky 2&>1 | tee /var/log/coblsky.log ; bash