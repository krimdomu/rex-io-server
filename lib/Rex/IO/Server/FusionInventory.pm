#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::FusionInventory;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use XML::Simple;
use Compress::Zlib;

use Data::Dumper;
use Rex::IO::Server::Helper::IP;

sub post {
   my ($self) = @_;

   my $data = uncompress($self->req->body);
   my $ref = XMLin($data);

   if($ref->{QUERY} eq "PROLOG") {
      $self->render_data(
         compress(
            '<?xml version="1.0" encoding="UTF-8"?><REPLY><PROLOG_FREQ>60</PROLOG_FREQ><RESPONSE>SEND</RESPONSE></REPLY>'
         )
      );
   }
   elsif($ref->{QUERY} eq "INVENTORY") {
      my $server = $ref->{CONTENT}->{HARDWARE}->{NAME};

      # delete the processlist
      delete $ref->{CONTENT}->{PROCESSES};
      # delete the envs
      delete $ref->{CONTENT}->{ENVS};
      # delete the softwares
      delete $ref->{CONTENT}->{SOFTWARES};

#      $ref->{CONTENT} = _normalize_hash($ref->{CONTENT});

      # convert to array if not array
      if(ref($ref->{CONTENT}->{STORAGES}) ne "ARRAY") {
         $ref->{CONTENT}->{STORAGE} = [ $ref->{CONTENT}->{STORAGES} ];
      }
      if(ref($ref->{CONTENT}->{NETWORKS}) ne "ARRAY") {
         $ref->{CONTENT}->{NETWORKS} = [ $ref->{CONTENT}->{NETWORKS} ];
      }
      if(ref($ref->{CONTENT}->{MEMORIES}) ne "ARRAY") {
         $ref->{CONTENT}->{MEMORIES} = [ $ref->{CONTENT}->{MEMORIES} ];
      }
      if(ref($ref->{CONTENT}->{CPUS}) ne "ARRAY") {
         $ref->{CONTENT}->{CPUS} = [ $ref->{CONTENT}->{CPUS} ];
      }

      my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->uuid eq $ref->{CONTENT}->{HARDWARE}->{UUID} );
      my $hw = $hw_r->next;
      if($hw) {
         # hardware found 
         $self->app->log->debug("Found hardware's uuid");
      }
      else {
         for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
            $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->ip eq ip_to_int($net->{IPADDRESS} || 0) );
            $hw = $hw_r->next;
            if($hw) {
               $self->app->log->debug("Found hardware through ip address");
               last;
            }
         }
      }

      unless($hw) {
         $self->app->log->debug("nothing found!");
      }

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
      my $os_name = $ref->{CONTENT}->{HARDWARE}->{OSNAME};
      my ($os_version, $rest) = split(/ /, $ref->{CONTENT}->{HARDWARE}->{OSVERSION});

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
      else {
         $self->app->log->debug("Registering new OS");
         $hw->state_id = 4;
         $hw->update;

         $hw->os_id = $os->id;
         $hw->update;
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



      #if(! ref($data) ) {
      #   $self->render_data(
      #      compress(
      #         '<?xml version="1.0" encoding="UTF-8"?><REPLY>ACCOUNT_NOT_UPDATED</REPLY>'
      #      ),
      #      status => 500
      #   );
      #}
      #else {
         $self->render_data(
            compress(
               '<?xml version="1.0" encoding="UTF-8"?><REPLY>><RESPONSE>ACCOUNT_UPDATE</RESPONSE></REPLY>'
            )
         );
      #}
   }
}

sub _normalize_hash {
   my ($h) = @_;

   for my $key (keys %{$h}) {
      if(ref($h->{$key}) eq "ARRAY") {
         $h->{$key} = _normalize_array($h->{$key});
      }
      elsif(ref($h->{$key}) eq "HASH") {
         my @tmp = %{ $h->{$key} };
         if(scalar(@tmp) == 0) {
            $h->{$key} = "";
         }
         else {
            $h->{$key} = _normalize_hash($h->{$key});
         }
      }
      else {
         $h->{$key} = _normalize_scalar($h->{$key});
      }
   }

   return $h;
}

sub _normalize_scalar {
   my ($s) = @_;

   if($s) {
      return $s;
   }

   return "";
}

sub _normalize_array {
   my ($a) = @_;

   for (@{$a}) {
      if(ref($_) eq "ARRAY") {
         $_ = _normalize_array($_);
      }
      elsif(ref($_) eq "HASH") {
         $_ = _normalize_hash($_);
      }
      else {
         $_ = _normalize_scalar($_);
      }
   }

   return $a;
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/fusioninventory")->to("fusion_inventory#post");
}

1;
