package Rex::IO::Server::Repository;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;

sub update {
  my $self = shift;

   my $cwd = getcwd;
   my $repo_dir = $self->stash("config")->{checkout_path};

   if(! -d $repo_dir) {
      system("git clone " . $self->stash("config")->{git} . " $repo_dir"); 
      chdir($repo_dir);
   }
   else {
      chdir($repo_dir);
      system("git fetch origin");
   }

   system("git checkout " . $self->stash("config")->{branch});
   system("git pull origin " . $self->stash("config")->{branch});

   chdir($cwd);

   $self->render_json({ok => ($? == 0?Mojo::JSON->true:Mojo::JSON->false)}, status => ($? == 0?200:500));
}

sub get_service {
   my $self = shift;

   my $cwd = getcwd;
   my $repo_dir = $self->stash("config")->{checkout_path};

   chdir($repo_dir);

   my $data;
   if(open(my $fh, "tar czf - " . $self->stash("service") . " |")) {
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

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;


   $r->route("/repository/update")->via("UPDATE")->over(authenticated => 1)->to("repository#update");
   $r->get("/repository/:service")->over(authenticated => 1)->to("repository#get_service");
}

1;
