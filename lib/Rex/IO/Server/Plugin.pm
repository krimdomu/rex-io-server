#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Plugin;

use Mojo::Base 'Rex::IO::Server::PluginController';
use Mojo::JSON "j";
use Mojo::UserAgent;

use Data::Dumper;

sub list {
  my ($self) = @_;
  $self->render( json => $self->config->{"plugins"} );
}

sub register {
  my ($self) = @_;

  $self->app->log->debug("Registering a new plugin...");

  my $ref = $self->req->json;
  $self->app->log->debug( Dumper($ref) );

  my $plugin_name = $ref->{name};

  if ( !$plugin_name ) {
    return $self->render(
      json => { ok => Mojo::JSON->false, error => "No plugin name specified." }
    );
  }

  my $plugin_methods = $ref->{methods};

  my $r = $self->app->routes;

  for my $meth ( @{$plugin_methods} ) {
    $meth->{plugin} = $plugin_name;
    $self->register_url($meth);
  }

  my %plugin_hooks = ();
  for my $hook ( @{ $ref->{hooks} } ) {
    push @{ $plugin_hooks{ $hook->{plugin} }->{ $hook->{action} } },
      {
      plugin_name => $plugin_name,
      location    => $hook->{location},
      };
  }

  $self->shared_data_tx(
    sub {
      my $current_hooks = $self->shared_data("plugin_hooks");
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

  $self->render( json => { ok => Mojo::JSON->true } );
}

sub call_plugin {
  my $self = shift;

  $self->app->log->debug( "Calling plugin: " . $self->param("plugin") );
  $self->app->log->debug( "HTTP-Method: " . $self->req->method );

  my $config = $self->param("config");
  $self->app->log->debug( Dumper($config) );

  my %shared_data = $self->shared_data();
  $self->app->log->debug( Dumper( \%shared_data ) );

  if ( exists $config->{func} ) {
    $config->{func}->($self);
  }

  if ( exists $config->{location} ) {
    my $ua          = Mojo::UserAgent->new;
    my $backend_url = $config->{location};
    $self->app->log->debug("Backend-URL: $backend_url");

    my $meth = $self->req->method;
    my $tx =
      $ua->build_tx(
      $meth => $backend_url => { "Accept" => "application/json" } => json =>
        $self->req->json );

    # do an async call
    Mojo::IOLoop->delay(
      sub {
        $ua->start(
          $tx,
          sub {
            my ( $ua, $tx ) = @_;
            if ( $tx->success ) {
              $self->render( json => $tx->res->json );
            }
            else {
              my $ref = $tx->res->json;
              if ($ref) {
                $self->render( json => $ref );
              }
              else {
                $self->render( json =>
                    { ok => Mojo::JSON->false, error => "Unknown error." } );
              }
            }
          }
        );
      }
    );

    $self->render_later();
  }
}

1;
