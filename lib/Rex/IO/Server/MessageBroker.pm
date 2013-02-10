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
use Rex::IO::Server::Helper::Inventory;

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

         #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->mac == \@mac_addresses );
         my $hw = $self->db->resultset("Hardware")->search({ "network_adapters.mac" => { "-in" => \@mac_addresses } });

         if(! $hw->first) {
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

#               my $new_hw = Rex::IO::Server::Model::Hardware->new(
#                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
#                  uuid => $json->{info}->{CONTENT}->{HARDWARE}->{UUID} || '',
#               );
               my $new_hw = $self->db->resultset("Hardware")->create({
                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
                  uuid => $json->{info}->{CONTENT}->{HARDWARE}->{UUID} || '',
               });
               $new_hw->update;

               $self->inventor($new_hw, $json->{info});

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
