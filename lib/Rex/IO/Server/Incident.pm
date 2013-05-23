#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Incident;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Mojo::UserAgent;
use Data::Dumper;

sub add {
   my ($self) = @_;

   my $json = $self->req->json;

   $json->{status_id} ||= 1;  # default incident status (new)

   my $inc = $self->db->resultset("Incident")->create($json);

   if($inc) {
      return $self->render(json => {ok => Mojo::JSON->true, id => $inc->id});
   }

   return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
}

sub add_message {
   my ($self) = @_;
   my ($new_status, $new_assignee);

   my $json = $self->req->json;
   my $incident_id = $self->param("incident_id");

   if(exists $json->{status}) {
      $new_status = $json->{status};
      delete $json->{status};
   }

   if(exists $json->{assignee}) {
      $new_assignee = $json->{assignee};
      delete $json->{assignee};
   }

   my $inc = $self->db->resultset("Incident")->find($incident_id);
   if(! $inc) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Incident not found"}, status => 404);
   }

   $json->{incident_id} = $incident_id;

   if((exists $json->{title} && $json->{title})
      || (exists $json->{message} && $json->{message})) {

      my $msg = $self->db->resultset("IncidentMessage")->create($json);

      return $self->render(json => {ok => Mojo::JSON->true, id => $msg->id});
   }


   if($new_status || $new_assignee) {

      my $data = {};

      if($new_status) {
         $data->{status_id} = $new_status;
      }

      if($new_assignee) {
         $data->{assignee} = $new_assignee;
      }

      $inc->update($data);

      return $self->render(json => {ok => Mojo::JSON->true, message => "status/assignee updated"});
   }

   $self->render(json => {ok => Mojo::JSON->false, message => "done nothing"});
}

sub update_status {
   my ($self) = @_;

   my $inc = $self->db->resultset("Incident")->find($self->param("incident_id"));

   if(! $inc) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Incident not found"}, status => 404);
   }

   $inc->update({
      status_id => $self->json->{"status_id"},
   });

   $self->render(json => {ok => Mojo::JSON->true});
}

sub list {
   my ($self) = @_;
   
   my @all = $self->db->resultset("Incident")->all;
   my @ret;

   for my $inc (@all) {
      my $data = { $inc->get_columns };
      $data->{status} = $inc->status->name;

      my $assignee = $inc->assignee;
      $data->{assignee} = { $assignee->get_columns };

      my $creator = $inc->creator;
      $data->{creator} = { $creator->get_columns };

      push @ret, $data;
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub list_incident_messages {
   my ($self) = @_;

   my $incident_id = $self->param("incident_id");
   my $inc = $self->db->resultset("Incident")->find($incident_id);

   if(! $inc) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Incident not found"}, status => 404);
   }

   my @messages;

   for my $msg ($inc->messages) {
      push @messages, { $msg->get_columns };
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@messages});
}

sub get {
   my ($self) = @_;

   my $inc = $self->db->resultset("Incident")->find($self->param("incident_id"));

   if(! $inc) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   my $data = { $inc->get_columns };
   $data->{assignee} = $inc->assignee->name;
   $data->{creator}  = $inc->creator->name;
   $data->{status}   = $inc->status->name;

   for my $msg ($inc->messages) {
      my $msg_data = { $msg->get_columns };
      $msg_data->{creator} = $msg->creator->name;

      push @{$data->{messages}}, $msg_data;
   }

   $self->render(json => $data);
}

sub list_status {
   my ($self) = @_;

   my @status = $self->db->resultset("IncidentStatus")->all;

   my @ret;

   for my $st (@status) {
      push @ret, { $st->get_columns };
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->route("/incident/status")->via("LIST")->over(authenticated => 1)->to("incident#list_status");
   $r->post("/incident")->over(authenticated => 1)->to("incident#add");
   $r->post("/incident/:incident_id/status")->over(authenticated => 1)->to("incident#update_status");
   $r->post("/incident/:incident_id/message")->over(authenticated => 1)->to("incident#add_message");
   $r->route("/incident")->via("LIST")->over(authenticated => 1)->to("incident#list");
   $r->route("/incident/:incident_id/message")->via("LIST")->over(authenticated => 1)->to("incident#list_incident_messages");
   $r->get("/incident/:incident_id")->over(authenticated => 1)->to("incident#get");
}

1;
