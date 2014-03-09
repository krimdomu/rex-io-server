#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Log::Output;

use strict;
use warnings;

sub create {
  my ($class, $type, %opt) = @_;

  my $klass = "Rex::IO::Server::Log::Output::$type";
  eval "use $klass";
  if($@) {
    die("Error loading Log Output module.");
  }

  my $c = $klass->new(%opt);
  return $c;
}

1;
