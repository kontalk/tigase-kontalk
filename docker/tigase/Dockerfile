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

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENTRYPOINT dockerize \
 -template /tmp/init.properties.dist:/home/kontalk/kontalk/tigase-kontalk/etc/init.properties \
 -stdout /home/kontalk/kontalk/tigase-kontalk/logs/tigase-console.log \
 -stderr /home/kontalk/kontalk/tigase-kontalk/logs/tigase.log.0 \
 -wait tcp://db:3306 \
 /home/kontalk/kontalk/tigase-kontalk/scripts/tigase.sh run /home/kontalk/kontalk/tigase-kontalk/etc/tigase.conf
