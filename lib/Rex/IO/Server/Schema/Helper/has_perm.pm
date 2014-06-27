package Rex::IO::Server::Schema::Helper::has_perm;

use strict;
use warnings;
use Data::Dumper;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
@EXPORT = qw(has_perm);

sub has_perm {
  my ( $self, $perm_type, $user_o ) = @_;

  $user_o ||= $self;

  my $perm_set = $self->permission_set;

  for my $perm ( $perm_set->permissions ) {

    if ( defined $perm->user_id ) {
      next if ( $perm->user_id != $user_o->id );
      return 1
        if ( $perm->user_id == $user_o->id
        && $perm_type eq $perm->permission_type->name );
    }
    elsif ( defined $perm->group_id ) {

      next if ( $perm->group_id != $user_o->group_id );
      return 1
        if ( $perm->group_id == $user_o->group_id
        && $perm_type eq $perm->permission_type->name );
    }
  }

  return 0;
}

1;
