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
        return $self->render( json =>
              { ok => Mojo::JSON->false, error => "No plugin name specified." }
        );
    }

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
            for my $plugin_name ( keys %plugin_hooks ) {
                for my $plugin_action ( keys %{ $plugin_hooks{$plugin_name} } )
                {
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

    my @permissions;
    if ( $self->authenticated ) {
        $self->app->log->debug(
            "User permissions: (" . $self->current_user() . ")" );
        @permissions =
          map { $_->name } $self->current_user()->get_permissions();
        $self->app->log->debug( Dumper( \@permissions ) );
    }

    if ( exists $config->{func} ) {
        $config->{func}->($self);
    }

    if ( exists $config->{location} ) {
        my $ua          = Mojo::UserAgent->new;
        my $backend_url = $config->{location};
        $self->app->log->debug("Backend-URL: $backend_url");

        my @params = ( $config->{url} =~ m/:(\w+)/g );
        $self->app->log->debug(
            "Found Backend-Params: " . join( ", ", @params ) );

        for my $p (@params) {
            my $param_data = $self->param($p);
            if ( !$param_data ) {
                return $self->render(
                    json => {
                        ok      => Mojo::JSON->false,
                        message => "Invalid parameters."
                    },
                    status => 500
                );
            }
            $backend_url =~ s/:\Q$p\E/$param_data/;
        }
        $backend_url .= "?" . $self->req->url->query;
        $self->app->log->debug("Parsed-Backend-URL: $backend_url");

        my $meth = $self->req->method;
        my $tx   = $ua->build_tx(
            $meth => $backend_url => {
                "Accept"              => "application/json",
                "X-RexIO-Permissions" => join( ",", @permissions ),
                "X-RexIO-User"        => $self->current_user()->name,
                "X-RexIO-Password"    => $self->current_user()->password,
                "X-RexIO-Group"    => $self->current_user()->group_id,
            } => json => $self->req->json
        );

        # do an async call
        Mojo::IOLoop->delay(
            sub {
                $ua->start(
                    $tx,
                    sub {
                        my ( $ua, $tx ) = @_;
                        if ( $tx->success ) {
                            my $ref = $tx->res->json;
                            $self->_filter_acl($ref);
                            if ( exists $ref->{data} ) {
                                $ref->{data} =
                                  [ grep { $_ } @{ $ref->{data} } ];
                            }
                            $self->render( json => $ref );
                        }
                        else {
                            my $ref = $tx->res->json;
                            if ($ref) {
                                $self->_filter_acl($ref);
                                if ( exists $ref->{data} ) {
                                    $ref->{data} =
                                      [ grep { $_ } @{ $ref->{data} } ];
                                }
                                $self->render(
                                    json   => $ref,
                                    status => $tx->res->code
                                );
                            }
                            else {
                                $self->render(
                                    json => {
                                        ok    => Mojo::JSON->false,
                                        error => "Unknown error."
                                    },
                                    status => $tx->res->code
                                );
                            }
                        }
                    }
                );
            }
        );

        $self->render_later();
    }
}

sub _filter_acl {
    my $self = shift;
    my $ref  = shift;

    if ( !exists $ref->{data} ) {
        return;
    }

    if ( ref $ref->{data} eq "ARRAY" ) {
        for my $data ( @{ $ref->{data} } ) {
            if ( exists $data->{permission_set_id} ) {
                if ( $data->{permission_set_id} ) {

                    # TODO: check for permissions
                    #$data = undef;
                }
            }
        }
    }
}

1;
