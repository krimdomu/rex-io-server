#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::CMDB;
   
use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON;
use Data::Dumper;


sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub add_server {
   my ($self, $data) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->post("$cmdb_url/server",
                              { "Content-Type" => "application/json" },
                              $self->_json->encode($data)
   );

   if($tx->success) {
      return $self->get_server($data->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub delete_server {
   my ($self, $name) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->delete("$cmdb_url/server/$name");

   if($tx->success) {
      return {ok => Mojo::JSON->true};
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub get_server {
   my ($self, $name) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->get("$cmdb_url/server/$name");

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub add_service {
   my ($self, $data) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->post("$cmdb_url/service",
                              { "Content-Type" => "application/json" },
                              $self->_json->encode($data)
   );

   if($tx->success) {
      return $self->get_service($data->{name});
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub delete_service {
   my ($self, $name) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->delete("$cmdb_url/service/$name");

   if($tx->success) {
      return {ok => Mojo::JSON->true};
   }
   else {
      return {ok => Mojo::JSON->false};
   }
}

sub get_service {
   my ($self, $name) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->get("$cmdb_url/service/$name");

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub get_server_list {
   my ($self) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->build_tx(LIST => "$cmdb_url/server");
   $self->_ua->start($tx);

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub get_service_list {
   my ($self) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->build_tx(LIST => "$cmdb_url/service");
   $self->_ua->start($tx);

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub add_service_to_server {
   my ($self, $server, $data) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->build_tx(LINK => "$cmdb_url/server/$server" => { "Content-Type" => "application/json" } => $self->_json->encode($data) );
   $self->_ua->start($tx);

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub remove_service_from_server {
   my ($self, $server, $data) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->build_tx(UNLINK => "$cmdb_url/server/$server" => { "Content-Type" => "application/json" } => $self->_json->encode($data) );
   $self->_ua->start($tx);

   if(my $res = $tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub configure_service_of_server {
   my ($self, $server, $service, $data) = @_;

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->put("$cmdb_url/server/$server/service/$service", { "Content-Type" => "application/json" }, $self->_json->encode($data));

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub add_section_to_server {
   my ($self, $server, $section, $data) = @_;

   my $server_data = $self->get_server($server);

   # check if server already exists
   if(! ref($server_data)) {
      # if not, add a new server
      my $ret = $self->add_server({name => $server});
      if(exists $ret->{ok} && $ret->{ok} == Mojo::JSON->false) {
         return 500;
      }
   }

   my $cmdb_url = $self->_cmdb;
   my $tx = $self->_ua->put("$cmdb_url/server/$server/$section", { "Content-Type" => "application/json" }, $self->_json->encode($data));

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }
   else {
      my ($error, $code) = $tx->error;
      return $code;
   }
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

sub _json {
   my ($self) = @_;
   return Mojo::JSON->new;
}

sub _cmdb {
   my ($self) = @_;
   return $self->{config}->{cmdb};
}

1;
