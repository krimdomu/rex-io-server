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
use Rex::IO::Server::Calculator;
use Mojo::Redis;

our $clients = {};

sub broker {
   my ($self) = @_;

   my $client_ip = $self->tx->remote_address;
   $self->app->log->debug("messagebroker / client connected: $client_ip");

   push(@{ $clients->{$self->tx->remote_address} }, { tx => $self->tx, tx_id => sprintf("%s", $self->tx) });

   my $redis = Mojo::Redis->new(server => $self->config->{redis}->{monitor}->{server} . ":" . $self->config->{redis}->{monitor}->{port});
   $redis->timeout(0);
   my $redis_deploy = Mojo::Redis->new(server => $self->config->{redis}->{deploy}->{server} . ":" . $self->config->{redis}->{deploy}->{port});
   $redis_deploy->timeout(0);
   my $redis_jobs = Mojo::Redis->new(server => $self->config->{redis}->{jobs}->{server} . ":" . $self->config->{redis}->{jobs}->{port});
   $redis_jobs->timeout(0);

   Mojo::IOLoop->stream($self->tx->connection)->timeout(0);

   #$self->send(Mojo::JSON->encode({type => "welcome", welcome => "Welcome to the real world."}));

   # monitor redis jobs queue
   my $jobs_sub = $redis->subscribe($self->config->{redis}->{jobs}->{queue});

   $jobs_sub->on(message => sub {
      my ($sub, $message, $channel) = @_;

      if($channel eq $self->config->{redis}->{jobs}->{queue}) {
         my $ref = Mojo::JSON->decode($message);
         if($ref->{cmd} eq "Answer") {
            $self->app->log->debug("Got answer from job: " . $ref->{jq_id});
         }
      }
   });

   $self->on(finish => sub {
      $self->app->log->debug("client disconnected");
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
      # send message to server
      if(exists $json->{to_ip}) {
         map {
               #warn "Sending message to client...\n";
               #warn Mojo::JSON->encode($json) . "\n";
               $self->app->log->debug("Sending message to client: " . $json->{to_ip} .  " => " . Mojo::JSON->encode($json));
               
               if(! exists $_->{sequences}) {
                  $_->{sequences} = [];
               }

               push(@{ $_->{sequences} }, $json->{seq}) if($json->{seq});

               $_->{tx}->send(Mojo::JSON->encode($json));
         } @{ $clients->{$json->{to_ip}} };
      }

      # hello action, check if there are queued jobs for this host
      elsif(exists $json->{type} && $json->{type} eq "hello") {
         $self->app->log->debug("Got 'hello' from $client_ip, looking for queued jobs");

         my $tx = $self->_ua->get($self->config->{dhcp}->{server} . "/mac/" . $client_ip);

         my $mac;
         if(my $res = $tx->success) {
            $mac = $res->json->{mac};

            $self->app->log->debug("GOT MAC: $mac");
         }
         else {
            $self->app->log->debug("MAC not found!");
         }

         # get the host object out of db
         my $host = $self->db->resultset("Hardware")->search(
            {
               "network_adapters.mac" => $mac,
            },
            {
               join => "network_adapters",
            },
         )->first;

         if(! $host) {
            # get the host object out of db
            $host = $self->db->resultset("Hardware")->search(
               {
                  "network_adapters.ip" => ip_to_int($client_ip),
               },
               {
                  join => "network_adapters",
               },
            )->first;
         }

         if($host) {
            # found host
            my @qjs = $host->queued_jobs();

            my @ref;
            for my $qj (@qjs) {
               $self->app->log->debug("Found job: " . $qj->id);

               my $task = $qj->task;
               my $magic = $self->get_random(16, 'a' .. 'z');

               push(@ref, {
                  host   => $host->name,
                  cmd    => "Execute",
                  script => $task->service->service_name,
                  task   => $task->task_name,
                  magic  => $magic,
                  qj_id  => $qj->id,
               });

               # delete job
               $qj->delete;
            }

            $redis_jobs->publish($self->config->{redis}->{jobs}->{queue} => Mojo::JSON->encode(\@ref));
         }
      }

      elsif(exists $json->{type} && $json->{type} eq "hello-service") {

         map { $_->{info} = $json } @{ $clients->{$self->tx->remote_address} };

         my @mac_addresses = ();
         for my $eth (@{ $json->{info}->{CONTENT}->{NETWORKS} }) {
            next if($eth->{MACADDR} =~ m/^00:00:00/);

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

         # normalizing fusioninventory array
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

         # getting hostname and looking for system uuid.
         # if no uuid we're using mac addr for system idenification
         my $hostname = $json->{info}->{CONTENT}->{HARDWARE}->{NAME};

         if(exists $json->{info}->{use_mac} && $json->{info}->{use_mac}) {
            ($hostname) = grep { ! m/^00:00:00/ } @mac_addresses;
            $hostname =~ s/:/-/g;
         }

         if(ref $json->{info}->{CONTENT}->{HARDWARE}->{UUID}) {
            # no mainboard uuid
            my ($uuid_r) = grep { $_->{MACADDR} !~ m/^00:00:00/ } @{ $json->{info}->{CONTENT}->{NETWORKS} };
            $json->{info}->{CONTENT}->{HARDWARE}->{UUID} = $uuid_r->{MACADDR};
         }

         my $hw_o = $hw->first;
         if(! $hw_o) {

            eval {

#               my $new_hw = Rex::IO::Server::Model::Hardware->new(
#                  name => $json->{info}->{CONTENT}->{HARDWARE}->{NAME},
#                  uuid => $json->{info}->{CONTENT}->{HARDWARE}->{UUID} || '',
#               );
               my $new_hw = $self->db->resultset("Hardware")->create({
                  name => $hostname,
                  uuid => $json->{info}->{CONTENT}->{HARDWARE}->{UUID} || '',
                  state_id => (exists $json->{installed} && $json->{installed} ? 1 : 5),
               });

               $self->inventor($new_hw, $json->{info});

               $redis_deploy->publish($self->config->{redis}->{deploy}->{queue} => Mojo::JSON->encode({
                  cmd => "deploy",
                  type => "newsystem",
                  host => { $new_hw->get_columns },
               }));

               return 1;
            } or do {
               $self->app->log->error("Error saving new system in db.\n$@");
            };
         }
         else {
            $self->app->log->debug("Hardware already registered");

            $self->inventor($hw_o, $json->{info});

            $hw->update({
               state_id => 5,
            });
         }
      }

      # return action
      elsif(exists $json->{type} && $json->{type} eq "return") {
         $self->app->log->debug("messagebroker / Some thing returns...");
         $self->app->log->debug(Dumper($json));

         # check if we have a valid sequence
         my $sseq = $json->{seq};
         for my $client (keys %{ $clients }) {
            for my $c (@{ $clients->{$client} }) {
               next if(! exists $c->{sequences});

               my ($seq) = grep { m/\Q$sseq\E/ } @{ $c->{sequences} };
               if($seq) {
                  $self->app->log->debug("Found valid return sequence... sending data");
                  $c->{tx}->send(Mojo::JSON->encode($json));
               }
            }
         }

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

                     #my $pcv = $self->db->resultset("PerformanceCounterValue")->create($mon_data);
                     #my $failure = $pcv->template_item->failure;

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

      # log action
      elsif(exists $json->{type} && $json->{type} eq "log") {
         # get the host object out of db
         my $host = $self->db->resultset("Hardware")->search(
            {
               "network_adapters.ip" => ip_to_int($client_ip),
            },
            {
               join => "network_adapters",
            },
         )->first;

         $self->app->log_writer->write($json->{tag}, $json->{data});

         $json->{host_id} = $host->id;
         $redis->publish($self->config->{redis}->{log}->{queue} => Mojo::JSON->encode($json));
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
      return $self->render(json => {ok => Mojo::JSON->true, data => \@ips});
   }
   else {
      return $self->render(json => $clients);
   }
}

sub is_online {
   my ($self) = @_;

   my $ip = $self->param("ip");

   if(exists $clients->{$ip}) {
      return $self->render(json => {ok => Mojo::JSON->true});
   }
   else {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
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
         
         if(! exists $_->{sequences}) {
            $_->{sequences} = [];
         }

         push(@{ $_->{sequences} }, $json->{seq}) if($json->{seq});

         $_->{tx}->send(Mojo::JSON->encode($json));
      } @{ $clients->{$to} };

   $self->render(json => {ok => Mojo::JSON->true});
}

sub _ua { return Mojo::UserAgent->new; }

sub get_random {
   my $self = shift;
	my $count = shift;
	my @chars = @_;
	
	srand();
	my $ret = "";
	for(1..$count) {
		$ret .= $chars[int(rand(scalar(@chars)-1))];
	}
	
	return $ret;
}

1;
