#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Plugin;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;

sub list {
  my ($self) = @_;
  $self->render( json => $self->config->{"plugins"} );
}

sub register {
  my ($self) = @_;

  $self->app->log->debug("Registering a new plugin...");

  my $ref = $self->req->json;

  my $plugin_name    = $ref->{name};
  my $plugin_methods = $ref->{methods};

  my $r = $self->app->routes;
  for my $meth ( @{$plugin_methods} ) {
    if ( "\L$meth->{meth}" eq "get" ) {
      if ( $meth->{auth} ) {
        $r->get("/1.0/$plugin_name$meth->{url}")->over( authenticated => 1 )
          ->to( "plugin#call_plugin", plugin => $plugin_name );
      }
      else {
        $r->get("/1.0/$plugin_name$meth->{url}")
          ->to( "plugin#call_plugin", plugin => $plugin_name );
      }
    }
  }

  $self->render( json => { ok => Mojo::JSON->true } );
}

sub call_plugin {
  my $self = shift;
  $self->app->log->debug( "Calling plugin: " . $self->param("plugin") );
  $self->render( json => { ok => Mojo::JSON->true } );
}

1;
