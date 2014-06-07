#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::IO::Server - The webservice component of Rex.IO

This is the webservice component of Rex.IO tieing all supported services together under one API.

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-server/issues>

=back

=cut

package Rex::IO::Server;
use Mojo::Base 'Mojolicious';
use Mojo::UserAgent;
use Mojo::IOLoop;
use Data::Dumper;

use Rex::IO::Server::Schema;

has schema => sub {
  my ($self) = @_;

  my $dsn =
      "DBI:mysql:"
    . "database="
    . $self->config->{database}->{schema} . ";" . "host="
    . $self->config->{database}->{host};

  return Rex::IO::Server::Schema->connect(
    $dsn,
    $self->config->{database}->{username},
    $self->config->{database}->{password},
    { mysql_enable_utf8 => 1 }
  );
};

our $VERSION = "0.5.0";

# This method will run once at server start
sub startup {
  my $self = shift;

  #######################################################################
  # Define some custom helpers
  #######################################################################
  $self->helper( db => sub { $self->app->schema } );

  #######################################################################
  # Load configuration
  #######################################################################
  my @cfg = (
    "/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf",
    "server.conf"
  );
  my $cfg;
  for my $file (@cfg) {
    if ( -f $file ) {
      $cfg = $file;
      last;
    }
  }

  #######################################################################
  # Load plugins
  #######################################################################
  $self->plugin( "Config", file => $cfg );
  $self->plugin("Rex::IO::Server::Mojolicious::Plugin::IP");
  $self->plugin("Rex::IO::Server::Mojolicious::Plugin::User");
  $self->plugin("Rex::IO::Server::Mojolicious::Plugin::Redis");
  $self->plugin(
    "http_basic_auth",
    {
      validate => sub {
        my ( $c, $username, $pass, $realm ) = @_;
        $c->app->log->debug(
          "Authenticating user: $username with password $pass.");
        my $user_o = $c->get_user( by_name => $username );
        if ( $user_o->check_password($pass) ) {
          $c->session("uid" => $user_o->id);
          return $user_o->id;
        }

        return 0;
      },
      invalid => sub {
        my $ctrl = shift;
        return (
          any => {
            json =>
              { ok => Mojo::JSON->false, error => "HTTP 401: Unauthorized" }
          },
        );
      },
      realm => 'Rex.IO Middleware'
    }
  );

  #######################################################################
  # Setup routing
  #######################################################################
  my $r = $self->routes;

  #######################################################################
  # routes that need authentication
  #######################################################################

  $r->delete("/hardware/:id")->over( authenticated => 1 )->to("hardware#purge");

  $r->post("/network-adapter/:id")->over( authenticated => 1 )
    ->to("hardware#update_network_adapter");

  $r->get("/user/:id")->over( authenticated => 1 )->to("user#get");
  $r->get("/group/:id")->over( authenticated => 1 )->to("group#get");
  $r->post("/user")->over( authenticated => 1 )->to("user#add");
  $r->post("/group")->over( authenticated => 1 )->to("group#add");
  $r->route("/user")->via("LIST")->over( authenticated => 1 )->to("user#list");
  $r->route("/group")->via("LIST")->over( authenticated => 1 )
    ->to("group#list");
  $r->delete("/user/:user_id")->over( authenticated => 1 )->to("user#delete");
  $r->delete("/group/:group_id")->over( authenticated => 1 )
    ->to("group#delete");
  $r->post("/group/:group_id/user/:user_id")->over( authenticated => 1 )
    ->to("group#add_user_to_group");

  #
  # load server plugins
  #
  for my $plug ( @{ $self->{defaults}->{config}->{plugins} } ) {
    my $s = "Rex::IO::Server::$plug";
    eval "require $s";
    $s->__register__($self);
  }

  $r->get("/plugins")->over( authenticated => 1 )->to("plugin#list");

}

1;
