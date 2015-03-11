#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Plugin;

use Mojo::Base 'Mojolicious::Controller';
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
    if ( "\L$meth->{meth}" eq "get" ) {
      if ( $meth->{auth} ) {
        $r->get("/1.0/$plugin_name$meth->{url}")->over( authenticated => 1 )
          ->to( "plugin#call_plugin", plugin => $plugin_name, config => $meth );
      }
      else {
        $r->get("/1.0/$plugin_name$meth->{url}")
          ->to( "plugin#call_plugin", plugin => $plugin_name, config => $meth );
      }
    }
  }

  my %plugin_hooks = ();
  for my $hook ( keys %{ $ref->{hooks} } ) {    # z.b. base
    for my $plugin_type ( keys %{ $ref->{hooks}->{$hook} } ) { # z.b. navigation
      for my $plugin ( @{ $ref->{hooks}->{$hook}->{$plugin_type} } ) {
        $plugin_hooks{$plugin_name} = {
          module => $hook,
          type   => $plugin_type,
          data   => $plugin,
        };
      }
    }
  }

  $self->shared_data_tx(
    sub {
      my $current_hooks = $self->shared_data("plugin_hooks");
      my %merged_hooks = ( %{ $current_hooks || {} }, %plugin_hooks );
      $self->shared_data( "plugin_hooks", \%merged_hooks );

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
              $self->render(
                json => { ok => Mojo::JSON->false, error => "Unknown error." }
              );
            }
          }
        }
      );
    }
  );

  $self->render_later();
}

1;
