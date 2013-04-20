package Rex::IO::Server::Service;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;
use Data::Dumper;
use Mojo::Redis;

sub register {
   my ($self) = @_;

   my $service_name = $self->param("name");
   my $json = $self->req->json;

   my $service = $self->db->resultset("Service")->create({
      service_name => $service_name,
      task_name    => $json->{task_name},
      task_description => $json->{task_description},
   });

   $self->render_json({ok => Mojo::JSON->true});
}

sub add_task_to_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $task_id = $self->param("taskid");

   $self->db->resultset("HardwareService")->create({
      service_id => $task_id,
      hardware_id => $host_id,
   });

   $self->render_json({ok => Mojo::JSON->true});
}

sub run_task_on_host {
   my $self = shift->render_later;
   my $redis = Mojo::Redis->new(server => $self->config->{redis}->{server} . ":" . $self->config->{redis}->{port});

   my $host_id = $self->param("hostid");
   my $task_id = $self->param("taskid");

   my $host = $self->db->resultset("Hardware")->find($host_id);
   my $task = $self->db->resultset("Service")->find($task_id);

   Mojo::IOLoop->delay(
      sub {
         my ($delay) = @_;
         my $ref = {
            host   => $host->name,
            cmd    => "Execute",
            script => $task->service_name,
            task   => $task->task_name,
         };
         my $json = Mojo::JSON->new;
         $redis->publish($self->config->{redis}->{queue} => $json->encode($ref), $delay->begin);
      },
      sub {
         $self->render_json({ok => Mojo::JSON->true});
      }
   );
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/service/:name")->to("service#register");
   $r->post("/service/host/:hostid/:taskid")->to("service#add_task_to_host");
   $r->route("/service/host/:hostid/:taskid")->via("RUN")->to("service#run_task_on_host");
}

1;
