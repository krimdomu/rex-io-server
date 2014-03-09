#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Schema::Result::PerformanceCounterTemplateItem;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("performance_counter_template_item");
__PACKAGE__->add_columns(qw/id template_id name check_key unit divisor relative calculation failure/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("template", "Rex::IO::Server::Schema::Result::PerformanceCounterTemplate", "template_id");
__PACKAGE__->has_many("performance_counter_values", "Rex::IO::Server::Schema::Result::PerformanceCounterValue", "template_item_id");
__PACKAGE__->has_many("alerts", "Rex::IO::Server::Schema::Result::CurrentAlert", "template_item_id");

sub to_hashRef {
  my ($self) = @_;
  return { $self->get_columns };
}

1;
