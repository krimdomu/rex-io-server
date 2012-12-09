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

      $ref->{CONTENT} = _normalize_hash($ref->{CONTENT});

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

      # update operating system
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

      # update network cards
      my $net_devs = $hw->network_adapter;

      my @new_net_dev;

      NETDEVS: while(my $net_dev = $net_devs->next) {
         INVENTORY: for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {

            next INVENTORY unless $net;

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
