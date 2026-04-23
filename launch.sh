#!/bin/sh
#
# (c)2026 Ira Parsons
# launch.sh - coblsky/db2 launch script
#

set -e

# start db2
su - db2inst1 "~/sqllib/adm/db2start"

# set password from env file
echo -e "$DB2INST1_PASSWORD\n$DB2INST1_PASSWORD" | passwd db2inst1

# start server
nohup ./coblsky 2&>1 | tee /var/log/coblsky.log

# keep container alive
if [[ "$DEBUG" = "true" ]]; then
	while true; do sleep 1000; done
fi