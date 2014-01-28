#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Cmdb::Service;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;

sub post {
   my ($self) = @_;
   my $ref = $self->req->json;

   my $new_res = $self->cmdb->add_service($ref);

   $self->render(json => $new_res, status => 201);
}

sub delete {
   my ($self) = @_;

   my $data = $self->cmdb->delete_service($self->stash("name"));

   if($data->{ok} == Mojo::JSON->false) {
      $self->render(json => $data, status => 404);
   }
   else {
      $self->render(json => $data);
   }
}

sub get {
   my ($self) = @_;
   my $server = $self->stash("name");

   my $data = $self->cmdb->get_service($server);

   if(! ref($data) ) {
      $self->render(json => {ok => Mojo::JSON->false}, status => $data);
   }

   my $ret = {
      ok => Mojo::JSON->true,
      data => $data,
   };
   $self->render(json => $ret);
}

sub list {
   my ($self) = @_;

   my $data = $self->cmdb->get_service_list();

   if(! ref($data) ) {
      $self->render(json => {ok => Mojo::JSON->false}, status => $data);
   }

   my $ret = {
      ok => Mojo::JSON->true,
      data => $data,
   };
   $self->render(json => $ret);
}

1;
