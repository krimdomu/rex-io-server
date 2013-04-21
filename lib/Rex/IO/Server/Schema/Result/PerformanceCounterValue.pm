#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::PerformanceCounterValue;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("performance_counter_value");
__PACKAGE__->add_columns(qw/id performance_counter_id template_item_id value created/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("performance_counter", "Rex::IO::Server::Schema::Result::PerformanceCounter", "performance_counter_id");

1;
