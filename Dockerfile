#
# (c)2026 Ira Parsons
# coblsky dockerfile
#

# building this as an image necessary for integration with ibm db2 luw ce (only distributed as a docker image)

FROM ibmcom/db2 AS prep

# create user for db2 instance
RUN groupadd db2iadm1
RUN useradd -g db2iadm1 db2inst1
RUN echo -e "password\npassword" | passwd db2inst1

# setup db
RUN /opt/ibm/db2/V11.5/instance/db2icrt -u db2inst1 db2inst1
RUN --security=insecure su - db2inst1 -c "sh" <<EOF
set -e
~/sqllib/adm/db2start
~/sqllib/bin/db2 create database coblsky
~/sqllib/bin/db2 connect to coblsky
~/sqllib/bin/db2 -vtf /src/db/init.sql
~/sqllib/bin/db2 connect reset
~/sqllib/adm/db2stop
EOF

# copy over source folder
WORKDIR /src
COPY . .

# embed and bind sql
RUN --security=insecure su - db2inst1 -c "sh" <<EOF
set -e
~/sqllib/adm/db2start
~/sqllib/bin/db2 connect to coblsky
cd /src/db/db2
~/sqllib/bin/db2 prep db2.sqb bindfile target ansi_cobol CALL_RESOLUTION DEFERRED
sed -i 's/^\(\s\+\)0\([^0-9]*\)$/\1BY VALUE 0\2/' db2.cbl
~/sqllib/bin/db2 bind /src/db/db2/db2.bnd
~/sqllib/bin/db2 connect reset
~/sqllib/adm/db2stop
EOF

FROM fedora:43 AS build

# update system software
RUN yum clean all
RUN yum install -y libstdc++-15.2.1-7.fc43 libxcrypt-compat
RUN yum update -y glibc-2.42

# install needed build packages
RUN yum install -y make gcc-gcobol libgcobol-static openssl openssl-devel cjson-devel

# install libdb2 for linking
COPY --from=prep /opt/ibm/db2/V11.5/lib64 /opt/ibm/db2/V11.5/lib64

# install db2 include files
COPY --from=prep /opt/ibm/db2/V11.5/include/cobol_mf /opt/ibm/db2/V11.5/include/cobol_mf

# copy over source folder
WORKDIR /src
COPY --from=prep /src .

# build coblsky
RUN make

# make ssl keys
RUN make keygen

FROM prep AS install

# change repo to latest centos
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/centos*
RUN sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/centos*
RUN sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/centos*
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/centos*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/centos*

# add fedora repo to provide newer glibc
RUN cat <<EOF > /etc/yum.repos.d/fedora.repo
[fedora]
name=Fedora Latest
mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-43&arch=\$basearch
gpgcheck=0
EOF

# install gcobol dependencies
RUN yum clean all
RUN yum update -y glibc-2.42 libxml2
COPY --from=build /usr/lib64/libstdc++.so.6 /usr/lib64/libstdc++.so.6

# install coblsky dependencies
RUN yum install -y openssl3-devel cjson-devel

# add db2 libs to ld search path
RUN echo '/opt/ibm/db2/V11.5/lib64' >> /etc/ld.so.conf
RUN ldconfig

# install coblsky
WORKDIR /src
COPY --from=build /src .

ENTRYPOINT ./launch.sh