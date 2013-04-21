#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::PerformanceCollector;

use strict;
use warnings;

use Mojo::Base -base;
use Mojo::Log;
use Mojo::JSON;
use Mojo::Redis;
use Data::Dumper;

use Rex::IO::Server::Schema;

has schema => sub {
   my ($self) = @_;

   my $dsn = "DBI:mysql:"
           . "database=". $self->config->{database}->{schema} . ";"
           . "host="    . $self->config->{database}->{host};
            
   $self->log->info("Connecting to database.");
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
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub start {
   my ($self) = @_;

   $self->log->info("Starting performance collector.");

   $self->log->info("Connecting to redis.");

   my $sub = $self->redis->subscribe($self->config->{redis}->{monitor}->{queue});
   $sub->on(message => sub {
      my ($sub, $message, $channel) = @_;
      if($channel eq $self->config->{redis}->{monitor}->{queue}) {
         $self->log->info("Got message from redis: $message");
         $self->process_message($self->json->decode($message));
      }
   });

   # at last start the loop
   $self->redis->ioloop->start;
}

sub process_message {
   my ($self, $ref) = @_;

   if(!$ref) {
      $self->log->error("Invalid json message.");
      return;
   }

   my $host = $self->db->resultset("Hardware")->search({name => $ref->{host}})->first;

   if($host) {
      my @counters = $host->get_monitor_items;
      if(my ($counter) = grep { $_->{check_key} eq $ref->{check_key} } @counters) {

         $self->log->info("found monitor for " . $ref->{check_key} . " on host " . $host->name);
         my $pcv = $self->db->resultset("PerformanceCounterValue")->create({
            performance_counter_id => $counter->{performance_counter_id},
            template_item_id       => $counter->{id},
            value                  => $ref->{value},
            created                => time,
         });
      }
      else {
         $self->log->error("NO monitor found for " . $ref->{check_key} . " on host " . $host->name);
      }
   }
   else {
      $self->log->info("Host: " . $ref->{host} . " not found.");
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
