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
use JSON::XS;
use Carp;
use Redis::DistLock;

has redis => sub {
  my ($self) = @_;
  state $redis ||= Redis->new( server => $self->config->{redis}->{server} );
};

has shared_config => sub {
  my ($self) = @_;
  state $rd ||= Redis::DistLock->new( servers => [ $self->config->{redis}->{server} ] );
};

has schema => sub {
  my ($self) = @_;

  my $dsn;

  if ( exists $self->config->{database}->{dsn} ) {
    $dsn = $self->config->{database}->{dsn};
  }
  else {
    $dsn =
        "dbi:"
      . $self->config->{database}->{type} . ":"
      . "database="
      . $self->config->{database}->{schema} . ";" . "host="
      . $self->config->{database}->{host};
  }

  return Rex::IO::Server::Schema->connect(
    $dsn,
    ( $self->config->{database}->{username} || "" ),
    ( $self->config->{database}->{password} || "" ),
    ( $self->config->{database}->{options}  || {} ),
  );
};

our $VERSION = "0.6.0";

#use IPC::Lite qw(%shared_data);

# This method will run once at server start
sub startup {
  my $self = shift;

  #######################################################################
  # Define some custom helpers
  #######################################################################
  $self->helper( db   => sub { $self->app->schema } );
  $self->helper( shared_config => sub { $self->app->shared_config } );
  $self->helper( redis => sub { $self->app->redis } );

  $self->helper(
    shared_data_tx => sub {
      my ( $self, $code ) = @_;
      my $mutex = $self->shared_config->lock("rexio_shared_config", $self->config->{redis}->{lock_ttl} || 10);
      $code->();
      $self->shared_config->release($mutex);
    }
  );
  $self->helper(
    shared_data => sub {
      my ( $self, $key, $value ) = @_;
      if ($value) {
        $self->redis->set( "/$key" => JSON::XS::encode_json($value) );
      }
      else {
        if ($key) {
          my $ret;
          eval {
            $ret =
              JSON::XS::decode_json( $self->redis->get("/$key") );
            1;
          } or do {
            $ret = {};
          };

          return $ret;
        }
        else {
          confess "Illegal call to shared_data.";
        }
      }
    }
  );

  $self->helper(
    register_url => sub {
      my ( $self, $config ) = @_;

      my $plugin_name = $config->{plugin};
      my $r           = $self->app->routes;

      my $meth_case = "\L$config->{meth}";
      if ( $meth_case eq "get"
        || $meth_case eq "post"
        || $meth_case eq "put"
        || $meth_case eq "delete" )
      {
        if ( $config->{auth} ) {
          $r->$meth_case("/1.0/$plugin_name$config->{url}")
            ->over( authenticated => 1 )->to(
            "plugin#call_plugin",
            plugin => $plugin_name,
            config => $config
            );
        }
        else {
          $r->$meth_case("/1.0/$plugin_name$config->{url}")->to(
            "plugin#call_plugin",
            plugin => $plugin_name,
            config => $config
          );
        }
      }
    }
  );
  
  $self->helper(
    call_plugin => sub {
      
    }
  );

  $self->helper(
    register_plugin => sub {
      my $self        = shift;
      my $ref         = shift;
      my $plugin_name = $ref->{name};
      my $plugin_methods = $ref->{methods};

      my $r = $self->app->routes;

      for my $meth ( @{$plugin_methods} ) {
        $meth->{plugin} = $plugin_name;
        $self->register_url($meth);
      }

      my %plugin_hooks = ();
      for my $hook ( @{ $ref->{hooks}->{consume} } ) {
        push @{ $plugin_hooks{ $hook->{plugin} }->{ $hook->{action} } },
          {
          plugin_name => $plugin_name,
          location    => $hook->{location},
          };
      }

      $self->shared_data_tx(
        sub {
          my $current_hooks = $self->shared_data("plugin_hooks");
          my $current_plugin_config = $self->shared_data("plugin_config");
          $current_plugin_config->{$plugin_name} = $ref;
          $self->shared_data( "plugin_config" => $current_plugin_config );
          
          for my $plugin_name ( keys %plugin_hooks ) {
            for my $plugin_action ( keys %{ $plugin_hooks{$plugin_name} } ) {
              push @{ $current_hooks->{$plugin_name}->{$plugin_action} },
                @{ $plugin_hooks{$plugin_name}->{$plugin_action} };
            }
          }
          $self->shared_data( "plugin_hooks", $current_hooks );

          my $loaded_plugins = $self->shared_data("loaded_plugins");
          my %merged_loaded_plugins =
            ( %{ $loaded_plugins || {} }, $plugin_name => $ref );
          $self->shared_data( "loaded_plugins", \%merged_loaded_plugins );
        }
      );
    },
  );

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

  #$self->plugin("Rex::IO::Server::Mojolicious::Plugin::Redis");
  $self->plugin(
    "http_basic_auth",
    {
      validate => sub {
        my ( $c, $username, $pass, $realm ) = @_;
        $c->app->log->debug(
          "Authenticating user: $username with password $pass.");
        my $user_o = $c->get_user( by_name => $username );
        if ( $user_o->check_password($pass) ) {
          $c->session( "uid" => $user_o->id );
          return $user_o->id;
        }

        return 0;
      },
      invalid => sub {
        my $ctrl = shift;
        return (
          any => {
            json => {
              ok    => Mojo::JSON->false,
              error => "HTTP 401: Unauthorized"
            }
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

  #
  # load server plugins
  #
  for my $plug ( @{ $self->{defaults}->{config}->{plugins} } ) {
    my $s = "Rex::IO::Server::$plug";
    eval "require $s";
    $s->__register__($self);
  }

  $r->get("/plugins")->over( authenticated => 1 )->to("plugin#list");

#$r->post("/1.0/plugin/plugin")->over( authenticated => 1 )->to("plugin#register");
  $r->post("/1.0/plugin/plugin")->to("plugin#register");

  #######################################################################
  # load routes that are currently known to the cluster
  #######################################################################

  my $plugins = $self->shared_data("plugin_config");
  for my $ref (values %{$plugins}) {
    $self->log->debug("Loading already registered plugin: " . $ref->{name});
    $self->register_plugin($ref);
  }

}

1;
