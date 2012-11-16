#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Hardware;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(name => "String");
__PACKAGE__->attr(mac => "String");
__PACKAGE__->attr(state_id => "Integer");
__PACKAGE__->attr(os_template_id => "Integer");
__PACKAGE__->attr(os_id => "Integer");

__PACKAGE__->table("hardware");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("state" => "Rex::IO::Server::Model::HardwareState", "state_id");
__PACKAGE__->belongs_to("os_template" => "Rex::IO::Server::Model::OsTemplate", "os_template_id");
__PACKAGE__->belongs_to("os" => "Rex::IO::Server::Model::Os", "os_id");

__PACKAGE__->has_n("network_adapter" => "Rex::IO::Server::Model::NetworkAdapter", "hardware_id");
__PACKAGE__->has("bios" => "Rex::IO::Server::Model::Bios", "hardware_id");
__PACKAGE__->has_n("harddrive" => "Rex::IO::Server::Model::Harddrive", "hardware_id");
__PACKAGE__->has_n("memory" => "Rex::IO::Server::Model::Memory", "hardware_id");
__PACKAGE__->has_n("processor" => "Rex::IO::Server::Model::Processor", "hardware_id");


sub to_hashRef {
   my ($self) = @_;

   my $data = $self->get_data;

   my $state = $self->state->next;
   delete $data->{state_id};

   if($state) {
      $data->{state} = $state->name;
   }
   else {
      $data->{state} = "UNKNOWN";
   }

   my $os_template = $self->os_template->next;
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
   my $nw_r = $self->network_adapter;
   my @nw_a = ();

   while(my $nw = $nw_r->next) {
      push(@nw_a, $nw->get_data);
   }

   $data->{network_adapters} = \@nw_a;

   #### bios
   if(my $bios = $self->bios->next) {
      $data->{bios} = $bios->get_data;
   }

   #### harddrives
   my $hd_r = $self->harddrive;
   my @hd_a = ();

   while(my $hd = $hd_r->next) {
      push(@hd_a, $hd->get_data);
   }

   $data->{harddrives} = \@hd_a;

   #### memory
   my $mem_r = $self->memory;
   my @mem_a = ();

   while(my $mem = $mem_r->next) {
      push(@mem_a, $mem->get_data);
   }

   $data->{memories} = \@mem_a;

   #### processor
   my $cpu_r = $self->processor;
   my @cpu_a = ();

   while(my $cpu = $cpu_r->next) {
      push(@cpu_a, $cpu->get_data);
   }

   $data->{processors} = \@cpu_a;

   #### os
   if(my $os = $self->os->next) {
      $data->{os} = $os->get_data;
   }
   delete $data->{os_id};

   return $data;
}

1;
