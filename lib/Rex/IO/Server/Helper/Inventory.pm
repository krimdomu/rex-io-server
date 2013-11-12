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
use Rex::IO::Server::Helper::Fdisk;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use List::MoreUtils qw/uniq/;


@EXPORT = qw(inventor);

sub inventor {
   my ($self, $hw, $ref) = @_;

   $hw->discard_changes; # get new infos from db (needed for relations)

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
      $self->app->log->debug(Dumper($bios_data));

      my $new_bios = $self->db->resultset("Bios")->create({
         hardware_id  => $hw->id,
         biosdate     => (ref $bios_data->{BDATE} ? "" : $bios_data->{BDATE}),
         version      => (ref $bios_data->{BVERSION} ? "" : $bios_data->{BVERSION}),
         ssn          => (ref $bios_data->{SSN} ? "" : $bios_data->{SSN}),
         manufacturer => (ref $bios_data->{MANUFACTURER} ? 
                                 (
                                    ref $bios_data->{BMANUFACTURER} ?
                                       (
                                          ref $bios_data->{SMANUFACTURER} ?
                                             ""
                                          : $bios_data->{SMANUFACTURER}
                                       )
                                    : $bios_data->{BMANUFACTURER} 
                                 )
                              : $bios_data->{MANUFACTURER}),
         model        => (ref $bios_data->{SMODEL} ? "" : $bios_data->{SMODEL}),
      });
   }
   $self->app->log->debug("Bios updated");

#################################################################################
# update memories
#################################################################################

   $self->app->log->debug("Updating memory information");
   $self->app->log->debug(Dumper($ref->{CONTENT}->{MEMORIES}));

   my $mem_r = $hw->memories;

   MEMS: while(my $mem_dev = $mem_r->next) {
      $self->app->log->debug("Updating already registered memory");
      INVMEMS: for my $mem ( @{ $ref->{CONTENT}->{MEMORIES} } ) {

         next INVMEMS unless $mem;
         next unless($mem->{CAPACITY});
         next unless($mem->{CAPACITY} =~ m/^\d+$/);

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
      next unless($mem->{CAPACITY});
      next unless($mem->{CAPACITY} =~ m/^\d+$/);

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
   $self->app->log->debug(Dumper($ref->{CONTENT}->{CPUS}));

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
   $self->app->log->debug(Dumper($ref->{CONTENT}->{STORAGES}));

   my $hdd_r = $hw->harddrives;

   my $fdisk;

   if(exists $ref->{fdisk}) {
      $self->app->log->debug("fdisk fallback available");
      my @lines = split(/\n/, $ref->{fdisk});
      $fdisk = read_fdisk(@lines);
      $self->app->log->debug(Dumper($fdisk));
   }

   HDDS: while(my $hdd_dev = $hdd_r->next) {
      $self->app->log->debug("Updating existing harddrives");
      INVHDDS: for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {

         next INVHDDS unless $hdd;

         if(! exists $hdd->{SERIALNUMBER}) {
            $hdd->{SERIALNUMBER} = md5_hex($hdd->{NAME} . "-" . $hdd->{DESCRIPTION} . "-" . $hdd->{MANUFACTURER} . "-" . $hdd->{TYPE});
         }

         if(! exists $hdd->{DISKSIZE}) {
            # fallback to fdisk data if available
            if(exists $ref->{fdisk}) {
               $hdd->{DISKSIZE} = $fdisk->{"/dev/" . $hdd->{NAME}}->{size} / 1024 / 1024;
               $self->app->log->debug("New Disksize: " . $hdd->{DISKSIZE});
            }
         }

         if($hdd_dev->serial eq $hdd->{SERIALNUMBER}) {
            $self->app->log->debug("Updating harddrive id: " . $hdd_dev->id . " / " . $hdd_dev->serial);
            $hdd_dev->update({
               size => $hdd->{DISKSIZE},
               vendor => (ref $hdd->{MANUFACTURER} ? "" : $hdd->{MANUFACTURER}),
               devname => $hdd->{NAME},
            });

            $hdd = undef;
            next HDDS;

         }

      } # END INVHDDS: for

   }


   for my $hdd ( @{ $ref->{CONTENT}->{STORAGES} } ) {
      next unless $hdd;
      next unless ($hdd->{TYPE} eq "disk");

      if(! exists $hdd->{DISKSIZE}) {
         # fallback to fdisk data if available
         if(exists $ref->{fdisk}) {
            $hdd->{DISKSIZE} = $fdisk->{"/dev/" . $hdd->{NAME}}->{size} / 1024 / 1024;
            $self->app->log->debug("New Disksize: " . $hdd->{DISKSIZE});
         }
      }

      $self->app->log->debug("Adding new harddrive");
      my $new_hdd = $self->db->resultset("Harddrive")->create({
         hardware_id => $hw->id,
         size        => $hdd->{DISKSIZE},
         vendor      => (ref $hdd->{MANUFACTURER} ? "" : $hdd->{MANUFACTURER}),
         devname     => (ref $hdd->{NAME} ? "" : $hdd->{NAME}),
         serial      => (ref $hdd->{SERIALNUMBER} ? 
                           md5_hex($hdd->{NAME} . "-" . $hdd->{DESCRIPTION} . "-" . $hdd->{MANUFACTURER} . "-" . $hdd->{TYPE})
                         : $hdd->{SERIALNUMBER}),
      });
   }

   $self->app->log->debug("Updated harddrives.");


#################################################################################
# update operating system
#################################################################################
   $self->app->log->debug("Updating OS information");
   $self->app->log->debug(Dumper($ref->{CONTENT}->{HARDWARE}));

   my $op_r = $hw->os;

   my $os_version = $ref->{CONTENT}->{HARDWARE}->{OSVERSION};
   my $os_name    = $ref->{CONTENT}->{HARDWARE}->{OSNAME};

   $self->app->log->debug("Found OS: $os_name / $os_version");

   my $os_r = $self->db->resultset("Os")->search(
      {
         version => $os_version,
         name    => $os_name,
      },
   );

   #my $os_r = Rex::IO::Server::Model::Os->all( 
   #               (Rex::IO::Server::Model::Os->version eq $os_version) 
   #             & (Rex::IO::Server::Model::Os->name eq $os_name)
   #           );
   my $os = $os_r->next;

   unless($os) {
      my ($rest, $rest2, $start);
      ($start, $os_version) = split(/ /, $os_name);
      $self->app->log->debug("os not found trying with $os_name / $os_version");

      $os_r = $self->db->resultset("Os")->search(
         {
            version => $os_version,
            name    => $os_name,
         },
      );

      $os = $os_r->next;

      unless($os) {
         ($os_name, $rest2) = split(/ /, $os_name);
         $self->app->log->debug("os not found trying with $os_name / $os_version");

         $os_r = $self->db->resultset("Os")->search(
            {
               version => $os_version,
               name    => $os_name,
            },
         );

         $os = $os_r->next;
      }
   }

   if(my $op = $op_r) {
      $self->app->log->debug("updating os");
      $hw->update({
         os_id => $os->id,
      });
   }
   elsif($os) {
      $self->app->log->debug("Registering new OS");
      $hw->update({
         state_id => 4,
         os_id    => $os->id,
      });
   }
   else {
      $self->app->log->debug("Unknown OS >>$os_name<< and version >>$os_version<<");
   }

   $self->app->log->debug("Updated OS information");

#################################################################################
# update network devices
#################################################################################

   $self->app->log->debug("Updating network adapters");
   $self->app->log->debug(Dumper($ref->{CONTENT}->{NETWORKS}));

   my $net_devs = $hw->network_adapters;

   my @new_net_dev;

   NETDEVS: while(my $net_dev = $net_devs->next) {
      INVNET: for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {

         next INVNET unless $net;

         if($net_dev->dev eq $net->{DESCRIPTION}) {
            $self->app->log->debug("Updating existing network adapter: " . $net_dev->id);

            $net_dev->update({
               ip      => ip_to_int($net->{IPADDRESS} || 0),
               netmask => ip_to_int($net->{IPMASK} || 0),
               network => ip_to_int($net->{IPSUBNET} || 0),
               gateway => ip_to_int($net->{IPGATEWAY} || 0),

               wanted_ip      => ip_to_int($net->{IPADDRESS} || 0),
               wanted_netmask => ip_to_int($net->{IPMASK} || 0),
               wanted_network => ip_to_int($net->{IPSUBNET} || 0),
               wanted_gateway => ip_to_int($net->{IPGATEWAY} || 0),

               mac => $net->{MACADDR} || "",
               virtual => (ref $net->{VIRTUALDEV} ? 0 : $net->{VIRTUALDEV}) ,
            });

            my (@to_undef) = grep { $_->{DESCRIPTION} eq $net_dev->dev } @{ $ref->{CONTENT}->{NETWORKS} };

            for my $to_undef_net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
               if($to_undef_net->{DESCRIPTION} eq $net_dev->dev) {
                  $to_undef_net = undef;
               }
            }

            next NETDEVS;

         }

      } # END INVENTORY: for

   }

   if(scalar(@{ $ref->{CONTENT}->{NETWORKS} })) {

   my @found_net_devs = uniq(map { exists $_->{DESCRIPTION} && $_->{DESCRIPTION} } @{ $ref->{CONTENT}->{NETWORKS} });
   my @already_created = ();

   #for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
   for my $dev ( @found_net_devs ) {

      next unless($dev);
      my $net;

      my @all_conf = grep { exists $_->{DESCRIPTION} && $_->{DESCRIPTION} eq $dev } @{ $ref->{CONTENT}->{NETWORKS} };

      if(scalar(@all_conf) > 1) {
         my ($with_ip_address) = grep { exists $_->{IPADDRESS} } @all_conf;

         if($with_ip_address) {
            $net = $with_ip_address;
         }
         else {
            $net = $all_conf[0];
         }
      }
      elsif(scalar(@all_conf) == 1) {
         $net = $all_conf[0];
      }
      else {
         next;
      }

      my $new_hw = $self->db->resultset("NetworkAdapter")->create({
         hardware_id => $hw->id,
         dev         => $net->{DESCRIPTION},
         ip          => ip_to_int($net->{IPADDRESS} || 0),
         netmask     => ip_to_int($net->{IPMASK}    || 0),
         network     => ip_to_int($net->{IPSUBNET}  || 0),
         gateway     => ip_to_int($net->{IPGATEWAY} || 0),
         virtual     => (ref $net->{VIRTUALDEV} ? 0 : $net->{VIRTUALDEV}),
         proto       => "static",
         mac         => (ref $net->{MACADDR} ? "" : $net->{MACADDR}),
      });

   }
   }

   $self->app->log->debug("Networkadapter updated");

   $self->app->log->debug("hardware updated");

   # plugin inventory
   for my $plug (@{ $self->config->{plugins} }) {
      my $s = "Rex::IO::Server::$plug";
      eval "require $s";
      eval {
         $s->__inventor__($hw, $self->db, $ref);
      };
   }



}

1;
