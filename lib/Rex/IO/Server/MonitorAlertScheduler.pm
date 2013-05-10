#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::MonitorAlertScheduler;

use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use Mojo::IOLoop;
use Mojo::Log;
use Mojo::JSON;
use Mojo::Redis;
use Data::Dumper;

use Rex::IO::Server::Schema;
use Rex::IO::Server::Calculator;

has schema => sub {
   my ($self) = @_;

   my $dsn = "DBI:mysql:"
           . "database=". $self->config->{database}->{schema} . ";"
           . "host="    . $self->config->{database}->{host};
            
   return Rex::IO::Server::Schema->connect($dsn, 
      $self->config->{database}->{username},
      $self->config->{database}->{password});
};

has db => sub {
   my ($self) = @_;
   $self->schema;
}; 

has log => sub {
   my ($self) = @_;

   if(! exists $self->{"log"}) {
      if($self->config->{log}->{file} eq "-") {
         $self->{"log"} = Mojo::Log->new(level => $self->config->{log}->{level});
      }
      else {
         $self->{"log"} = Mojo::Log->new(path => $self->config->{log}->{file}, level => $self->config->{log}->{level});
      }
   }

   return $self->{"log"};
}; 

has json => sub {
   my ($self) = @_;
   if(! exists $self->{json}) {
      $self->{json} = Mojo::JSON->new;
   }

   return $self->{json};
};

has redis => sub {
   my ($self) = @_;
   if(! exists $self->{redis}) {
      $self->{redis} = Mojo::Redis->new(server => $self->config->{redis}->{monitor}->{server} . ":" . $self->config->{redis}->{monitor}->{port});
   }

   return $self->{redis};
};

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = $proto->SUPER::new(@_);

   bless($self, $proto);

   return $self;
}

sub start {
   my ($self) = @_;

   $self->log->info("Starting alert scheduler collector.");

   $self->log->info("Connecting to redis.");

   my $sub = $self->redis->subscribe($self->config->{redis}->{monitor}->{queue});
   $sub->on(message => sub {
      my ($sub, $message, $channel) = @_;
      if($channel eq $self->config->{redis}->{monitor}->{queue}) {
         $self->process_message($self->json->decode($message));
      }
   });

   $self->prepare_cache;

   # at last start the loop
   $self->redis->ioloop->start; 
}

sub prepare_cache {
   my ($self) = @_;

   # get all failure and cache needed values
   $self->log->debug("Scanning templates and getting failure calculation...");
   my @perf_t = $self->db->resultset("PerformanceCounterTemplateItem")->all;

   my (%used_keys, @keys);

   for my $perf (@perf_t) {
      push(@keys, $perf->check_key);
   }

   for my $perf (@perf_t) {
      my $failure = $perf->failure;

      if($failure) {
         my @lines = split(/\r?\n/, $failure);
         for my $line (@lines) {
            my ($act, $params) = split(/:\s?/, $line, 2);
            my ($key, $count) = split(/,\s?/, $params);

            if($key ~~ @keys) {
               if(! $used_keys{$key}) {
                  $used_keys{$key} = $count;
               }
               elsif($used_keys{$key} < $count) {
                  $used_keys{$key} = $count;
               }
            }
         }
      }
   }

   # get all items and cache in redis
   for my $key (keys %used_keys) {
      my $titm = $self->db->resultset("PerformanceCounterTemplateItem")->search({ check_key => $key })->next;
      my @pcs = $titm->template->performance_counters;

      for my $pc (@pcs) {
         my $pc_id = $pc->id;
         my $hardware_id = $pc->hardware->id;
         my $cache_key = $self->_get_cache_item($hardware_id, $titm->id, $pc_id);

         my @items_to_cache = $self->db->resultset("PerformanceCounterValue")->search(
            {
               hardware_id => $hardware_id,
               template_item_id => $titm->id,
               performance_counter_id => $pc_id,
            },
            {
               order_by => { -desc => 'created' },
               rows     => $used_keys{$key},
            },
         );

         my @cache_data;
         for my $item_to_cache (@items_to_cache) {
            push(@cache_data, { $item_to_cache->get_columns });
         }

         $self->log->debug("Caching value in key: $cache_key");
         $self->redis->set($cache_key => $self->json->encode(\@cache_data));
      }
   }


}

# hardware_id, template_item_id, performance_counter_id
sub _get_cache_item {
   my ($self, $hardware_id, $template_item_id, $pc_id) = @_;
   return "monitor:cache:hw-" . $hardware_id . ":titm-" . $template_item_id . ":pc-" . $pc_id;
}

sub process_message {
   my ($self, $msg) = @_;

   my $mon_data = {
      performance_counter_id => $msg->{performance_counter_id},
      template_item_id       => $msg->{template_item_id},
      value                  => $msg->{value},
      created                => $msg->{created},
      hardware_id            => $msg->{host},
   };

   my $pcv = $self->db->resultset("PerformanceCounterValue")->create($mon_data);
   my $failure = $pcv->template_item->failure;

   if($failure) {
      # there is a failure definition,
      # so cache it

      my $cache_key = $self->_get_cache_item($msg->{host}, $msg->{template_item_id}, $msg->{performance_counter_id});
      $self->redis->get($cache_key, sub {
         my ($redis, $res) = @_;
         my $ref = $self->json->decode($res);
         shift @{ $ref };
         push @{ $ref }, { $pcv->get_columns };

         $self->redis->set($cache_key => $self->json->encode($ref));
         $self->log->debug("Updatet cache for $cache_key containing " . scalar(@{ $ref }) . " items");

         # and check it
         $self->log->debug("Checking if we need to trigger a failure...");

         my $data_hash = {
            $pcv->template_item->check_key => [ map { $_ = $_->{value} } sort { $a->{created} <=> $b->{created} } @{ $ref }],
         };

         my $need_alert = Rex::IO::Server::Calculator->parse($failure, $data_hash);

         my $alert_key = $cache_key . ":alert";
         $self->redis->get($alert_key, sub {
            my ($redis, $res) = @_;
            if(defined $res && $need_alert) {
               $self->log->debug("Already alerted. Not alerting again.");
            }
            else {
               if($need_alert) {
                  $self->log->debug("Sending alert...");
                  $self->redis->set($alert_key => 1);
               }
               else {
                  # remove alert key
                  if(defined $res) {
                     $self->log->debug("All good again, removing alert key...");
                     $self->redis->del($alert_key);
                  }
                  else {
                     $self->log->debug("All good, doing nothing...");
                  }
               }
            }
         });

      });

      
   }

}

sub config {
   my ($self) = @_;

   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }

   my $config = {};

   if($cfg && -f $cfg) {
      my $content = eval { local(@ARGV, $/) = ($cfg); <>; };
      $config  = eval 'package Rex::IO::Config::Loader;'
                           . "no warnings; $content";

      die "Couldn't load configuration file: $@" if(!$config && $@);
      die "Config file invalid. Did not return HASH reference." if( ref($config) ne "HASH" );

      return $config;
   }
   else {
      print "Can't find configuration file.\n";
      exit 1;
   }

}

1;
