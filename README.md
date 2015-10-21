Kontalk Tigase server
=====================

This repository contains build and startup scripts for setting up and running
a Kontalk server.

To build the Kontalk server, clone this and the following repositories into
the same directory:

* tigase-server
* tigase-extension
* gnupg-for-java

Then run from this repository:

```
mvn install
```

Configure it through etc/tigase.conf and etc/init.properties and after that
you should get it up and running:

```
scripts/tigase.sh start etc/tigase.conf
```

You can find all the repositories in [our organization](/kontalk).
