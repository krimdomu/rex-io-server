#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Hardware;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";
use Mojo::UserAgent;

use Rex::IO::Server::Helper::IP;

use Data::Dumper;


sub list {
  my ($self) = @_;

  my @all_hw = $self->db->resultset('Hardware')->all;

  my @ret;

  for my $hw (@all_hw) {
    push(@ret, $hw->to_hashRef);
  }

  $self->render(json => \@ret);
}

sub search {
  my ($self) = @_;

  #my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name % ($self->param("name") . '%'));
  my @hw_r = $self->db->resultset("Hardware")->search({ name => { like => $self->param("name") . '%' } });

  my @ret = ();

  for my $hw (@hw_r) {
    push(@ret, $hw->to_hashRef);
  }

  $self->render(json => \@ret);
}

sub get {
  my ($self) = @_;

  #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id"))->next;
  my $hw = $self->db->resultset("Hardware")->find($self->param("id"));
  $self->render(json => $hw->to_hashRef);
}

sub update {
  my ($self) = @_;

  #my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id") );
  my $hw_r = $self->db->resultset("Hardware")->find($self->param("id"));

  if(my $hw = $hw_r) {
    return eval {
      my $json = $self->req->json;

      for my $k (keys %{ $json }) {
        $hw->$k($json->{$k});
      }

      $hw->update;

      return $self->render(json => {ok => Mojo::JSON->true});
    } or do {
      return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
    };
  }
  else {
    return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
  }
}

sub purge {
  my ($self) = @_;

  my $hw_i = $self->db->resultset("Hardware")->find($self->param("id"));

  # deregister hardware on dhcp
  eval {
    $self->_ua->delete($self->config->{dhcp}->{server} . "/" . $hw_i->name);
  } or do {
    $self->app->log->error("error deregistering " . $hw_i->name . " on dhcp server: $@");
  };



  eval {
    if(my $hw = $hw_i) {

      # give plugins the possibility to clean up
      for my $plug (@{ $self->config->{plugins} }) {
        my $klass = "Rex::IO::Server::$plug";
        eval "require $klass";
        eval { $klass->__delete_hardware__($self, $hw); };
      }

      $hw->purge;
      return $self->render(json => {ok => Mojo::JSON->true});
    }
    else {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
    }
  } or do {
    return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
  };

}



################################################################################
# internal functions
################################################################################
sub _ua { return Mojo::UserAgent->new; }

sub __register__ {
  my ($self, $app) = @_;
  my $r = $app->routes;

  $r->route("/hardware")->via("LIST")->over(authenticated => 1)->to("hardware#list");
  $r->get("/hardware/search/:name")->over(authenticated => 1)->to("hardware#search");
  $r->post("/hardware/:id")->over(authenticated => 1)->to("hardware#update");
  $r->get("/hardware/:id")->over(authenticated => 1)->to("hardware#get");
  $r->post("/hardware")->over(authenticated => 1)->to("hardware#add");

}


1;
