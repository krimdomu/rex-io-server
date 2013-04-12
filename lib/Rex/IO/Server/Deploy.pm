#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Deploy;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;
use Rex::IO::Server::Helper::IP;
use Data::Dumper;

sub wait {
   my ($self) = @_;
}

sub boot {
   my ($self) = @_;

   my $client = $self->tx->remote_address;

   my $tx = $self->_ua->get($self->config->{dhcp}->{server} . "/mac/" . $client);

   my $mac;
   if(my $res = $tx->success) {
      $mac = $res->json->{mac};

      warn "GOT MAC: $mac\n";
   }

   #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->mac eq $mac );
   my $hw = $self->db->resultset("Hardware")->search({ mac => $mac })->first;

   if($self->param("custom")) {
      $client = $self->param("custom");
      #$hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->ip == ip_to_int($client) );
      $hw = $self->db->resultset("Hardware")->search({
            "network_adapters.ip" => ip_to_int($client),
         })->first;
   }

   if(my $system = $hw) {
      # system known, do the registered boot
      warn "HW is known, returning registered os template\n";

      my $boot_os_r = $system->os_template;
      if(my $boot_os = $boot_os_r) {

         if($system->state_id == 1 || $self->param("deploy")) { # first boot after service os / after registration
                                      # return os template to deploy os

            if($boot_os->id == 1) {
               warn "Booting local... Setting system->state_id = 4";
               $system->update({
                  state_id => 4
               });
               return $self->render_text($boot_os->ipxe);
            }

            if($boot_os->ipxe) {
               # if there are ipxe commands, use them
               warn "Booting ipxe commands... Setting system->state_id = 4";
               $system->update({
                  state_id => 4
               });
               return $self->render_text($boot_os->ipxe);
            }

            my $append = $boot_os->append;
            my $hostname = $boot_os->name;
            #my $boot_eth = Rex::IO::Server::Model::NetworkAdapter->all( Rex::IO::Server::Model::NetworkAdapter->mac eq $mac )->next;
            my $boot_eth = $self->db->resultset("NetworkAdapter")->search({ mac => $mac })->first;
            my $eth = $boot_eth->dev;

            $append =~ s/\%hostname/$hostname/g;
            $append =~ s/\%eth/$eth/g;

            my $boot_commands = "#!ipxe\n"
                              . "kernel " . $boot_os->kernel . " " . $boot_os->append .  "\n"
                              . "initrd " . $boot_os->initrd . "\n"
                              . "boot";

            $system->update({
               state_id => 2
            });

            return $self->render_text($boot_commands);
         }
         elsif($system->state_id == 2 || $self->param("kickstart")) { # request of kickstart/preseed/... file

         warn "rerturning kickstart template\n";

            $system->update({
               state_id => 3
            });

            $self->stash("hardware", $system);

            my $template = $boot_os->template;
            return $self->render(inline => $template);
         }
         elsif($system->state_id == 3 || $self->param("finished")) { # hook after installation, must be called from within the template

            $system->update({
               state_id => 4,
               os_template_id => 1,
            });

            return $self->render_json({ok => Mojo::JSON->true});
         }
         else { # default boot, if state == INSTALLED (state_id: 4)
            warn "boot from local hard disk...\n";

            #my $boot_os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == 1 );
            my $boot_os_r = $self->db->resultset("OsTemplate")->find(1);
            my $boot_os = $boot_os_r;

            return $self->render_text($boot_os->ipxe);
         }
      }
      else { # no boot method found, use localboot for safety
         warn "No Boot method found...\n";
         warn "Returning localboot...\n";

         #my $boot_os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == 1 );
         my $boot_os_r = $self->db->resultset("OsTemplate")->find(1);
         my $boot_os = $boot_os_r;
         return $self->render_text($boot_os->ipxe);
      }
   }
   else { # system unknown, boot service os
      #my $boot_os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == 2 );
      my $boot_os_r = $self->db->resultset("OsTemplate")->find(2);
      my $boot_os = $boot_os_r;

      my $boot_commands = "#!ipxe\n\n";
      $boot_commands .= "kernel " . $boot_os->kernel . " " . $boot_os->append . "\n";
      $boot_commands .= "initrd " . $boot_os->initrd . "\n";
      $boot_commands .= "boot";

      return $self->render_text($boot_commands);
   }

}

sub deploy {
   my ($self) = @_;
   
   #my $system_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name eq $self->stash("server") );
   my $system_r = $self->db->resultset("Hardware")->search({ name => $self->stash("server") });
   if(my $system = $system_r->first) {
      #my $os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->name eq $self->stash("os") );
      my $os_r = $self->db->resultset("OsTemplate")->search({ name => $self->stash("os") });
      if(my $os = $os_r->first) {
         $system->update({
            os_template_id => $os->id,
            state_id => 1,
         });

         return $self->render_json({ok => Mojo::JSON->true});
      }

      else {
         return $self->render_json({ok => Mojo::JSON->false, error => "OS not found"}, status => 404);
      }
   }

   $self->render_json({ok => Mojo::JSON->false, error => "Host not found"}, status => 404);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get("/deploy/wait/:name")->to("deploy#wait");
   $r->get("/deploy/boot")->to("deploy#boot");

   # write new boot info, needs auth
   $r->post("/deploy/:server/:os")->over(authenticated => 1)->to("deploy#deploy");

   $r->put("/deploy/os/:id")->over(authenticated => 1)->to("deploy-os#update");
   $r->post("/deploy/os/:name")->over(authenticated => 1)->to("deploy-os#register");
   $r->delete("/deploy/os/:name")->over(authenticated => 1)->to("deploy-os#delete");
   $r->route("/deploy/os")->via("LIST")->over(authenticated => 1)->to("deploy-os#list");
}

sub _ua { return Mojo::UserAgent->new; }

1;
