#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Helper::IP;
   
use strict;
use warnings;

use Socket;

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT);
@EXPORT = qw(ip_to_int int_to_ip);

sub ip_to_int {
   return unpack "N", inet_aton($_[0]);
}

sub int_to_ip {
   return inet_ntoa(pack ("N", $_[0]));
}

1;
