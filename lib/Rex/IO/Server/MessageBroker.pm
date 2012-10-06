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

      for (keys %$clients) {
         $new_clients->{$_} = [ grep { $_->{tx_id} ne sprintf("%s", $self->tx) } @{ $clients->{$_} } ];
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

         my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->mac == \@mac_addresses );

         if(! $hw->next) {
            my ($eth_dev) = grep { $_->{IPADDRESS} eq $self->tx->remote_address } @{ $json->{info}->{CONTENT}->{NETWORKS} };

            eval {
               my $new_hw = Rex::IO::Server::Model::Hardware->new(
                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
                  mac  => $eth_dev->{MACADDR},
               );
               $new_hw->save;

               for my $eth (@{ $json->{info}->{CONTENT}->{NETWORKS} }) {

                  my $new_nw_a = Rex::IO::Server::Model::NetworkAdapter->new(
                     dev         => $eth->{DESCRIPTION},
                     hardware_id => $new_hw->id,
                     proto       => "static",
                     ip          => ! ref($eth->{IPADDRESS}) ? ip_to_int($eth->{IPADDRESS}) : 0,
                     netmask     => ! ref($eth->{IPMASK})    ? ip_to_int($eth->{IPMASK})    : 0,
                     network     => ! ref($eth->{IPSUBNET})  ? ip_to_int($eth->{IPSUBNET})  : 0,
                     gateway     => ! ref($eth->{IPGATEWAY}) ? ip_to_int($eth->{IPGATEWAY}) : 0,
                  );

                  $new_nw_a->save;

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
   $self->render_json($clients);
}

sub message_to_server {
   my ($self) = @_;

   my $json = $self->req->json;
   my ($to) = ($self->req->url =~ m/^.*\/(.*?)$/);

   map {
         #warn "Sending message to client...\n";
         #warn Mojo::JSON->encode($json) . "\n";

         $_->{tx}->send(Mojo::JSON->encode($json))
      } @{ $clients->{$to} };

   $self->render_json({ok => Mojo::JSON->true});
}

1;
