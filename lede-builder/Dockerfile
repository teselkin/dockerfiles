FROM ubuntu:trusty

RUN apt-get update && apt-get --yes upgrade
RUN apt-get install --yes \
  build-essential \
  git \
  libncurses5-dev \
  libz-dev \
  libssl-dev \
  gawk \
  unzip \
  wget \
  python \
  subversion

RUN useradd -m build
RUN echo "build ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/build
RUN chmod 440 /etc/sudoers.d/build

USER build
WORKDIR /home/build
RUN git clone http://git.lede-project.org/source.git

