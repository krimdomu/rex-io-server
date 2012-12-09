#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Helper::Inventory;
   
use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

use Rex::IO::Server::Helper::IP;

@EXPORT = qw(inventor);

sub inventor {
   my ($self, $hw, $ref) = @_;

#################################################################################
# update bios
#################################################################################
   my $bios_r = $hw->bios;

   my $bios_data = $ref->{CONTENT}->{BIOS};
   if($bios_data->{BDATE}) {
      my ($mon, $day, $year) = split(/\//, $bios_data->{BDATE});
      $bios_data->{BDATE} = "$year-$mon-$day 00:00:00";
   }
   else {
      $bios_data->{BDATE} = "1970-01-01 00:00:00";
   }

   if(my $bios = $bios_r->next) {
      $bios->biosdate     = $bios_data->{BDATE};
      $bios->version      = $bios_data->{BVERSION};
      $bios->ssn          = $bios_data->{SSN};
      $bios->manufacturer = $bios_data->{MANUFACTURER};
      $bios->model        = $bios_data->{SMODEL};

      $bios->update;
   }
   else {
      my $new_bios = Rex::IO::Server::Model::Bios->new(
         hardware_id => $hw->id,
         biosdate    => $bios_data->{BDATE},
         version     => $bios_data->{BVERSION},
         ssn         => $bios_data->{SSN},
         manufacturer   => $bios_data->{MANUFACTURER},
         model       => $bios_data->{SMODEL},
      );
      $new_bios->save;
   }

#################################################################################
# update memories
#################################################################################

   my $mem_r = $hw->memory;

   MEMS: while(my $mem_dev = $mem_r->next) {
      INVMEMS: for my $mem ( @{ $ref->{CONTENT}->{MEMORIES} } ) {

         next INVMEMS unless $mem;

         if($mem_dev->serialnumber eq $mem->{SERIALNUMBER}) {

            $mem_dev->size    = $mem->{CAPACITY};
            $mem_dev->bank    = $mem->{NUMSLOTS} || 0;
            $mem_dev->speed   = $mem->{SPEED};
            $mem_dev->type    = $mem->{TYPE};

            $mem_dev->update;

            $mem = undef;
            next MEMS;

         }

      } # END INVHDDS: for

   }

   for my $mem ( @{ $ref->{CONTENT}->{MEMORIES} } ) {
      next unless $mem;

      my $new_mem = Rex::IO::Server::Model::Memory->new(
         hardware_id  => $hw->id,
         size         => $mem->{CAPACITY},
         bank         => $mem->{NUMSLOTS} || 0,
         serialnumber => $mem->{SERIALNUMBER},
         speed        => $mem->{SPEED},
         type         => $mem->{TYPE},
      );

      $new_mem->save;
   }

#################################################################################
# update processor
#################################################################################

   my $cpu_r = $hw->processor;

   # first remove cpus
   while(my $cpu_dev = $cpu_r->next) {
      $cpu_dev->delete;
   }

   for my $cpu ( @{ $ref->{CONTENT}->{CPUS} } ) {

      my $new_cpu = Rex::IO::Server::Model::Processor->new(
         hardware_id  => $hw->id,
         modelname    => $cpu->{NAME},
         vendor       => $cpu->{MANUFACTURER} || '<UNKNOWN>',
         #flags        => $cpu->{FLAGS},
         mhz          => $cpu->{SPEED},
         #cache        => $mem->{CACHE},
      );

      $new_cpu->save;
   }

#################################################################################
# update harddrives
#################################################################################
   my $hdd_r = $hw->harddrive;

   HDDS: while(my $hdd_dev = $hdd_r->next) {
      INVHDDS: for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {

         next INVHDDS unless $hdd;

         if($hdd_dev->serial eq $hdd->{SERIALNUMBER}) {

            $hdd_dev->size    = $hdd->{DISKSIZE};
            $hdd_dev->vendor  = $hdd->{MANUFACTURER};
            $hdd_dev->devname = $hdd->{NAME};

            $hdd_dev->update;

            $hdd = undef;
            next HDDS;

         }

      } # END INVHDDS: for

   }

   for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {
      next unless $hdd;

      my $new_hdd = Rex::IO::Server::Model::Harddrive->new(
         hardware_id => $hw->id,
         size        => $hdd->{DISKSIZE},
         vendor      => $hdd->{MANUFACTURER},
         devname     => $hdd->{NAME},
         serial      => $hdd->{SERIALNUMBER},
      );

      $new_hdd->save;
   }


#################################################################################
# update operating system
#################################################################################
   my $op_r = $hw->os;
   my ($os_version, $rest) = split(/ /, $ref->{CONTENT}->{HARDWARE}->{OSVERSION});
   my ($os_name, $rest) = split(/ /, $ref->{CONTENT}->{HARDWARE}->{OSNAME});

   $self->app->log->debug("Found OS: $os_name / $os_version");

   my $os_r = Rex::IO::Server::Model::Os->all( 
                  (Rex::IO::Server::Model::Os->version eq $os_version) 
                & (Rex::IO::Server::Model::Os->name eq $os_name)
              );
   my $os = $os_r->next;

   if(my $op = $op_r->next) {
      $self->app->log->debug("updating os");
      $hw->os_id = $os->id;
      $hw->update;
   }
   elsif($os) {
      $self->app->log->debug("Registering new OS");
      $hw->state_id = 4;
      $hw->update;

      $hw->os_id = $os->id;
      $hw->update;
   }
   else {
      $self->app->log->debug("Unknown OS >>$os_name<< and version >>$os_version<<");
   }

#################################################################################
# update network devices
#################################################################################

   my $net_devs = $hw->network_adapter;

   my @new_net_dev;

   NETDEVS: while(my $net_dev = $net_devs->next) {
      INVNET: for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {

         next INVNET unless $net;

         if($net_dev->dev eq $net->{DESCRIPTION}) {

            $net_dev->ip      = ip_to_int($net->{IPADDRESS} || 0);
            $net_dev->netmask = ip_to_int($net->{IPMASK}    || 0);
            $net_dev->network = ip_to_int($net->{IPSUBNET}  || 0);
            $net_dev->gateway = ip_to_int($net->{IPGATEWAY} || 0);
            $net_dev->mac     = $net->{MACADDR};

            $net_dev->update;

            $net = undef;
            next NETDEVS;

         }

      } # END INVENTORY: for

   }

   for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
      next unless $net;

      my $new_hw = Rex::IO::Server::Model::NetworkAdapter->new(
         hardware_id => $hw->id,
         dev         => $net->{DESCRIPTION},
         ip          => ip_to_int($net->{IPADDRESS} || 0),
         netmask     => ip_to_int($net->{IPMASK}    || 0),
         network     => ip_to_int($net->{IPSUBNET}  || 0),
         gateway     => ip_to_int($net->{IPGATEWAY} || 0),
         proto       => "static",
         mac         => $net->{MACADDR},
      );

      $new_hw->save;
   }

   $self->app->log->debug("hardware updated");

}

1;
