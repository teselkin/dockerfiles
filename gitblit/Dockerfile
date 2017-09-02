FROM java:8

MAINTAINER Dmitry Teselkin <teselkin.d@gmail.com>

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl git-core

RUN mkdir /workspace

COPY setup.sh /workspace
COPY start.sh /workspace

RUN chmod +x /workspace/*.sh
RUN /workspace/setup.sh

WORKDIR /opt/gitblit

CMD /workspace/start.sh
