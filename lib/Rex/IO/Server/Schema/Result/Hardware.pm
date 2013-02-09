#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Hardware;

use strict;
use warnings;

use Data::Dumper;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("hardware");
__PACKAGE__->add_columns(qw/id name state_id os_template_id os_id uuid/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("state" => "Rex::IO::Server::Schema::Result::HardwareState", "state_id");
__PACKAGE__->belongs_to("os_template" => "Rex::IO::Server::Schema::Result::OsTemplate", "os_template_id");
__PACKAGE__->belongs_to("os" => "Rex::IO::Server::Schema::Result::Os", "os_id");

__PACKAGE__->has_many("network_adapters" => "Rex::IO::Server::Schema::Result::NetworkAdapter", "hardware_id");
__PACKAGE__->has_one("bios" => "Rex::IO::Server::Schema::Result::Bios", "hardware_id");
__PACKAGE__->has_many("harddrives" => "Rex::IO::Server::Schema::Result::Harddrive", "hardware_id");
__PACKAGE__->has_many("memories" => "Rex::IO::Server::Schema::Result::Memory", "hardware_id");
__PACKAGE__->has_many("processors" => "Rex::IO::Server::Schema::Result::Processor", "hardware_id");

sub mac {
   my ($self) = @_;

#   my $hw_net_boot = Rex::IO::Server::Model::NetworkAdapter->all( (Rex::IO::Server::Model::NetworkAdapter->hardware_id == $self->id) & (Rex::IO::Server::Model::NetworkAdapter->boot == 1) )->next;
#
#   if($hw_net_boot) {
#      return $hw_net_boot->mac;
#   }
   return "undef";
}

sub to_hashRef {
   my ($self) = @_;

   my $data = { $self->get_columns };

   my $state = $self->state;
   delete $data->{state_id};

   if($state) {
      $data->{state} = $state->name;
   }
   else {
      $data->{state} = "UNKNOWN";
   }

   my $os_template = $self->os_template;
   delete $data->{os_template_id};

   if($os_template) {
      $data->{os_template} = {
         id => $os_template->id,
         name => $os_template->name,
      };
   }
   else {
      $data->{os_template} = {
         id => 0,
         name => "UNKNWON",
      };
   }

   #### network adapters
   my @nw_r = $self->network_adapters;
   my @nw_a = ();
   for my $nw (@nw_r) {
      push(@nw_a, $nw->to_hashRef);

      if($nw->boot) {
         $data->{mac} = $nw->mac;
      }
   }

   $data->{network_adapters} = \@nw_a;

   #### bios
   if(my $bios = $self->bios) {
      $data->{bios} = { $bios->get_columns };
   }

   #### harddrives
   my @hd_r = $self->harddrives;
   my @hd_a = ();

   for my $hd (@hd_r) {
      push(@hd_a, { $hd->get_columns });
   }

   $data->{harddrives} = \@hd_a;

   #### memory
   my @mem_r = $self->memories;
   my @mem_a = ();

   for my $mem (@mem_r) {
      push(@mem_a, { $mem->get_columns });
   }

   $data->{memories} = \@mem_a;

   #### processor
   my @cpu_r = $self->processors;
   my @cpu_a = ();

   for my $cpu (@cpu_r) {
      push(@cpu_a, { $cpu->get_columns });
   }

   $data->{processors} = \@cpu_a;

   #### os
   if(my $os = $self->os) {
      $data->{os} = { $os->get_columns };
   }
   delete $data->{os_id};

   return $data;
}

# delete hardware completely
sub purge {
   my ($self) = @_;

   #for my $obj (qw/network_adapter bios harddrive memory processor/) {
   #   my $devs = $self->$obj;
   #   while(my $dev = $devs->next) {
   #      $dev->delete;
   #   }
   #}

   #$self->delete;
}

1;
