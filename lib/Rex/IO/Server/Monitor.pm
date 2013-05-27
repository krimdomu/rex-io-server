package Rex::IO::Server::Monitor;
use Mojo::Base 'Mojolicious::Controller';

use Cwd qw(getcwd);
use Mojo::JSON;
use Data::Dumper;
use Mojo::Redis;
use POSIX;

sub template_new {
   my ($self) = @_;

   my $ref = $self->req->json;

   if(! $ref->{name}) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "name missing"}, status => 500);
   }

   my $template = $self->db->resultset("PerformanceCounterTemplate")->create($ref);

   $self->render(json => {ok => Mojo::JSON->true, template_id => $template->id});
}

sub item_new {
   my ($self) = @_;

   my $template_id = $self->param("templateid");
   my $template = $self->db->resultset("PerformanceCounterTemplate")->find($template_id);

   if(! $template) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Template not found"}, status => 404);
   }

   my $ref = $self->req->json;

   if(! $ref->{name}) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "name missing"}, status => 500);
   }

   if(! $ref->{check_key}) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "key missing"}, status => 500);
   }

   $ref->{template_id} = $template_id;
   my $item = $self->db->resultset("PerformanceCounterTemplateItem")->create($ref);

   $self->render(json => {ok => Mojo::JSON->true, item_id => $item->id});
}

sub add_template_to_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");
   my $template_id = $self->param("templateid");

   my $template = $self->db->resultset("PerformanceCounterTemplate")->find($template_id);

   if(! $template) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Template not found"}, status => 404);
   }

   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Host not found"}, status => 404);
   }

   my $pc = $self->db->resultset("PerformanceCounter")->create({
      hardware_id => $host_id,
      template_id => $template_id,
   });

   $self->render(json => {ok => Mojo::JSON->true, performance_counter_id => $pc->id});
}

sub get_items_of_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");

   my $host = $self->db->resultset("Hardware")->find($host_id);

   if(! $host) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Host not found"}, status => 404);
   }

   $self->render(json => {ok => Mojo::JSON->true, data => [ $host->get_monitor_items ]});
}

sub get_alerts {
   my ($self) = @_;

   my @alerts = $self->db->resultset("CurrentAlert")->search({});

   my @ret;

   for my $alert (@alerts) {
      push @ret, {
         created => $alert->created,
         time    => strftime("%Y-%m-%d %H:%M:%S", localtime($alert->created)),
         host    => $alert->hardware->name,
         name    => $alert->template_item->name,
         template_item_id => $alert->template_item_id,
         hardware_id      => $alert->hardware_id,
      };
   }

   $self->render(json => \@ret);
}

sub get_alerts_of_host {
   my ($self) = @_;

   my $host_id = $self->param("hostid");

   my @alerts = $self->db->resultset("CurrentAlert")->search(
      {
         hardware_id => $host_id,
      }
   );

   my @ret;
   for my $alert (@alerts) {
      push @ret, {
         created => $alert->created,
         time    => strftime("%Y-%m-%d %H:%M:%S", localtime($alert->created)),
         host    => $alert->hardware->name,
         name    => $alert->template_item->name,
         template_item_id => $alert->template_item_id,
         hardware_id      => $alert->hardware_id,
      };
   }

   $self->render(json => \@ret);
}

sub list_templates {
   my ($self) = @_;

   my @ret;

   my @tpl = $self->db->resultset("PerformanceCounterTemplate")->all;
   for my $t (@tpl) {
      push @ret, { $t->get_columns };
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub delete_template {
   my ($self)  = @_;

   my $id = $self->param("id");
   my $t = $self->db->resultset("PerformanceCounterTemplate")->find($id);
   if($t) {
      $t->delete;
      return $self->render(json => {ok => Mojo::JSON->true});
   }

   $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}

sub list_items_of_template {
   my ($self) = @_;

   my $t_id = $self->param("id");

   my $t = $self->db->resultset("PerformanceCounterTemplate")->find($t_id);

   if(! $t) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   my @ret;

   for my $m ($t->items) {
      push @ret, { $m->get_columns };
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub del_item {
   my ($self) = @_;

   my $item_id = $self->param("itemid");
   my $i = $self->db->resultset("PerformanceCounterTemplateItem")->find($item_id);

   if(! $i) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   $i->delete;

   $self->render(json => {ok => Mojo::JSON->true});
}

sub get_template {
   my ($self) = @_;
   my $t_id = $self->param("id");
   my $t = $self->db->resultset("PerformanceCounterTemplate")->find($t_id);

   if(! $t) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   my $data = { $t->get_columns };
   $self->render(json => {ok => Mojo::JSON->true, data => $data});
}

sub get_item {
   my ($self) = @_;

   my $item_id = $self->param("item_id");
   my $itm = $self->db->resultset("PerformanceCounterTemplateItem")->find($item_id);

   if(! $itm) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   $self->render(json => {ok => Mojo::JSON->true, data => { $itm->get_columns }});
}

sub save_item {
   my ($self) = @_;

   my $item_id = $self->param("item_id");
   my $itm = $self->db->resultset("PerformanceCounterTemplateItem")->find($item_id);

   if(! $itm) {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }

   $itm->update($self->req->json);

   $self->render(json => {ok => Mojo::JSON->true});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/monitor/template")->to("monitor#template_new");
   $r->post("/monitor/template/:templateid/item")->to("monitor#item_new");
   $r->post("/monitor/template/:templateid/host/:hostid")->to("monitor#add_template_to_host");

   $r->route("/monitor/host/:hostid/item")->via("LIST")->to("monitor#get_items_of_host");
   $r->route("/monitor/alerts")->via("LIST")->to("monitor#get_alerts");
   $r->route("/monitor/alerts/:hostid")->via("LIST")->to("monitor#get_alerts_of_host");

   $r->route("/monitor/template")->via("LIST")->to("monitor#list_templates");
   $r->delete("/monitor/template/:id")->to("monitor#delete_template");

   $r->route("/monitor/template/:id")->via("LIST")->to("monitor#list_items_of_template");
   $r->delete("/monitor/template/:templateid/item/:itemid")->to("monitor#del_item");

   $r->get("/monitor/template/:id")->to("monitor#get_template");
   $r->get("/monitor/template/:id/item/:item_id")->to("monitor#get_item");
   $r->post("/monitor/template/:id/item/:item_id")->to("monitor#save_item");
}



1;
