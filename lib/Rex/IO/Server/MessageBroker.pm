#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::MessageBroker;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Mojo::JSON;
use Mojo::UserAgent;
use Rex::IO::Server::Helper::IP;

my $clients = {};

sub broker {
   my ($self) = @_;

   warn "client connected: ". $self->tx->remote_address . "\n";

   push(@{ $clients->{$self->tx->remote_address} }, { tx => $self->tx, tx_id => sprintf("%s", $self->tx) });

   Mojo::IOLoop->stream($self->tx->connection)->timeout(300);

   $self->send(Mojo::JSON->encode({type => "welcome", welcome => "Welcome to the real world."}));

   $self->on(finish => sub {
      warn "client disconnected\n";
      my $new_clients = {};

      for my $cl (keys %$clients) {
         for my $cl_conn ( @{ $clients->{$cl} } ) {
            if($cl_conn->{tx_id} ne sprintf("%s", $self->tx)) {
               push(@{ $new_clients->{$cl} }, $cl_conn);
            }
         }
      }

      $clients = $new_clients;
   });

   $self->on(message => sub {
      my ($tx, $message) = @_;

      my $json = Mojo::JSON->decode($message);

      if(exists $json->{type} && $json->{type} eq "hello") {

         map { $_->{info} = $json } @{ $clients->{$self->tx->remote_address} };

         my @mac_addresses = ();
         for my $eth (@{ $json->{info}->{CONTENT}->{NETWORKS} }) {
            push(@mac_addresses, $eth->{MACADDR});
         }

         my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->mac == \@mac_addresses );

         if(! $hw->next) {
            my ($eth_dev) = grep { exists $_->{IPADDRESS} && $_->{IPADDRESS} eq $self->tx->remote_address } @{ $json->{info}->{CONTENT}->{NETWORKS} };

            eval {

               # convert to array if not array
               if(ref($json->{info}->{CONTENT}->{STORAGES}) ne "ARRAY") {
                  $json->{info}->{CONTENT}->{STORAGE} = [ $json->{info}->{CONTENT}->{STORAGES} ];
               }
               if(ref($json->{info}->{CONTENT}->{NETWORKS}) ne "ARRAY") {
                  $json->{info}->{CONTENT}->{NETWORKS} = [ $json->{info}->{CONTENT}->{NETWORKS} ];
               }
               if(ref($json->{info}->{CONTENT}->{MEMORIES}) ne "ARRAY") {
                  $json->{info}->{CONTENT}->{MEMORIES} = [ $json->{info}->{CONTENT}->{MEMORIES} ];
               }
               if(ref($json->{info}->{CONTENT}->{CPUS}) ne "ARRAY") {
                  $json->{info}->{CONTENT}->{CPUS} = [ $json->{info}->{CONTENT}->{CPUS} ];
               }

               my $new_hw = Rex::IO::Server::Model::Hardware->new(
                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
                  uuid => $json->{info}->{CONTENT}->{HARDWARE}->{UUID} || '',
               );
               $new_hw->save;
               for my $eth (@{ $json->{info}->{CONTENT}->{NETWORKS} }) {

                  #next if ($eth->{VIRTUALDEV} == 1);
                  # for now, skip ipv6
                  next if (exists $eth->{IPSUBNET6});

                  my $new_nw_a = Rex::IO::Server::Model::NetworkAdapter->new(
                     dev         => $eth->{DESCRIPTION},
                     hardware_id => $new_hw->id,
                     proto       => "static",
                     ip          => ! ref($eth->{IPADDRESS}) ? ip_to_int($eth->{IPADDRESS} || 0) : 0,
                     netmask     => ! ref($eth->{IPMASK})    ? ip_to_int($eth->{IPMASK}    || 0) : 0,
                     network     => ! ref($eth->{IPSUBNET})  ? ip_to_int($eth->{IPSUBNET}  || 0) : 0,
                     gateway     => ! ref($eth->{IPGATEWAY}) ? ip_to_int($eth->{IPGATEWAY} || 0) : 0,
                     mac         => $eth->{MACADDR},
                  );

                  $new_nw_a->save;

               }

               for my $storage (@{ $json->{info}->{CONTENT}->{STORAGES} }) {

                  next if ($storage->{TYPE} ne "disk");

                  my $new_store = Rex::IO::Server::Model::Harddrive->new(
                     hardware_id => $new_hw->id,
                     devname     => $storage->{NAME},
                     size        => $storage->{DISKSIZE},
                     vendor      => $storage->{MANUFACTURER},
                  );

                  $new_store->save;

               }

               my $bios_data = $json->{info}->{CONTENT}->{BIOS};
               my ($mon, $day, $year) = split(/\//, $bios_data->{BDATE});

               $bios_data->{BDATE} = "$year-$mon-$day 00:00:00";

               my $new_bios = Rex::IO::Server::Model::Bios->new(
                  hardware_id => $new_hw->id,
                  biosdate    => $bios_data->{BDATE},
                  version     => $bios_data->{BVERSION},
                  ssn         => $bios_data->{SSN},
                  manufacturer   => $bios_data->{MANUFACTURER},
                  model       => $bios_data->{SMODEL},
               );

               $new_bios->save;

               for my $mem (@{ $json->{info}->{CONTENT}->{MEMORIES} }) {

                  next if (! exists $mem->{CAPACITY});
                  next if ($mem->{CAPACITY} eq "No");
                  
                  my $new_mem = Rex::IO::Server::Model::Memory->new(
                     hardware_id => $new_hw->id,
                     size        => $mem->{CAPACITY},
                     bank        => $mem->{NUMSLOTS},
                     serialnumber => $mem->{SERIALNUMBER},
                     speed       => $mem->{SPEED},
                     type        => $mem->{TYPE},
                  );

                  $new_mem->save;

               }

               for my $cpu (@{ $json->{info}->{CONTENT}->{CPUS} }) {

                  my $new_cpu = Rex::IO::Server::Model::Processor->new(
                     hardware_id => $new_hw->id,
                     modelname   => $cpu->{TYPE},
                     vendor      => $cpu->{MANUFACTURER},
                     mhz         => $cpu->{SPEED},
                  );

                  $new_cpu->save;
               }

               return 1;
            } or do {
               warn "Error saving new system in db.\n$@\n";
            };
         }
         else {
            warn "Hardware already registered\n";
         }
      }

      elsif(exists $json->{type} && $json->{type} eq "return") {
         warn "Some thing returns...\n";
         warn Dumper($json);
      }

      else {
         warn "Got unknown message type.\n";
         warn "    $message\n";
      }

#      if(exists $json->{type} && $json->{type} eq "broadcast") {
#         for (keys %$clients) {
#            map { $_->{tx}->send($json); } @{ $clients->{$_} };
#         }
#      }

   });
}

sub clients {
   my ($self) = @_;

   if($self->param("only_ip")) {
      my @ips = keys %{ $clients };
      return $self->render_json({ok => Mojo::JSON->true, data => \@ips});
   }
   else {
      return $self->render_json($clients);
   }
}

sub is_online {
   my ($self) = @_;

   my $ip = $self->param("ip");
   if(exists $clients->{$ip}) {
      return $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      return $self->render_json({ok => Mojo::JSON->false}, status => 404);
   }
}

sub message_to_server {
   my ($self) = @_;

   my $json = $self->req->json;
   my ($to) = ($self->req->url =~ m/^.*\/(.*?)$/);

   map {
         #warn "Sending message to client...\n";
         #warn Mojo::JSON->encode($json) . "\n";
         $self->app->log->debug("Sending message to client: " . $to .  " => " . Mojo::JSON->encode($json));

         $_->{tx}->send(Mojo::JSON->encode($json))
      } @{ $clients->{$to} };

   $self->render_json({ok => Mojo::JSON->true});
}

1;
