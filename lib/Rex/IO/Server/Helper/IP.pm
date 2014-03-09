#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
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
  return 0 unless ($_[0] =~ m/\d+\.\d+\.\d+\.\d+/);
  return unpack "N", inet_aton($_[0]);
}

sub int_to_ip {
  return 0 unless($_[0]);
  return inet_ntoa(pack ("N", $_[0]));
}

1;
