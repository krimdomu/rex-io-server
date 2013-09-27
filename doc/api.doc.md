# Rex.IO - API

## Definition

The api always begins with the API version. After the API version the section (module) is called and then in a key/value syntax the options.

There are several HTTP methods Rex.IO is using.

* GET
* POST
* DELETE
* LIST


## Hardware

### LIST /1.0/hardware

List all the hardware known to Rex.IO.

 

### GET /1.0/hardware/:name

* TODO: rework

Search for a specific hardware.

### POST /1.0/hardware/:id

Update the hardware information.

### GET /1.0/hardware/:id

Get the information of a specific hardware.

### POST /1.0/hardware

Create a new hardware entry.

### DELETE /1.0/hardware/:id

Delete a hardware.


## OS Templates

### LIST /1.0/os_template

List all the OS templates known to Rex.IO.

### GET /1.0/os_template/:name

* TODO: rework

Search for a specific template.

### POST /1.0/os_template/:id

Update the template information.

### GET /1.0/os_template/:id

Get the information of a specific template.

### POST /1.0/os_template

Create a new os template entry.

## Network Adapters

### POST /1.0/hardware/:hardware_id/network_adapter/:network_adapter_id

* TODO: rework

Modify network adapter information


## User and Group management

### GET /1.0/user/:id

Get the information of a specific user.

### GET /1.0/group/:id

Get the information of a specific group.

### POST /1.0/user

Create a new user.

### POST /1.0/group

Create a new group.

### LIST /1.0/user

Returns a list of all known users.

### LIST /1.0/group

Returns a list of all known groups.


### DELETE /1.0/user/:id

Delete a specific user.

### DELETE /1.0/group/:id

Delete a specific group.

### PUT /1.0/user/:user_id/group/:group_id

* TODO: rework

Add a user to a specific group.

### DELETE /1.0/user/:user_id/group/:group_id

* TODO: implement

Remove a user from a specific group.


