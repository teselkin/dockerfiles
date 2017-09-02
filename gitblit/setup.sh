#!/bin/bash

set -o xtrace
set -o errexit

GITBLIT_VERSION=${GITBLIT_VERSION:-1.8.0}

curl -Lks http://dl.bintray.com/gitblit/releases/gitblit-${GITBLIT_VERSION}.tar.gz -o /tmp/gitblit.tar.gz
mkdir -p /tmp/gitblit-tmp
tar -xzvf /tmp/gitblit.tar.gz -C /tmp/gitblit-tmp
mv /tmp/gitblit-tmp/gitblit-${GITBLIT_VERSION} /opt/gitblit
rm -rf /tmp/gitblit*

touch /opt/gitblit/data/gitblit.properties
tar -czvf /opt/gitblit-data.tar.gz -C /opt/gitblit/data/ .

mkdir -p /opt/gitblit-data

