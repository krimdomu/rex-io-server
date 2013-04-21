#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::PerformanceCounter;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("performance_counter");
__PACKAGE__->add_columns(qw/id hardware_id template_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Schema::Result::Hardware", "hardware_id");
__PACKAGE__->belongs_to("template", "Rex::IO::Server::Schema::Result::PerformanceCounterTemplate", "template_id");
__PACKAGE__->has_many("values", "Rex::IO::Server::Schema::Result::PerformanceCounterValue", "performance_counter_id");

1;
