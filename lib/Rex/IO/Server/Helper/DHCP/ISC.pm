#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Helper::DHCP::ISC;

use strict;
use warnings;

use IPC::Open2;
use Data::Dumper;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get_mac_from_ip {
   my ($self, $ip) = @_;
   my @data = $self->_call("connect", "new lease", "set ip-address = $ip", "open");
   chomp @data;

   my ($mac_line) = grep { /^hardware-address/ } @data;

   if(!$mac_line) {
      return undef;
   }

   my ($mac) = ($mac_line =~ m/= (.*)$/);

   return $mac;
}

sub _call {
   my ($self, @cmd) = @_;

   my ($out, $in);
   open2($out, $in, "omshell");

   print $in "server 192.168.1.6\n";

   my $ret = {};
   for (@cmd) {
      print $in "$_\n";
   }

   close($in);

   my $out_str = do {
      local $/;
      <$out>;
   };

   return split(/\n/, $out_str);
}

1;
