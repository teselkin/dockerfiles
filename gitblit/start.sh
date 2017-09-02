#!/bin/bash

JAVA_MEMORY=${JAVA_MEMORY:-1024M}

java -server \
  -Xmx${JAVA_MEMORY} \
  -Djava.awt.headless=true \
  -jar /opt/gitblit/gitblit.jar \
  --baseFolder /opt/gitblit-data

