Kontalk Tigase server
=====================

### Setting up a Kontalk server

A Kontalk server can be quickly installed and set up in a few minutes if you use
[our Docker environment](//github.com/kontalk/xmppserver-docker).

**You can get [support in our forum](https://forum.kontalk.org/) only if you use our Docker environment.**
We don't support other means of installations because setting up a Kontalk server is complicated and
we put severe efforts to make it easier. You can however provide feedback on our Docker installation
by opening a topic in the forum or by [opening an issue](//github.com/kontalk/xmppserver-docker/issues/new).

### Build

This repository contains build and startup scripts for setting up and running
a Kontalk server.

To build the Kontalk server, run this command in your terminal:

```
wget -qq -O - https://raw.githubusercontent.com/kontalk/tigase-kontalk/master/scripts/installer.sh | bash
```

The script will clone this repository in a new folder called "kontalk-server" and build everything.

After building, configure the server through `etc/tigase.conf` and `etc/init.properties` and after that
you should get it up and running:

```
scripts/tigase.sh start etc/tigase.conf
```

We also wrote a [basic tutorial](docs/local-server-howto.md) that goes more in depth with the setup of a Kontalk server.
The default `etc/init.properties` contains a few explanation comments.
