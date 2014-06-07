# Rex::IO::Server

This is the Server Component of Rex. This component is for collecting multiple backends under one middleware to get a consistent api to talk to the backends (like CMDBs, DHCP, DNS, Issue/Incident Trackers, and more).

It also provides bare metal deployment capabilities.

This is a work in progress project.


# SETUP

...tbd...

# CONFIGURATION


...tbd...

## ISC DHCP

...tbd...

Configure a subnet to boot iPXE.

 subnet 192.168.7.0 netmask 255.255.255.0 {
	range 192.168.7.100 192.168.7.150;
	option routers 192.168.7.1;

	if exists user-class and option user-class = "iPXE" {
		filename "http://rex-io-server:5000/deploy/boot?deploy=true";
	} else {
		filename "undionly.kpxe";
	}
 }

## TFTP

Download L<http://boot.ipxe.org/undionly.kpxe> into your tftp-root.

## APACHE

...tbd...

## MYSQL

...tbd...

## ISC BIND

...tbd...

Configure your ISC BIND DNS Server to accept zone transfers from your Rex.IO Server. Use I<ddns-confgen> to generate a key.

```
acl trusted-servers {
  192.168.1.3;
  127.0.0.1;
};

controls {
  inet 127.0.0.1 port 953 allow { any; }
  keys { "rexio"; };
};

key "rexio" {
  algorithm hmac-md5;
  secret "the-secret-string";
};

zone "your-zone.com" IN {
  type master;
  file "your-zone.com.zone";
  allow-transfer { trusted-servers; };
  update-policy {
    grant rexio zonesub ANY;
  };
};
```

# API

## Hardware

Manage the hardware

List all hardware

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/hardware/hardware
```

Count hardware

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/hardware/hardware?action=count
```

Get specific hardware

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/hardware/hardware/$hardware_id
```

Add new hardware

```javascript
{
  "name": "myserver01.rexify.org",
  "os_id": "1"
}
```

```
curl -D- -XPOST -d@hardware.json \
  http://user:password@localhost:5000/1.0/hardware/hardware
```

Update hardware

```javascript
{
  "name": "myserver01.rexify.org",
  "os_id": "1"
}
```

```
curl -D- -XPOST -d@hardware.json \
  http://user:password@localhost:5000/1.0/hardware/hardware/$hardware_id
```

Delete hardware

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/hardware/hardware/$hardware_id
```

## Os

Manage known operating systems

List all operating systems

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/os/os
```

Get one operating system

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/os/os/$os_id
```

Add a new operating system.

```javascript
{
  "name"    : "Os name",
  "version" : "Os version"
}
```

```
curl -D- -XPOST -d@os.json \
  http://user:password@localhost:5000/1.0/os/os
```

Delete an operating system.

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/os/os/$os_id
```

## MessageBroker

Get online clients:

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/messagebroker/client
```

Send command to client:

```javascript
{
  "type"           : "Type::Of::Message",
  "param1"         : "First parameter",
  "someotherparam" : "another parameter"
}
```

```
curl -D- -XPOST -d@command.json \
  http://user:password@localhost:5000/1.0/messagebroker/client/192.168.13.213
```

Check if a client is online:

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/messagebroker/client/192.168.1.5/online
```
