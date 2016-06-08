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

In addition to the [Tigase database scripts](http://docs.tigase.org/tigase-server/snapshot/Administration_Guide/html/#_prepare_database), you will need to run the following scripts in the same database:

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

A default configuration file can be found in `etc/init.properties`. For general Tigase configuration, you can refer to its documentation. For Kontalk specific usage, here is a list of parameters you will need to modify:

* `sess-man/plugins-conf/fingerprint` - fingerprint of your newly created GPG key
* `sess-man/plugins-conf/network-domain` - your network name (WARNING: this is not the host name!)
* `sess-man/plugins-conf/kontalk\:jabber\:iq\:register/provider` - registration provider (see section *Registration*)
* `c2s/clientCertCA` - path to the PEM trusted certificate chain for client authentication (dummy: won't be used, but it needs to be a valid list of concatenated CA certificates, any system pem file will do)
* Various `db-uri` parameters all pointing to the same database
* `upload/uri` - URL to your Fileserver component (see section *File upload support*)

## Registration ##

Registration is already enabled in default configuration, using the `adb` tool to send SMS messages to an Android emulator. If you want real SMS verification, you need to choose a provider. It can be configured in `sess-man/plugins-conf/kontalk\:jabber\:iq\:register/provider`. Available providers are:

* `NexmoSMSProvider` - uses [Nexmo](https://nexmo.com/) to manually send SMS messages and use the local database for storing verification PINs
* `NexmoVerifyProvider` uses [Nexmo](https://nexmo.com/) verification API which can handle the whole verification workflow
* `AndroidEmulatorProvider` - uses adb to send SMS messages to an Android emulator

For providers backed by Nexmo, you need to configure two other additional parameters, namely `username` and `password` with Nexmo API key and API secret respectively.
For Nexmo verification API provider, one more parameter called `brand` should have value "Kontalk" (it will appear in the verification SMS text):

This is an example configuration using the Nexmo verification API:

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/provider=org.kontalk.xmppserver.registration.NexmoVerifyProvider
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/sender=SENDERID
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/username=APIKEY
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/password=APISECRET
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/brand=YOURBRAND
```

To disable registration (which makes your server pretty much useless), remove:

```
+kontalk:jabber:iq:register
```

from the `--sm-plugins` directive.

## Push notifications ##

First of all, enable push support in the server by adding:

```
+kontalk:push:legacy
```

to `--sm-plugins`.

Then add these other parameters at the end:

```
--comp-name-4=push
--comp-class-4=org.kontalk.xmppserver.KontalkLegacyPushComponent
push/gcm-projectid=GCM-PROJECTID
push/gcm-apikey=GCM-API-KEY
push/db-uri=DB-URI
```

`push/db-uri` should be the same value as other parameters with the same name.

## File upload support ##

The file upload component (already activated in the configuration template using `KontalkLegacyFileUploadComponent`) will be using the Fileserver component.

Clone the Fileserver repository:

```
git clone https://github.com/kontalk/fileserver.git
```

The fileserver component is a very basic file uploader designed to work with a Kontalk server. Its configuration file fileserver.conf is a JSON file with C++ block comments allowed.

Edit fileserver.conf and set the `host` and `network` parameters with the same value of the domain name you chose as the virtual host for Tigase (`--virt-hosts` in Tigase configuration). Edit also the `fingerprint` parameters with the fingerprint of the PGP server key used for Tigase.

The `storage` section holds the configuration for the actual storage driver. The only available implementation is `DiskFileStorage`, accepting the path where to store uploaded files as the only parameter.

The `upload` section can be used to configure accepted MIME types (`accept_content`), max file size (`max_size`, in bytes), and the URL returned to the client after the upload. This must match an address visible to the client (`upload/uri` in Tigase configuration), because that URL will be used by clients to download the uploaded file later (that is, by the message recipient).

With your shell inside the fileserver directory, run this command to start it:

```shell
GNUPGHOME=gnupg_home_dir twistd --pidfile fileserver.pid --logfile fileserver.log kontalk-fileserver
```

The GNUPGHOME assignment is required only if you choose a non-standard path for your GPG home.

## Running ##

Place your shell in the `tigase-kontalk` directory and run:

```shell
scripts/tigase.sh start etc/tigase.conf
```

Tigase will fork in the background and start logging in the `logs` directory.
