> This document is a work in progress.

Server internals
================
This article describes some internals of the Kontalk server, how it was
developed and what customizations were needed to make it work.


## Software environment
Kontalk is based on a patched version of the
[Tigase XMPP server](https://projects.tigase.org), usually on top of the
release branch. We patched a few things mainly to add more reliability and
pieces of code to better integrate with our extensions (more about those later
on).
In addition to that, we developed a few extensions on top of the plugins and
component APIs provided by Tigase which proved to be very useful and well
organized. Extensions were developed only when Tigase didn't provide its own
plugin or when the Tigase implementation wasn't enough for our needs.


## Patches to Tigase
We always [rebase on top of the upstream release branch](https://github.com/kontalk/tigase-server/commits/master)
so our commits will always be at the top of history. Here is a quick list of
what we did.

### Patch: allow self-signed certificates in client certificate authentication
Kontalk authentication is client-certificate based, but signature check is done
on the PGP key, not on the X.509 certificate (although a X.509 certificate is
used to encapsulate, more on that later on). Therefore, those "bridge
certificates" as we call them are simply self-signed. Tigase doesn't allow
client certificate authentication with self-signed certificates, so we had to
patch it.

### Patch: subscription pre-approval
XMPP defines something called [subscription pre-approvals](http://xmpp.org/rfcs/rfc6121.html#sub-preapproval)
which is used to approve (hence the name) a subscription request by somebody
preemptively, so that when that somebody requests a subscription to that user,
it will get automatically approved by the server without requiring any other
action. A merge request is currently pending to the Tigase project with the code
we donated.

### Patch: minor reliability checks
There are some minor issues with Tigase regarding aggressive delivery. Tigase
does guarantee message delivery when using Session Management, however there are
a couple of borderline cases where some messages might get lost. It happens only
in severely broken connections, however for mobile phones this is not so rare.


## Kontalk extensions
On top of the described patches, a separate set of plugins and components were
delivered to fully support the Kontalk workflow.

### PGP-key based authentication
This is the central authentication module that allows authentication through
means of a PGP key previously signed by the server during registration. It's
built on top of [XEP-0077: In-band registration](http://xmpp.org/extensions/xep-0077.html)
with a few more form fields to include some stuff such as verification code,
phone number and public key. More details on the XMPP extension can be found in
the [relevant spec document](https://github.com/kontalk/specs/blob/master/register.md).
