Kontalk XMPP server image
=========================

This is a Docker environment for building a Docker image with a ready-to-use Kontalk server.

This image can easily be used with a Docker Compose script also found in this repository.  
As a matter of fact, this image can't work alone: it needs configuration files and a database container.  

To build this image just run this from a terminal:

```shell
./build.sh
```

When executed in a container, it will generate server keys automatically for testing purposes.
However, for production environments, it's highly recommended to keep keys exported somewhere else.

The following environment variables are mandatory:

* `XMPP_SERVICE`: XMPP service name (not necessarily the container hostname)
* `MYSQL_PASSWORD`: password of the MySQL user account

The following variables will be used if available:

* `FINGERPRINT`: fingerprint of the GPG server key (if available)
