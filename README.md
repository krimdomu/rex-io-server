# Rex::IO::Server

This is the Server Component of Rex. This component is for collecting multiple backends under one middleware to get a consistent api to talk to the backends (like CMDBs, DHCP, DNS, Issue/Incident Trackers, and more).

It also provides bare metal deployment capabilities.

This is a work in progress project.


# API

## Users and Groups

Create a user:

```javascript
{
  "name"              : "username",
  "password"          : "the-password",
  "group_id"          : 1,
  "permission_set_id" : 1
}
```

```
curl -D- -XPOST -d@user.json \
  http://user:password@localhost:5000/1.0/user/user
```

Modify a user:

```javascript
{
  "name"              : "username",
  "password"          : "the-password",
  "group_id"          : 1,
  "permission_set_id" : 1
}
```

```
curl -D- -XPOST -d@user.json \
  http://user:password@localhost:5000/1.0/user/user/$user_id
```


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

## Permissions

Permissions are build of permission sets. These sets can contain multiple permissions. You'll find all available permissions in the *permission_type* table.

List permission types

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/permission/type
```

List all permission sets

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/permission/set
```

Create a new permission set

```javascript
{
  "name"        : "My Permission Set",
  "description" : "My very own permission set.",
  "permissions" : {      // optional
    "user"  : {
      15 : [1,2,3,4],
      19 : [19,1,2,3,4]
    },
    "group" : {
      4 : [1,2,3,4]
    }
  }
}
```

```
curl -D- -XPOST -d@permission_set.json \
  http://user:password@localhost:5000/1.0/permission/set
```

Update a permission set

```javascript
{
  "name"        : "New name",
  "description" : "My very own permission set.",
  "permissions" : {
    "user"  : {
      15 : [1,2,3,4],
      19 : [19,1,2,3,4]
    },
    "group" : {
      4 : [1,2,3,4]
    }
  }
}
```

```
curl -D- -XPOST -d@permission_set.json \
  http://user:password@localhost:5000/1.0/permission/set/$permission_set_id
```

Delete a permission set

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/permission/set/$permission_set_id
```

List all permissions

```
curl -D- -XGET \
  http://user:password@localhost:5000/1.0/permission/permission
```

Create a new permission

```javascript
{
  "permission_set_id" : 1,
  "group_id"          : 10,   // optional, if this permission is for a group
  "user_id"           : 4,    // optional, if this permission is for a user
  "perm_id"           : 17,   // permission id from permission_type table
}
```

```
curl -D- -XPOST -d@permission.json \
  http://user:password@localhost:5000/1.0/permission/permission
```

Update a permission

```javascript
{
  "user_id" : 14
}
```

```
curl -D- -XPOST -d@permission.json \
  http://user:password@localhost:5000/1.0/permission/permission/$permission_id
```

Delete a permission

```
curl -D- -XDELETE \
  http://user:password@localhost:5000/1.0/permission/permission/$permission_id
```


