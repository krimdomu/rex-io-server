package Rex::IO::Server::Monitor;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;
use Data::Dumper;
use Mojo::Redis;

sub template_new {
   my ($self) = @_;

   my $ref = $self->req->json;

   if(! $ref->{name}) {
      return $self->render_json({ok => Mojo::JSON->false, error => "name missing"}, status => 500);
   }

   my $template = $self->db->resultset("PerformanceCounterTemplate")->create($ref);

   $self->render_json({ok => Mojo::JSON->true, template_id => $template->id});
}

sub item_new {
   my ($self) = @_;

   my $template_id = $self->param("templateid");
   my $template = $self->db->resultset("PerformanceCounterTemplate")->find($template_id);

   if(! $template) {
      return $self->render_json({ok => Mojo::JSON->false, error => "Template not found"}, status => 404);
   }

   my $ref = $self->req->json;

   if(! $ref->{name}) {
      return $self->render_json({ok => Mojo::JSON->false, error => "name missing"}, status => 500);
   }

   if(! $ref->{check_key}) {
      return $self->render_json({ok => Mojo::JSON->false, error => "key missing"}, status => 500);
   }

   $ref->{template_id} = $template_id;
   my $item = $self->db->resultset("PerformanceCounterTemplateItem")->create($ref);

   $self->render_json({ok => Mojo::JSON->true, item_id => $item->id});
}

sub add_template_to_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $template_id = $self->param("templateid");

   my $template = $self->db->resultset("PerformanceCounterTemplate")->find($template_id);

   if(! $template) {
      return $self->render_json({ok => Mojo::JSON->false, error => "Template not found"}, status => 404);
   }

   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render_json({ok => Mojo::JSON->false, error => "Host not found"}, status => 404);
   }

   my $pc = $self->db->resultset("PerformanceCounter")->create({
      hardware_id => $host_id,
      template_id => $template_id,
   });

   $self->render_json({ok => Mojo::JSON->true, performance_counter_id => $pc->id});
}

sub get_items_of_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");

   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render_json({ok => Mojo::JSON->false, error => "Host not found"}, status => 404);
   }

   $self->render_json({ok => Mojo::JSON->true, data => [ $host->get_monitor_items ]});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/monitor/template")->to("monitor#template_new");
   $r->post("/monitor/template/:templateid/item")->to("monitor#item_new");
   $r->post("/monitor/template/:templateid/host/:hostid")->to("monitor#add_template_to_host");

   $r->route("/monitor/host/:hostid/item")->via("LIST")->to("monitor#get_items_of_host");
}



1;
