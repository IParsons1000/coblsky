#
# (c)2026 Ira Parsons
# coblsky dockerfile
#

# building this as an image necessary for integration with ibm db2 luw ce (only distributed as a docker image)

FROM fedora:43 AS build

# update system software
RUN yum clean all
RUN yum install -y libstdc++-15.2.1-7.fc43
RUN yum update -y glibc-2.42

# install needed build packages
RUN yum install -y make gcc-gcobol libgcobol-static openssl openssl-devel cjson-devel

# install libdb2 for linking
COPY --from=ibmcom/db2 /opt/ibm/db2/V11.5/lib64 /opt/ibm/db2/V11.5/lib64

# copy over source folder
WORKDIR /src
COPY . .

# build coblsky
RUN make

# make ssl keys
RUN make keygen

FROM ibmcom/db2

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

# install coblsky
WORKDIR /src
COPY --from=build /src .

ENTRYPOINT ./coblsky &>/var/log/coblsky.log