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
use Data::Dumper;

@EXPORT = qw(inventor);

sub inventor {
   my ($self, $hw, $ref) = @_;

#################################################################################
# update bios
#################################################################################
   $self->app->log->debug("Updating BIOS");
   my $bios_r = $hw->bios;

   my $bios_data = $ref->{CONTENT}->{BIOS};
   if($bios_data->{BDATE}) {
      my ($mon, $day, $year) = split(/\//, $bios_data->{BDATE});
      $bios_data->{BDATE} = "$year-$mon-$day 00:00:00";
   }
   else {
      $bios_data->{BDATE} = "1970-01-01 00:00:00";
   }

   if(my $bios = $bios_r) {
      $self->app->log->debug("Found existing Bios");
      $bios->update({
         biosdate => $bios_data->{BDATE},
         version  => $bios_data->{BVERSION},
         ssn      => $bios_data->{SSN},
         manufacturer => $bios_data->{MANUFACTURER},
         model        => $bios_data->{SMODEL},
      });
   }
   else {
      $self->app->log->debug("Creating new Bios entry");
      my $new_bios = $self->db->resultset("Bios")->create({
         hardware_id  => $hw->id,
         biosdate     => $bios_data->{BDATE},
         version      => $bios_data->{BVERSION},
         ssn          => $bios_data->{SSN},
         manufacturer => $bios_data->{MANUFACTURER},
         model        => $bios_data->{SMODEL},
      });
   }
   $self->app->log->debug("Bios updated");

#################################################################################
# update memories
#################################################################################

   $self->app->log->debug("Updating memory information");
   my $mem_r = $hw->memories;

   MEMS: while(my $mem_dev = $mem_r->next) {
      $self->app->log->debug("Updating already registered memory");
      INVMEMS: for my $mem ( @{ $ref->{CONTENT}->{MEMORIES} } ) {

         next INVMEMS unless $mem;

         if($mem_dev->serialnumber eq $mem->{SERIALNUMBER}) {

            $mem_dev->update({
                  size => $mem->{CAPACITY},
                  bank => $mem->{NUMSLOTS} || 0,
                  speed => $mem->{SPEED},
                  type  => $mem->{TYPE},
            });

            $mem = undef;
            next MEMS;

         }

      } # END INVHDDS: for

   }

   for my $mem ( @{ $ref->{CONTENT}->{MEMORIES} } ) {
      next unless $mem;
      $self->app->log->debug("Creating new memory entry");

      my $new_mem = $self->db->resultset("Memory")->create({
         hardware_id  => $hw->id,
         size         => $mem->{CAPACITY},
         bank         => $mem->{NUMSLOTS} || 0,
         serialnumber => $mem->{SERIALNUMBER},
         speed        => $mem->{SPEED},
         type         => $mem->{TYPE},
      });
   }

   $self->app->log->debug("Updated memory information");

#################################################################################
# update processor
#################################################################################

   $self->app->log->debug("Updating cpu information");
   my $cpu_r = $hw->processors;

   # first remove cpus
   $self->app->log->debug("First deleting cpus");
   while(my $cpu_dev = $cpu_r->next) {
      $self->app->log->debug("   id: " . $cpu_dev->id);
      $cpu_dev->delete;
   }

   for my $cpu ( @{ $ref->{CONTENT}->{CPUS} } ) {

      $self->app->log->debug("Adding new cpu");
      my $new_cpu = $self->db->resultset("Processor")->create({
         hardware_id  => $hw->id,
         modelname    => $cpu->{NAME},
         vendor       => $cpu->{MANUFACTURER} || '<UNKNOWN>',
         #flags        => $cpu->{FLAGS},
         mhz          => $cpu->{SPEED},
         #cache        => $mem->{CACHE},
      });
   }

   $self->app->log->debug("Updated cpu information");

#################################################################################
# update harddrives
#################################################################################
   $self->app->log->debug("Updating harddrives");
   my $hdd_r = $hw->harddrives;

   HDDS: while(my $hdd_dev = $hdd_r->next) {
      $self->app->log->debug("Updating existing harddrives");
      INVHDDS: for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {

         next INVHDDS unless $hdd;
         next INVHDDS unless $hdd->{SERIALNUMBER};

         if($hdd_dev->serial eq $hdd->{SERIALNUMBER}) {
            $self->app->log->debug("Updating harddrive id: " . $hdd_dev->id . " / " . $hdd_dev->serial);
            $hdd_dev->update({
               size => $hdd->{DISKSIZE},
               vendor => $hdd->{MANUFACTURER},
               devname => $hdd->{NAME},
            });

            $hdd = undef;
            next HDDS;

         }

      } # END INVHDDS: for

   }

   for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {
      next unless $hdd;
      $self->app->log->debug("Adding new harddrive");
      my $new_hdd = $self->db->resultset("Harddrive")->create({
         hardware_id => $hw->id,
         size        => $hdd->{DISKSIZE},
         vendor      => $hdd->{MANUFACTURER},
         devname     => $hdd->{NAME},
         serial      => $hdd->{SERIALNUMBER},
      });
   }

   $self->app->log->debug("Updated harddrives.");


#################################################################################
# update operating system
#################################################################################
   $self->app->log->debug("Updating OS information");
   my $op_r = $hw->os;

   my $os_version = $ref->{CONTENT}->{HARDWARE}->{OSVERSION};
   my $os_name    = $ref->{CONTENT}->{HARDWARE}->{OSNAME};

   $self->app->log->debug("Found OS: $os_name / $os_version");

   my $os_r = Rex::IO::Server::Model::Os->all( 
                  (Rex::IO::Server::Model::Os->version eq $os_version) 
                & (Rex::IO::Server::Model::Os->name eq $os_name)
              );
   my $os = $os_r->next;

   unless($os) {
      my ($rest, $rest2);
      ($os_version, $rest) = split(/ /, $os_version);

      $os_r = Rex::IO::Server::Model::Os->all( 
                  (Rex::IO::Server::Model::Os->version eq $os_version) 
                & (Rex::IO::Server::Model::Os->name eq $os_name)
              );
      $os = $os_r->next;

      unless($os) {
         ($os_name, $rest2) = split(/ /, $os_name);

         $os_r = Rex::IO::Server::Model::Os->all( 
                  (Rex::IO::Server::Model::Os->version eq $os_version) 
                & (Rex::IO::Server::Model::Os->name eq $os_name)
              );
         $os = $os_r->next;
      }
   }

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
            $net_dev->virtual = $net->{VIRTUALDEV};

            $net_dev->update;

            $net = undef;
            next NETDEVS;

         }

      } # END INVENTORY: for

   }

   for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
      next unless $net;
      next if (exists $net->{IPSUBNET6} && ! exists $net->{IPSUBNET});

      my $new_hw = Rex::IO::Server::Model::NetworkAdapter->new(
         hardware_id => $hw->id,
         dev         => $net->{DESCRIPTION},
         ip          => ip_to_int($net->{IPADDRESS} || 0),
         netmask     => ip_to_int($net->{IPMASK}    || 0),
         network     => ip_to_int($net->{IPSUBNET}  || 0),
         gateway     => ip_to_int($net->{IPGATEWAY} || 0),
         virtual     => $net->{VIRTUALDEV},
         proto       => "static",
         mac         => $net->{MACADDR},
      );

      $new_hw->save;
   }

   $self->app->log->debug("hardware updated");

}

1;
