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

__PACKAGE__->table("hardware");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("state" => "Rex::IO::Server::Model::HardwareState", "state_id");
__PACKAGE__->belongs_to("os_template" => "Rex::IO::Server::Model::OsTemplate", "os_template_id");

__PACKAGE__->has_n("network_adapter" => "Rex::IO::Server::Model::NetworkAdapter", "hardware_id");


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

   my $os = $self->os_template->next;
   delete $data->{os_template_id};

   if($os) {
      $data->{os} = $os->name;
   }
   else {
      $data->{os} = "UNKNWON";
   }

   #### network adapters
   my $nw_r = $self->network_adapter;
   my @nw_a = ();

   while(my $nw = $nw_r->next) {
      push(@nw_a, $nw->get_data);
   }

   $data->{network_adapters} = \@nw_a;

   return $data;
}

1;
