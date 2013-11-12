package Rex::IO::Server::Service;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;
use Data::Dumper;
use Mojo::Redis;
use Gearman::Client;

# CALL: 
# curl -X POST -d '{"task_name":"world","task_description":"Simple Hello World Task"}' http://localhost:5000/service/hello
sub register {
   my ($self) = @_;

   my $service_name = $self->param("name");
   my $json = $self->req->json;

   my $service_o = $self->db->resultset("Service")->search({ service_name => $service_name });

   my $service = $service_o->first;
   if(! $service) {
      $service = $self->db->resultset("Service")->create({
         service_name => $service_name,
      });
   }

   my $task = $self->db->resultset("ServiceTask")->create({
      service_id       => $service->id,
      task_name        => $json->{task_name},
      task_description => $json->{task_description},
   });

   $self->send_flush_cache();
   $self->render(json => {ok => Mojo::JSON->true, data => { service_id => $service->id, task_id => $task->id }});
}

sub add_task_to_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $task_id = $self->param("taskid");
   my $json = $self->req->json;

   my $host = $self->db->resultset("Hardware")->find($host_id);
   my $task = $self->db->resultset("ServiceTask")->find($task_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Can't find host."}, status => 401);
   }

   if(! $task) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Can't find task."}, status => 401);
   }

   $self->db->resultset("HardwareTask")->create({
      task_id     => $task_id,
      hardware_id => $host_id,
      task_order  => $json->{task_order},
   });

   $self->send_flush_cache();
   $self->render(json => {ok => Mojo::JSON->true});
}

sub run_task_on_host {
   my $self = shift->render_later;
   my $redis = $self->redis;

   my $host_id = $self->param("hostid");
   my $task_id = $self->param("taskid");

   my $host = $self->db->resultset("Hardware")->find($host_id);
   my $task = $self->db->resultset("ServiceTask")->find($task_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Can't find host."}, status => 401);
   }

   if(! $task) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Can't find task."}, status => 401);
   }

   my $service = $task->service;


   my $client = Gearman::Client->new;
   $client->job_servers(@{ $self->config->{gearman}->{job_servers} });
    
   my $arg = {
      service => [{ service => $service->service_name, task => $task->task_name}],
      host    => $host->name,
   };

   Mojo::IOLoop->delay(
      sub {
         my ($delay) = @_;
         my $arg_str = Mojo::JSON->encode($arg);
         $client->dispatch_background("run_job", $arg_str);
         $redis->publish($self->config->{redis}->{jobs}->{queue} => $arg_str, $delay->begin);
      },
      sub {
         $self->render(json => {ok => Mojo::JSON->true});
      }
   );
}

sub get_all {
   my ($self) = @_;

   my @services = $self->db->resultset("Service")->all;

   my @ret;

   for my $service (@services) {
      push(@ret, $service->to_hashRef);
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub get_service {
   my ($self) = @_;

   my $service_id = $self->param("id");
   my $service = $self->db->resultset("Service")->find($service_id);

   if(! $service) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   my @tasks = $service->get_tasks;

   $self->render(json => {ok => Mojo::JSON->true, data => \@tasks});
}

sub get_service_for_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Host not found."}, status => 404);
   }

   my @tasks = $host->get_tasks;

   $self->render(json => {ok => Mojo::JSON->true, data => \@tasks});
}

sub remove_all_tasks_from_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   $host->remove_tasks;

   $self->send_flush_cache();
   $self->render(json => {ok => Mojo::JSON->true});
}

sub run_tasks {
   my ($self) = @_;

   my @tasks = @{ $self->req->json };

   my @ref;

   my $client = Gearman::Client->new;
   $client->job_servers(@{ $self->config->{gearman}->{job_servers} });
    

   my $tasks_to_run = {};

   for my $task (@tasks) {
      my $task_o = $self->db->resultset("ServiceTask")->find($task->{task_id});
      my $service_o = $task_o->service;
      my $host_o = $self->db->resultset("Hardware")->find($task->{server_id});

      if(! $task_o) {
         return $self->render(json => {ok => Mojo::JSON->false}, status => 404, error => "Task not found");
      }

      if(! $host_o) {
         return $self->render(json => {ok => Mojo::JSON->false}, status => 404, error => "Host not found");
      }

      # this system is currenlty in inventory stage, so don't run the tasks now
      my @service_tasks = ();
      if($host_o->state_id != 5) {
         push @{ $tasks_to_run->{$host_o->name} }, {
            service => $service_o->service_name,
            task    => $task_o->task_name
         };
      }
   }

   my $redis = $self->redis;

   for my $host (keys %{ $tasks_to_run }) {
      my $arg = {
         service => $tasks_to_run->{$host},
         host    => $host,
      };

      my $arg_str = Mojo::JSON->encode($arg);

      $self->app->log->debug("Sending Jobs to $host: $arg_str");

      $client->dispatch_background("run_job", $arg_str);
      $redis->publish($self->config->{redis}->{jobs}->{queue} => $arg_str);
   }

   $self->render(json => {ok => Mojo::JSON->true});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/service/:name")->to("service#register");
   $r->post("/service/host/:hostid/task/:taskid")->to("service#add_task_to_host");
   $r->route("/service/host/:hostid/task/:taskid")->via("RUN")->to("service#run_task_on_host");
   $r->route("/service")->via("RUN")->to("service#run_tasks");
   $r->route("/service")->via("LIST")->to("service#get_all");
   $r->route("/service/:id")->via("LIST")->to("service#get_service");
   $r->route("/service/host/:hostid")->via("LIST")->to("service#get_service_for_host");
   $r->delete("/service/host/:hostid")->to("service#remove_all_tasks_from_host");
}

sub redis {
   my ($self) = @_;
   return Mojo::Redis->new(server => $self->config->{redis}->{jobs}->{server} . ":" . $self->config->{redis}->{jobs}->{port});
}

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
