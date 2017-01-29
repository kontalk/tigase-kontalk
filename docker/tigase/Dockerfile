FROM debian:jessie-backports
LABEL "org.kontalk"="Kontalk devteam"
LABEL version="1.0"
LABEL description="Kontalk server base image"

RUN apt-get -qq update
RUN apt-get -qq -y install wget git maven openjdk-8-jdk mysql-client
RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

ENV DOCKERIZE_VERSION v0.3.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && cp wait-for-it.sh /usr/local/bin/wait-for-it \
    && chmod +x /usr/local/bin/wait-for-it

# create kontalk user and copy the entrypoint script
RUN useradd -ms /bin/bash kontalk
COPY entrypoint.sh /home/kontalk/
RUN chown kontalk:kontalk /home/kontalk/entrypoint.sh
RUN chmod +x /home/kontalk/entrypoint.sh

# will now work from the kontalk user
USER kontalk
WORKDIR /home/kontalk

RUN wget -qq -O - https://raw.githubusercontent.com/kontalk/tigase-kontalk/master/scripts/installer.sh | bash

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENTRYPOINT ${HOME}/entrypoint.sh
