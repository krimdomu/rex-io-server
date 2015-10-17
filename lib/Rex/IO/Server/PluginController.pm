#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::PluginController;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub render {
    my ( $self, @rest ) = @_;
    $self->app->log->debug("Rendering:");
    $self->app->log->debug( Dumper( \@rest ) );

    my $config = $self->param("config");
    $self->app->log->debug( "config from BaseController:\n" . Dumper($config) );

    my %shared_data = $self->shared_data();
    $self->app->log->debug(
        "shared data from BaseController:\n" . Dumper( \%shared_data ) );

    my @permissions;

    if ( $self->authenticated ) {
        $self->app->log->debug( "User permissions from BaseController: ("
              . $self->current_user()
              . ")" );
        @permissions =
          map { $_->name } $self->current_user()->get_permissions();
        $self->app->log->debug( Dumper( \@permissions ) );
    }

    if (   $config
        && exists $shared_data{plugin_hooks}->{ $config->{plugin} }
        && exists $shared_data{plugin_hooks}->{ $config->{plugin} }
        ->{ $config->{url} } )
    {
        # we need to call a hook
        my $plugins =
          $shared_data{plugin_hooks}->{ $config->{plugin} }->{ $config->{url} };

        for my $plugin ( @{$plugins} ) {

            $self->app->log->debug(
                "calling plugin from BaseController:\n" . Dumper($plugin) );

            if ( exists $plugin->{location} ) {
                my $ua          = Mojo::UserAgent->new;
                my $backend_url = $plugin->{location};
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
                        "X-RexIO-Password" => $self->current_user()->password,
                        "X-RexIO-Group"    => $self->current_user()->group_id,
                    } => json => $self->req->json
                );

                my $resp =
                  $ua->post(
                    $backend_url => { "Accept" => "application/json" } =>
                      json => \@rest );
                if ( my $res = $resp->success ) {
                    $self->app->log->debug("Got an answer from $backend_url.");
                    @rest = @{ $res->json };
                }
                else {
                    $self->app->log->error("Failed calling $backend_url");
                }
            }
        }

    }

    $self->SUPER::render(@rest);
}

1;
