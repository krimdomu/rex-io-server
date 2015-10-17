#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
# vim: set ft=perl:

package Rex::Lang::Perl::Carton;

use strict;
use warnings;

use Rex -base;
use Carp;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(carton);

sub carton {
    my $command = shift;

    my $cmd;
    if ( $command eq "-install" ) {
        $cmd = "carton install";
    }
    elsif ( $command eq "-exec" ) {
        $cmd = "carton exec $_[0]";
    }

    my $out = run "$cmd 2>&1";
    print $out . "\n";
    if ( $? != 0 ) {
        confess "Error running command: $cmd";
    }
}

1;
