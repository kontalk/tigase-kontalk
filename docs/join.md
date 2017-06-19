# Join a Kontalk network

In order to join a network, you need to configure some other parameters to some predefined values.

## Registration

If you use Nexmo verify API for registration (NexmoVerifyProvider) you must set the `brand` parameter to the network brand name. For example, the kontalk.net network requires this value to be "Kontalk":

```
sess-man/plugins-conf/kontalk\:jabber\:iq\:register/brand=Kontalk
```

## Server list

Every server needs to know the current list of all servers in the network and which of them are active or not. You can request a list of all the servers to any of the other servers' administrators. Some automatic method will be implemented in the future.

## Requesting a link

Although Kontalk works in the XMPP federated network, requesting a link can have some advantages and will form an agreement that will simplify some collaboration tasks between the servers. Please refer to the [kontalk.net join page](//github.com/kontalk/network/wiki/Join).
