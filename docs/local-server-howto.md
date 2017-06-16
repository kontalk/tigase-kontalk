> This is a low-level tutorial for people developing on the Kontalk server. Please refer to documents in
> [our Docker repository](//github.com/kontalk/xmppserver-docker) if you want to setup a server instance
> for production use.

**WARNING** this tutorial is NOT for newbies. Linux system administrator skills are required. Also, it takes for granted concepts like GPG keys and SSL certificates, which are assumed to be known by the reader.

## Introduction ##

This tutorial will help you setup a working instance of a Kontalk XMPP server on Linux system. You can use it for your own purposes or you can link to the kontalk.net network (please refer to the [[Join]] page for that).

## Dependencies ##

Our preferred system is Debian, but any GNU/Linux distribution should work.

* MySQL server >= 5.5
* GnuPG >= 2.1.5
* GPGPME >= 1.4
* JDK >= 1.8
* Kyoto Cabinet >= 1.2.76
* Kyoto Cabinet for Java >= 1.24

For compiling you will need also:

* make
* Maven 3
* gcc/g++
* git
* development packages for Kyoto Cabinet and GPGME

## Download sources ##

After installing all the requirements, you can download the source code. We'll use the production branch, which is supposed to be stable.

Next step is Kontalk server source code.

```shell
git clone -b production https://github.com/kontalk/tigase-server.git
git clone -b production https://github.com/kontalk/tigase-extension.git
git clone https://github.com/kontalk/tigase-kontalk.git
cd tigase-kontalk
mvn install
ln -sf /usr/lib/libjkyotocabinet.so jars/libjkyotocabinet.so
```

**NOTE**: the last command will change depending on where you installed Kyoto Cabinet for Java.

## Create database ##

Database objects for Tigase itself and Kontalk must be created now. Run these commands while standing in same directory of the previous commands:

```shell
cd tigase-server
rm -f jars/*.jar
cp ../tigase-kontalk/jars/*.jar jars/
java -cp "jars/*" tigase.util.DBSchemaLoader -dbHostname db -dbType mysql -schemaVersion 7-1 \
    -dbName ${MYSQL_DATABASE} -dbUser ${MYSQL_USER} -dbPass ${MYSQL_PASSWORD} \
    -logLevel ALL -useSSL false
java -cp "jars/*" tigase.util.DBSchemaLoader -dbHostname db -dbType mysql -schemaVersion 7-1 \
    -dbName ${MYSQL_DATABASE} -dbUser ${MYSQL_USER} -dbPass ${MYSQL_PASSWORD} \
    -logLevel ALL -useSSL false \
    database/mysql-pubsub-schema-3.0.0.sql
```

Replace the variables above with the proper MySQL information.

Now it's time for Kontalk database objects. Run the following scripts in the same database using any MySQL client:

* `tigase-extension/data/network.sql` which will create a *servers* table that you will need to fill later
* `tigase-extension/data/messages.sql` creates the *messages* table for offline message delivery
* `tigase-extension/data/registration.sql` if you plan to support registration (and I bet you do)
* `tigase-extension/data/push.sql` if you want to support push notifications

## Create GPG key ##

Create a GPG key for both signing and encrypting, and remove its passphrase after creating it. Take note of the key fingerprint, you will need it.
I strongly suggest to create a local keychain instead of using the one in your home directory. However, if you created a user just for Kontalk, you might want to use the user's default keychain in `~/.gnupg`.

If you use a custom GPG home directory, you can set it in a variable in `tigase-kontalk/etc/tigase.conf`.

Export both your new private and public keys separately, using the following commands:

```shell
gpg2 --export [fingerprint] >tigase-kontalk/server-public.key
gpg2 --export-secret-key [fingerprint] >tigase-kontalk/server-private.key
```

The filenames are important because they are referenced by the configuration files.

Now log into your new database and insert a row in the *servers* database with the fingerprint of the key you've just created (without spaces) and the XMPP service host name of your server, with the enabled field set to 1:

```sql
INSERT INTO servers (fingerprint, host, enabled) VALUES('[fingerprint]', '[service_name]', 1);
```

## Create SSL certificate ##

Create a SSL certificate which will be used for STARTTLS. You can generate a self-signed certificate or request one from a CA. Save the private key and certificate chain in PEM format and concatenate them:

```shell
cat certificate.pem privatekey.pem >tigase-kontalk/certs/hostname.pem
```

The name of the file must match the host name you will use as the XMPP host for your server.

## Configuration ##

A default configuration file can be found in `etc/init.properties`. For general Tigase configuration, you can refer to its documentation.
All Kontalk specific parameters have comments explaining how to set them.

## Registration ##

Registration is already enabled in default configuration, using the `adb` tool to send SMS messages to an Android emulator. If you want real SMS verification, you need to choose a provider. It can be configured in `sess-man/plugins-conf/kontalk\:jabber\:iq\:register/provider`. Available providers are:

* `NexmoSMSProvider` - uses [Nexmo](https://nexmo.com/) to manually send SMS messages and use the local database for storing verification PINs
* `NexmoVerifyProvider` uses [Nexmo](https://nexmo.com/) verification API which can handle the whole verification workflow
* `AndroidEmulatorProvider` - uses adb to send SMS messages to an Android emulator
* `DummyProvider` - always accepts a verification code equal to the sender number configured

Those names must be prefixed in configuration with the full package name `org.kontalk.xmppserver.registration.`.

For providers backed by Nexmo, you need to configure two other additional parameters, namely `username` and `password` with Nexmo API key and API secret respectively.
For Nexmo verification API provider, one more parameter called `brand` should have value "Kontalk" (it will appear in the verification SMS text):

This is an example configuration using the Nexmo verification API:

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/providers[s]=nexmo=org.kontalk.xmppserver.registration.NexmoVerifyProvider
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/nexmo-sender=SENDERID
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/nexmo-username=APIKEY
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/nexmo-password=APISECRET
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/nexmo-brand=YOURBRAND
```

The `providers[s]` property lists which providers should be loaded. It should be in this form:

```
provider_name=provider_class,provider_name=provider_class,...
```

The provider name can be anything, as long as it's the same among all its parameters, defined right after:

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/provider_name-param_name=param_value
```

When configuring multiple providers, you can set a default provider and a fallback
one to be used when the default one fails for whatever reason:

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/default-provider=nexmo
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/fallback-provider=dummy
```

If no default or fallback providers are configured, choice will be driven by the order
you configured them in the `providers[s]` property.


For remote test servers, the dummy provider is a good way to test registrations:

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/providers[s]=dummy=org.kontalk.xmppserver.registration.DummyProvider
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/dummy-sender=123456
```

This will configure your server to always accept 123456 as a valid verification code for any account registered.


To disable registration (which makes your server pretty much useless), remove:

```
+kontalk:jabber:iq:register
```

from the `--sm-plugins` directive and remove all lines beginning with `sess-man/plugins-conf/kontalk\:jabber\:iq\:register`.

## Push notifications ##

First of all, enable push support in the server by adding:

```
+kontalk:push:legacy
```

to `--sm-plugins`.

Then uncomment the `KontalkLegacyPushComponent` component part and configure it with your GCM parameters.

## File upload support ##

> TODO configure HttpFileUploadComponent

## Running ##

Place your shell in the `tigase-kontalk` directory and run:

```shell
scripts/tigase.sh start etc/tigase.conf
```

Tigase will fork in the background and start logging in the `logs` directory.
