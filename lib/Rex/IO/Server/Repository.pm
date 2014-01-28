package Rex::IO::Server::Repository;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON "j";
use Data::Dumper;
use Rex::IO::Server::Helper::IP;

sub get_service {
   my $self = shift;

   my $hw = $self->_get_client;
   if(! ref $hw) {
      return $hw;
   }

   my $cwd = getcwd;
   my $repo_dir = $self->config->{repository}->{path} . "/" . $self->param("environment");

   chdir($repo_dir);

   my $data;
   if(open(my $fh, "tar czf - " . $self->param("service") . " |")) {
      binmode $fh;
      while(my $line = <$fh>) {
         $data .= $line;
      }
      close($fh);

      $self->render(data => $data);
   }
   else {
      $self->render(json => {ok => Mojo::JSON->false}, status => 500);
   }

   chdir($cwd);
}

sub catalog {
   my ($self) = @_;

   my $hw = $self->_get_client;
   if(ref $hw) {
      my @services = $hw->services;
      return $self->render(json => {ok => Mojo::JSON->true, data => [ map { $_ = $_->service_name } @services ]});
   }

   return $hw;
}

sub get_lib {
   my ($self) = @_;

   my $hw = $self->_get_client;
   if(! ref $hw) {
      return $hw;
   }

   my $lib_file = $self->param("lib");
   $lib_file =~ s/::/\//g;

   my $file = $self->config->{repository}->{path} . "/" . $self->param("environment") . "/lib/$lib_file.pm";

   if(! -f $file) {
      $file = $self->config->{repository}->{path} . "/" . $self->param("environment") . "/lib/$lib_file/__module__.pm";
   }

   if(-f $file) {
      my $content = eval { local(@ARGV, $/) = ($file); <>; };
      return $self->render(data => $content);
   }

   return $self->render(data => "die;", status => 404);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get("/repository/:environment/catalog")->to("repository#catalog");
   $r->get("/repository/:environment/service/:service")->to("repository#get_service");
   $r->get("/repository/:environment/lib/*lib")->to("repository#get_lib");
}

sub _get_client {
   my ($self) = @_;

   my $client = $self->tx->remote_address;

   # check if $client is ip address
   if($client =~ m/^(\d+\.\d+\.\d+\.\d+)$/) {
      $client = ip_to_int($client);
   }
   else {
      return $self->render(json => {ok => Mojo::JSON->false, error => "$client is not a valid ipv4 address"}, status => 500);
   }

   my $nwa_r = $self->db->resultset("NetworkAdapter")->search({ ip => $client });
   my $nwa   = $nwa_r->first;

   if(! $nwa) {
      return $self->render(json => {ok => Mojo::JSON->false, error => int_to_ip($client) . " not found in database"}, status => 404);
   }

   return $nwa->hardware;
}

1;
