#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Auth::User;

use strict;
use warnings;

use Digest::Bcrypt;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

sub id       { shift->{data}->{id} }
sub name     { shift->{data}->{name} }
sub password { shift->{data}->{password} }

sub load {
  my ( $self, $find_type, $data ) = @_;

  my $user;
  if ( $find_type eq "by_id" ) {
    $user = $self->app->db->resultset("User")->find($data);
  }
  elsif ( $find_type eq "by_name" ) {
    $user =
      $self->app->db->resultset("User")->search( { name => $data } )->first;
  }
  else {
    die("Wrong find_type: supported type: by_id and by_name.");
  }

  if ($user) {
    $self->{data} = { $user->get_columns };
  }

  return $self;
}

sub app { shift->{app} }

sub check_password {
  my ( $self, $given_pw ) = @_;

  my $b = Digest::Bcrypt->new;
  $b->cost( $self->app->config->{auth}->{cost} );
  $b->salt( $self->app->config->{auth}->{salt} );

  $b->add($given_pw);

  my $given_pw_cr = $b->hexdigest;

  if ( $given_pw_cr eq $self->password ) {
    return $self;
  }
}

sub has_perm {
  my ( $self, $perm_type ) = @_;

  my $user_db = $self->app->db->resultset("User")->find( $self->id );
  $self->app->log->debug("Checking for user permission: $perm_type");
  my $has_perm = $user_db->has_perm($perm_type);

  if ($has_perm) {
    $self->app->log->debug("User has permission for: $perm_type");
  }
  else {
    $self->app->log->debug("User has no permission for: $perm_type");
  }

  return $has_perm;
}

sub get_permissions {
  my ($self) = @_;
  my $user_db = $self->app->db->resultset("User")->find( $self->id );
  return $user_db->get_permissions;
}

1;
