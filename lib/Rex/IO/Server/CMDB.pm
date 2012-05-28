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

my $cmdb_url = "http://localhost:4000";

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub add_server {
   my ($self, $data) = @_;

   my $tx = $self->_ua->put("$cmdb_url/server",
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
   my $tx = $self->_ua->get("$cmdb_url/server/$name");

   if(my $res = $tx->success) {
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

1;
