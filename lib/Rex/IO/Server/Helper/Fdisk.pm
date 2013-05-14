#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Helper::Fdisk;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT);

@EXPORT = qw(read_fdisk);

sub read_fdisk {
   my (@fdisk) = @_;
   chomp @fdisk;

   my $ret = {};

   my $current_disk;

   for my $line (@fdisk) {
      next if($line =~ m/^$/);
      next if($line =~ m/^\s*$/);

      if($line =~ m/^Disk \/dev\/([^:]+):/) {
         $current_disk = "/dev/$1";

         my ($size) = ($line =~ m/(\d+) bytes$/);
         $ret->{$current_disk}->{size} = $1;
         next;
      }

      if($line =~ m/^\d+ heads/) {
         my ($heads, $sect_per_track, $cyl, $sect) = ($line =~ m/^(\d+) heads, (\d+) sectors[^,]+, (\d+) cylinders, total (\d+) sectors/);
         $ret->{$current_disk}->{heads} = $heads;
         $ret->{$current_disk}->{sectors_per_track} = $sect_per_track;
         $ret->{$current_disk}->{cylinders} = $cyl;
         $ret->{$current_disk}->{sectors} = $sect;
      }
   }

   return $ret;
}

1;
