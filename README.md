Kontalk Tigase server
=====================

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
