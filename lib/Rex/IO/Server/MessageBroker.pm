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

         my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->ip eq $self->tx->remote_address );

         if(! $hw->next) {
            my ($eth_dev) = grep { $_->{IPADDRESS} eq $self->tx->remote_address } @{ $json->{info}->{CONTENT}->{NETWORKS} };

            eval {
               my $new_hw = Rex::IO::Server::Model::Hardware->new(
                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
                  ip   => $self->tx->remote_address,
                  mac  => $eth_dev->{MACADDR},
               );

               $new_hw->save;
            } or do {
               warn "Error saving new system in db.\n$@\n";
            };
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
