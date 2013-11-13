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

sub to_hashRef {
   my ($self) = @_;

   my $data = { $self->get_columns };

   $data->{ip}        = int_to_ip($data->{ip})          if $data->{ip};
   $data->{netmask}   = int_to_ip($data->{netmask})     if $data->{netmask};
   $data->{broadcast} = int_to_ip($data->{broadcast})   if $data->{broadcast};
   $data->{network}   = int_to_ip($data->{network})     if $data->{network};
   $data->{gateway}   = int_to_ip($data->{gateway})     if $data->{gateway};

   $data->{wanted_ip}        = int_to_ip($data->{wanted_ip})          if $data->{wanted_ip};
   $data->{wanted_netmask}   = int_to_ip($data->{wanted_netmask})     if $data->{wanted_netmask};
   $data->{wanted_broadcast} = int_to_ip($data->{wanted_broadcast})   if $data->{wanted_broadcast};
   $data->{wanted_network}   = int_to_ip($data->{wanted_network})     if $data->{wanted_network};
   $data->{wanted_gateway}   = int_to_ip($data->{wanted_gateway})     if $data->{wanted_gateway};



   return $data;

}

1;
