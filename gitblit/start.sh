#!/bin/bash

JAVA_MEMORY=${JAVA_MEMORY:-1024M}

if [[ ! -f /opt/gitblit-data/gitblit.properties ]]; then
  tar -xzvf /opt/gitblit-data.tar.gz -C /opt/gitblit-data
  cat << EOF >> /opt/gitblit-data/gitblit.properties
server.httpPort=80
server.httpsPort=443
server.redirectToHttpsPort=true
web.enableRpcManagement=true
web.enableRpcAdministration=true
EOF
fi

java -server \
  -Xmx${JAVA_MEMORY} \
  -Djava.awt.headless=true \
  -jar /opt/gitblit/gitblit.jar \
  --baseFolder /opt/gitblit-data

