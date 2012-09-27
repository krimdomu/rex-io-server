#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Deploy;
use Mojo::Base 'Mojolicious::Controller';

use Rex::IO::Server::Helper::DHCP::ISC;

sub wait {
   my ($self) = @_;
}

sub boot {
   my ($self) = @_;

   my $client = $self->tx->remote_address;

   my $dhcp = Rex::IO::Server::Helper::DHCP::ISC->new;

   my $mac = $dhcp->get_mac_from_ip($client);

   my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->mac eq $mac );

   if(my $system = $hw->next) {
      # system known, do the registered boot
      warn "HW is known, returning ubuntu\n";

      my $boot_os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == 2 );
      my $boot_os = $boot_os_r->next;

      if($system->state_id == 1) {

         my $append = $boot_os->append;
         my $hostname = $boot_os->name;
         my $eth = "eth0";

         $append =~ s/\%hostname/$hostname/g;
         $append =~ s/\%eth/$eth/g;

         my $boot_commands = "#!ipxe\n"
                           . "kernel " . $boot_os->kernel . " " . $boot_os->append .  "\n"
                           . "initrd " . $boot_os->initrd . "\n"
                           . "boot";

         $system->state_id = 2;
         $system->update;

         return $self->render_text($boot_commands);
      }
      elsif($system->state_id == 2) {

         $system->state_id = 3;
         $system->update;

         return $self->render_text($boot_os->template);
      }
      else {
         warn "boot from local hard disk...\n";

      }
   }
   else {
      # system unknown, boot service os
      my $boot_commands = "#!ipxe\n\n";
      $boot_commands .= "kernel http://192.168.7.1/linux ramdisk_size=200000 apm=power-off dist=rex_io_bmd image_url=http://192.168.7.1/rex_io_bmd.img REXIO_BOOTSTRAP_FILE=http://192.168.7.1/debian6.yml REXIO_SERVER=ws://192.168.1.4:3000/messagebroker\n";
      $boot_commands .= "initrd http://192.168.7.1/minirt.gz\n";
      $boot_commands .= "boot";

      return $self->render_text($boot_commands);
   }

}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get("/deploy/wait/:name")->to("deploy#wait");
   $r->get("/deploy/boot")->to("deploy#boot");

   $r->post("/deploy/os/:name")->to("deploy-os#register");
   $r->delete("/deploy/os/:name")->to("deploy-os#delete");
   $r->route("/deploy/os")->via("LIST")->to("deploy-os#list");
}

1;
