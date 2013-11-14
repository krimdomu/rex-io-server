#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::NetworkAdapter;

use strict;
use warnings;

use base qw(DBIx::Class::Core);
use Rex::IO::Server::Helper::IP;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("network_adapter");
__PACKAGE__->add_columns(qw/id
                            hardware_id
                            dev
                            proto
                            ip
                            netmask
                            broadcast
                            network
                            gateway
                            wanted_ip
                            wanted_netmask
                            wanted_broadcast
                            wanted_network
                            wanted_gateway
                            mac
                            boot
                            virtual
                            network_bridge_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Schema::Result::Hardware", "hardware_id");
__PACKAGE__->belongs_to("bridge", "Rex::IO::Server::Schema::Result::NetworkBridge", "network_bridge_id");

sub to_hashRef {
   my ($self) = @_;

   my $data = { $self->get_columns };

   my $ip         = int_to_ip $self->ip;
   my $netmask    = int_to_ip $self->netmask;
   my $broadcast  = int_to_ip $self->broadcast;
   my $network    = int_to_ip $self->network;
   my $gateway    = int_to_ip $self->gateway;

   if($ip        eq "0.0.0.0")   { $ip        = ""; }
   if($netmask   eq "0.0.0.0")   { $netmask   = ""; }
   if($network   eq "0.0.0.0")   { $network   = ""; }
   if($broadcast eq "0.0.0.0")   { $broadcast = ""; }
   if($gateway   eq "0.0.0.0")   { $gateway   = ""; }

   my $wanted_ip         = int_to_ip $self->wanted_ip;
   my $wanted_netmask    = int_to_ip $self->wanted_netmask;
   my $wanted_broadcast  = int_to_ip $self->wanted_broadcast;
   my $wanted_network    = int_to_ip $self->wanted_network;
   my $wanted_gateway    = int_to_ip $self->wanted_gateway;

   if($wanted_ip        eq "0.0.0.0")   { $wanted_ip        = ""; }
   if($wanted_netmask   eq "0.0.0.0")   { $wanted_netmask   = ""; }
   if($wanted_network   eq "0.0.0.0")   { $wanted_network   = ""; }
   if($wanted_broadcast eq "0.0.0.0")   { $wanted_broadcast = ""; }
   if($wanted_gateway   eq "0.0.0.0")   { $wanted_gateway   = ""; }

   $data->{ip}        = $ip         || "";
   $data->{netmask}   = $netmask    || "";
   $data->{broadcast} = $broadcast  || "";
   $data->{network}   = $network    || "";
   $data->{gateway}   = $gateway    || "";

   $data->{wanted_ip}        = $wanted_ip          || "";
   $data->{wanted_netmask}   = $wanted_netmask     || "";
   $data->{wanted_broadcast} = $wanted_broadcast   || "";
   $data->{wanted_network}   = $wanted_network     || "";
   $data->{wanted_gateway}   = $wanted_gateway     || "";

   my $bridge = $self->bridge;
   if($bridge) {
      $data->{bridge} = $self->bridge->to_hashRef();
   }

   return $data;

}

1;
