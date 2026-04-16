#!/bin/sh
#
# (c)2026 Ira Parsons
# launch.sh - coblsky/db2 launch script
#

set -e

# start server
nohup ./coblsky 2&>1 | tee /var/log/coblsky.log

# keep container alive
if [[ "$DEBUG" = "true" ]]; then
	while true; do sleep 1000; done
fi