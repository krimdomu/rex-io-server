#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Mojolicious::Plugin::IP;

use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::IO::Server::Helper::IP;
use base 'Mojolicious::Plugin';

my $cache;

sub register {
    my ( $plugin, $app ) = @_;

    $app->helper(
        int_to_ip => sub {
            my $self = shift;
            return int_to_ip( $_[0] );
        },
        ip_to_int => sub {
            my $self = shift;
            return ip_to_int( $_[0] );
        },
    );
}

1;
