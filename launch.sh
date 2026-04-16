#!/bin/sh
#
# (c)2026 Ira Parsons
# launch.sh - coblsky/db2 launch script
#

set -e

# create user for db2 instance
groupadd db2iadm1
useradd -g db2iadm1 db2inst1
echo -e "$DB2INST1_PASSWORD\n$DB2INST1_PASSWORD" | passwd db2inst1

# setup db
/opt/ibm/db2/V11.5/instance/db2icrt -u db2inst1 db2inst1
su - db2inst1 -c "sh" <<EOF
~/sqllib/adm/db2start
~/sqllib/bin/db2 create database coblsky
~/sqllib/bin/db2 connect to COBLSKY
~/sqllib/bin/db2 -vtf /src/init.sql
EOF

# start server
nohup ./coblsky 2&>1 | tee /var/log/coblsky.log

# keep container alive
if [[ "$DEBUG" = "true" ]]; then
	while true; do sleep 1000; done
fi