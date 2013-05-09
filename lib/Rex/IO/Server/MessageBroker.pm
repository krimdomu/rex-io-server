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

   my $client_ip = $self->tx->remote_address;
   $self->app->log->debug("messagebroker / client connected: $client_ip");

   push(@{ $clients->{$self->tx->remote_address} }, { tx => $self->tx, tx_id => sprintf("%s", $self->tx) });

   my $redis = Mojo::Redis->new(server => $self->config->{redis}->{monitor}->{server} . ":" . $self->config->{redis}->{monitor}->{port});

   Mojo::IOLoop->stream($self->tx->connection)->timeout(300);

   #$self->send(Mojo::JSON->encode({type => "welcome", welcome => "Welcome to the real world."}));

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

      # @todo needs to split out into modules
      # hello action
      if(exists $json->{type} && $json->{type} eq "hello") {

         map { $_->{info} = $json } @{ $clients->{$self->tx->remote_address} };

         my @mac_addresses = ();
         for my $eth (@{ $json->{info}->{CONTENT}->{NETWORKS} }) {
            push(@mac_addresses, $eth->{MACADDR});
         }

         #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->mac == \@mac_addresses );
         my $hw = $self->db->resultset("Hardware")->search(
            {
               "network_adapters.mac" => { "-in" => \@mac_addresses }
            },
            {
               join => "network_adapters",
            }
         );

         if(! $hw->first) {

            eval {

               # convert to array if not array
               if(ref($json->{info}->{CONTENT}->{STORAGES}) ne "ARRAY") {
                  $json->{info}->{CONTENT}->{STORAGES} = [ $json->{info}->{CONTENT}->{STORAGES} ];
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

               $self->inventor($new_hw, $json->{info});

               return 1;
            } or do {
               $self->app->log->error("Error saving new system in db.\n$@");
            };
         }
         else {
            $self->app->log->debug("Hardware already registered");
         }
      }

      # return action
      elsif(exists $json->{type} && $json->{type} eq "return") {
         $self->app->log->debug("messagebroker / Some thing returns...");
         $self->app->log->debug(Dumper($json));
      }

      # monitor action
      elsif(exists $json->{type} && $json->{type} eq "monitor") {
         $self->app->log->debug("Got monitor event from: $client_ip");

         # get the host object out of db
         my $host = $self->db->resultset("Hardware")->search(
            {
               "network_adapters.ip" => ip_to_int($client_ip),
            },
            {
               join => "network_adapters",
            },
         )->first;

         my $data = $json->{data};

         # convert every input into a multi type
         for my $data_itm (@{ $data }) {
            if($data_itm->{type} eq "single") {
               $data_itm = {
                  type => "multi",
                  values => {
                     $data_itm->{name} => $data_itm->{value},
                  },
               };
            }
         }

         if($host) {
            my @counters = $host->get_monitor_items;

            for my $mon_itm (@{ $data }) { # iterate over all monitoring items

               for my $itm_name (keys %{ $mon_itm->{values} }) { # iterate over all values inside a monitoring item

                  if(my ($counter) = grep { $_->{check_key} eq $itm_name } @counters) {

                     $self->app->log->info("found monitor for " . $itm_name . " on host " . $host->name);

                     my $mon_data = {
                        performance_counter_id => $counter->{performance_counter_id},
                        template_item_id       => $counter->{id},
                        value                  => $mon_itm->{values}->{$itm_name},
                        created                => time,
                     };

                     my $pcv = $self->db->resultset("PerformanceCounterValue")->create($mon_data);

                     my $redis_data = $mon_data;
                     $redis_data->{check_key}   = $counter->{check_key};
                     $redis_data->{host}        = $host->id;
                     $redis_data->{check_name}  = $counter->{name};
                     $redis_data->{divisor}     = $counter->{divisor};
                     $redis_data->{relative}    = $counter->{relative};
                     $redis_data->{calculation} = $counter->{calculation};

                     $redis->publish($self->config->{redis}->{monitor}->{queue} => Mojo::JSON->encode($redis_data));
                  }
                  else {
                     $self->app->log->error("NO monitor found for " . $itm_name . " on host " . $host->name);
                  }

               } # /end iterate over all values

            } # /end iterate over all monitoring items
         }
         else {
            $self->app->log->info("Host: " . $client_ip . " not found.");
         }

      }

      # ping action
      elsif(exists $json->{type} && $json->{type} eq "ping") {
         $self->app->log->debug("Got ping event from: $client_ip");
         $self->send(Mojo::JSON->encode({type => "ping_answer", ping_answer => "Welcome to the real world."}));
      }

      # unknown action/type
      else {
         $self->app->log->error("Got unknown message type.\n   $message");
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
