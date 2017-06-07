Kontalk Tigase server
=====================

### Moving to Docker

We are currently in the process of moving our infrastructure and server environment to use Docker.
This repository is still needed to run the server, but it's low level stuff. You should begin using
[the Docker environment](//github.com/kontalk/xmppserver-docker) right now, providing feedback
and asking for help if you need it. We will soon drop support for this method of installation and
support only Docker based installation.

### Build & install

This repository contains build and startup scripts for setting up and running
a Kontalk server.

To build the Kontalk server, run this command in your terminal:

```
wget -qq -O - https://raw.githubusercontent.com/kontalk/tigase-kontalk/master/scripts/installer.sh | bash
```

The script will clone the following repositories into the current directory, in a new folder called "kontalk":

* tigase-kontalk
* tigase-server
* tigase-extension

> You can find all the repositories in [our organization](//github.com/kontalk).

And will run this command from inside `tigase-kontalk`:

```
mvn install
```

The same steps can also be done manually of course.

After building, configure the server through `etc/tigase.conf` and `etc/init.properties` and after that
you should get it up and running:

```
scripts/tigase.sh start etc/tigase.conf
```

We also wrote a [basic tutorial](docs/local-server-howto.md) that goes more in depth with the setup of a Kontalk server.
The default `etc/init.properties` contains a few explanation comments.
