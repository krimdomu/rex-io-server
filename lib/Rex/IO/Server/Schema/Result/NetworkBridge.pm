#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Schema::Result::NetworkBridge;

use strict;
use warnings;

use base qw(DBIx::Class::Core);
use Rex::IO::Server::Helper::IP;

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("network_bridge");
__PACKAGE__->add_columns(qw/id hardware_id name spanning_tree wait_port forwarding_delay ip network broadcast netmask gateway boot proto/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Schema::Result::Hardware", "hardware_id");
__PACKAGE__->has_many("network_adapters", "Rex::IO::Server::Schema::Result::NetworkAdapter", "network_bridge_id");

sub to_hashRef {
  my ($self) = @_;

  my @devices = ();
  for my $na ($self->network_adapters) {
    push @devices, $na->dev;
  }

  my $ip      = int_to_ip $self->ip;
  my $netmask   = int_to_ip $self->netmask;
  my $broadcast  = int_to_ip $self->broadcast;
  my $network   = int_to_ip $self->network;
  my $gateway   = int_to_ip $self->gateway;

  if($ip      eq "0.0.0.0")  { $ip      = ""; }
  if($netmask  eq "0.0.0.0")  { $netmask  = ""; }
  if($network  eq "0.0.0.0")  { $network  = ""; }
  if($broadcast eq "0.0.0.0")  { $broadcast = ""; }
  if($gateway  eq "0.0.0.0")  { $gateway  = ""; }

  my $ret = {
    id           => $self->id,
    hardware_id     => $self->hardware_id,
    name          => $self->name,
    spanning_tree    => $self->spanning_tree,
    wait_port      => $self->wait_port,
    forwarding_delay  => $self->forwarding_delay,
    ip           => $ip      || "",
    network        => $network   || "",
    netmask        => $netmask   || "",
    broadcast      => $broadcast  || "",
    gateway        => $gateway   || "",
    boot          => $self->boot,
    proto         => $self->proto,
    devices        => [ @devices ],
  };

  return $ret;
}

1;
