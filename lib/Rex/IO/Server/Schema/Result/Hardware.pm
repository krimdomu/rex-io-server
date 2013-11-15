#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Hardware;

use strict;
use warnings;

use Data::Dumper;

use Rex::IO::Server::Helper::IP;

use base qw(DBIx::Class::Core);

my $hooks = {};

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("hardware");
__PACKAGE__->add_columns(qw/id name state_id os_template_id os_id uuid server_group_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("state" => "Rex::IO::Server::Schema::Result::HardwareState", "state_id");
__PACKAGE__->belongs_to("os_template" => "Rex::IO::Server::Schema::Result::OsTemplate", "os_template_id");
__PACKAGE__->belongs_to("os" => "Rex::IO::Server::Schema::Result::Os", "os_id");
__PACKAGE__->belongs_to("server_group" => "Rex::IO::Server::Schema::Result::ServerGroup", "server_group_id");

__PACKAGE__->has_many("network_adapters" => "Rex::IO::Server::Schema::Result::NetworkAdapter", "hardware_id");
__PACKAGE__->has_many("network_bridges" => "Rex::IO::Server::Schema::Result::NetworkBridge", "hardware_id");
__PACKAGE__->has_one("bios" => "Rex::IO::Server::Schema::Result::Bios", "hardware_id");
__PACKAGE__->has_many("harddrives" => "Rex::IO::Server::Schema::Result::Harddrive", "hardware_id");
__PACKAGE__->has_many("memories" => "Rex::IO::Server::Schema::Result::Memory", "hardware_id");
__PACKAGE__->has_many("processors" => "Rex::IO::Server::Schema::Result::Processor", "hardware_id");
__PACKAGE__->has_many("tasks" => "Rex::IO::Server::Schema::Result::HardwareTask", "hardware_id");
__PACKAGE__->has_many("performance_counters" => "Rex::IO::Server::Schema::Result::PerformanceCounter", "hardware_id");
__PACKAGE__->has_many("performance_counter_values" => "Rex::IO::Server::Schema::Result::PerformanceCounterValue", "hardware_id");
__PACKAGE__->has_many("alerts", "Rex::IO::Server::Schema::Result::CurrentAlert", "hardware_id");

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

   # execute the hooks
   for my $key (keys %{ $hooks->{to_hashRef} }) {
      my $got_data = $hooks->{to_hashRef}->{$key}->($self);

      if($got_data) {
         $data->{$key} = $got_data;
      }
   }

   return $data;
}

# delete hardware completely
sub purge {
   my ($self) = @_;
   $self->delete;
}

sub get_tasks {
   my ($self) = @_;

   my @ret;

   for my $hw_task ($self->tasks) {
      my $task = $hw_task->task;
      next if(! $task);
      my $task_ref = $task->to_hashRef;
      $task_ref->{task_order} = $hw_task->task_order;
      push(@ret, $task_ref);
   }

   return @ret;
}

sub remove_tasks {
   my ($self) = @_;

   for my $hw_task ($self->tasks) {
      $hw_task->delete;
   }
}

sub get_monitor_items {
   my ($self) = @_;

   my @ret = ();

   for my $pc ($self->performance_counters) {
      my $template = $pc->template;
      for my $template_item ($template->items) {
         my $ref = $template_item->to_hashRef;
         $ref->{performance_counter_id} = $pc->id;
         push(@ret, $ref);
      }
   }

   return @ret;
}

sub primary_device {
   my ($self) = @_;

   my @nw_r = $self->network_adapters;
   my $nw_a = $nw_r[0]->dev;
   for my $nw (@nw_r) {
      if($nw->boot) {
         $nw_a = $nw->dev;
         last;
      }
   }

   return $nw_a;
}

sub primary_ip {
   my ($self) = @_;

   my @nw_r = $self->network_adapters;
   my $nw_a = int_to_ip($nw_r[0]->ip);
   for my $nw (@nw_r) {
      if($nw->boot) {
         $nw_a = int_to_ip($nw->ip);
         last;
      }
   }

   return $nw_a;
}

sub wanted_primary_netmask {
   my ($self) = @_;

   my @nw_r = $self->network_adapters;
   my $nw_a = int_to_ip($nw_r[0]->wanted_netmask);
   for my $nw (@nw_r) {
      if($nw->wanted_netmask) {
         $nw_a = int_to_ip($nw->wanted_netmask);
         last;
      }
   }

   return $nw_a;
}

sub primary_netmask {
   my ($self) = @_;

   my @nw_r = $self->network_adapters;
   my $nw_a = int_to_ip($nw_r[0]->netmask);
   for my $nw (@nw_r) {
      if($nw->netmask) {
         $nw_a = int_to_ip($nw->netmask);
         last;
      }
   }

   return $nw_a;
}

sub wanted_default_gateway {
   my ($self) = @_;

   my $dg_a;
   my @nw_r = $self->network_adapters;
   if($nw_r[0] && $nw_r[0]->wanted_gateway) {
      $dg_a = int_to_ip($nw_r[0]->wanted_gateway);
   }
   for my $nw (@nw_r) {
      if($nw->boot) {
         if($nw->wanted_gateway) {
            $dg_a = int_to_ip($nw->wanted_gateway);
            last;
         }
      }
   }

   return $dg_a;
}

sub default_gateway {
   my ($self) = @_;

   my $dg_a;
   my @nw_r = $self->network_adapters;
   if($nw_r[0] && $nw_r[0]->gateway) {
      $dg_a = int_to_ip($nw_r[0]->gateway);
   }
   for my $nw (@nw_r) {
      if($nw->boot) {
         if($nw->gateway) {
            $dg_a = int_to_ip($nw->gateway);
            last;
         }
      }
   }

   return $dg_a;
}

sub short_name {
   my ($self) = @_;

   my $name = $self->name;
   my ($short_name) = split(/\./, $name);
   return $short_name;
}

sub domain_name {
   my ($self) = @_;

   my $name = $self->name;
   my ($short_name, $domain_name) = split(/\./, $name, 2);

   return $domain_name;
}


sub add_hook {
   my ($class, $hook, $key, $code) = @_;
   $hooks->{$hook}->{$key} = $code;
}

1;
