# Rex::IO::Server

This is the Server Component of Rex. This component is for collecting multiple backends under one middleware to get a consistent api to talk to the backends (like CMDBs, DHCP, DNS, Issue/Incident Trackers, and more).

It also provides bare metal deployment capabilities.

This is a work in progress project.


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

## Users and Groups

Get all users:

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/user/user
```

Get a specific user

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/user/user/$user_id
```

Delete a user

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/user/user/$user_id
```

Get all groups:

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/group/group
```

Get a specific group

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/group/group/$group_id
```

Delete a group

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/group/group/$group_id
```

Assign a user to a group

```
curl -D- -XPOST \
  http://user:password@localhost:5000/1.0/group/group/$group_id/user/$user_id
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
