FROM debian:jessie-backports
LABEL "org.kontalk"="Kontalk devteam"
LABEL version="1.0"
LABEL description="Kontalk server base image"

RUN apt-get -qq update
RUN apt-get -qq -y install wget git maven openjdk-8-jdk

ENV DOCKERIZE_VERSION v0.3.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

RUN useradd -ms /bin/bash kontalk
USER kontalk
WORKDIR /home/kontalk

RUN wget -qq -O - https://raw.githubusercontent.com/kontalk/tigase-kontalk/master/scripts/installer.sh | bash

CMD dockerize -stdout /home/kontalk/tigase-kontalk/logs/tigase-console.log \
 -stderr /home/kontalk/tigase-kontalk/logs/tigase.log.0 \
 -wait tcp://db:3306 \
 /home/kontalk/tigase-kontalk/scripts/tigase.sh etc/tigase.conf run
