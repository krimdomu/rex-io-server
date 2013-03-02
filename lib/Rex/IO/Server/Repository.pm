package Rex::IO::Server::Repository;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;

sub get_service {
   my $self = shift;

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

      $self->render_data($data);
   }
   else {
      $self->render_json({ok => Mojo::JSON->false}, status => 500);
   }

   chdir($cwd);
}

sub catalog {
   my ($self) = @_;

   my $hw_name = "foobar";
   my $hw_r = $self->db->resultset("Hardware")->search({ name => $hw_name });
   if(my $hw = $hw_r->first) {
      my @services = $hw->services;
      return $self->render_json({ok => Mojo::JSON->true, data => [ map { $_ = $_->service_name } @services ]});
   }

   return $self->render_json({ok => Mojo::JSON->false}, status => 404);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get("/repository/:environment/catalog")->to("repository#catalog");
   $r->get("/repository/:environment/service/:service")->to("repository#get_service");
}

1;
