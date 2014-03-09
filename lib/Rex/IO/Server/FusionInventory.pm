#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::FusionInventory;
  
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";
use XML::Simple;
use Compress::Zlib;

use Data::Dumper;
use Rex::IO::Server::Helper::IP;
use Rex::IO::Server::Helper::Inventory;

sub post {
  my ($self) = @_;

  my $data = uncompress($self->req->body);
  my $ref = XMLin($data);

  if($ref->{QUERY} eq "PROLOG") {
    $self->render(data => 
      compress(
        '<?xml version="1.0" encoding="UTF-8"?><REPLY><PROLOG_FREQ>60</PROLOG_FREQ><RESPONSE>SEND</RESPONSE></REPLY>'
      )
    );
  }
  elsif($ref->{QUERY} eq "INVENTORY") {
    my $server = $ref->{CONTENT}->{HARDWARE}->{NAME};

    # delete the processlist
    delete $ref->{CONTENT}->{PROCESSES};
    # delete the envs
    delete $ref->{CONTENT}->{ENVS};
    # delete the softwares
    delete $ref->{CONTENT}->{SOFTWARES};

#    $ref->{CONTENT} = _normalize_hash($ref->{CONTENT});

    # convert to array if not array
    if(ref($ref->{CONTENT}->{STORAGES}) ne "ARRAY") {
      $ref->{CONTENT}->{STORAGE} = [ $ref->{CONTENT}->{STORAGES} ];
    }
    if(ref($ref->{CONTENT}->{NETWORKS}) ne "ARRAY") {
      $ref->{CONTENT}->{NETWORKS} = [ $ref->{CONTENT}->{NETWORKS} ];
    }
    if(ref($ref->{CONTENT}->{MEMORIES}) ne "ARRAY") {
      $ref->{CONTENT}->{MEMORIES} = [ $ref->{CONTENT}->{MEMORIES} ];
    }
    if(ref($ref->{CONTENT}->{CPUS}) ne "ARRAY") {
      $ref->{CONTENT}->{CPUS} = [ $ref->{CONTENT}->{CPUS} ];
    }

    #my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->uuid eq $ref->{CONTENT}->{HARDWARE}->{UUID} );
    my $hw_r = $self->db->resultset("Hardware")->search({ uuid => $ref->{CONTENT}->{HARDWARE}->{UUID} });
    my $hw = $hw_r->first;
    if($hw) {
      # hardware found 
      $self->app->log->debug("Found hardware's uuid");
    }
    else {
      for my $net ( @{ $ref->{CONTENT}->{NETWORKS} } ) {
        next unless $net->{IPADDRESS};
        next unless $net->{VIRTUALDEV} == 0;

        #$hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::NetworkAdapter->ip eq ip_to_int($net->{IPADDRESS} || 0) );
        $hw_r = $self->db->resultset("Hardware")->search({
            "network_adapters.ip" => ip_to_int($net->{IPADDRESS} || 0),
          },
          {
            join => "network_adapters",
          });
        $hw = $hw_r->first;
        if($hw) {
          $self->app->log->debug("Found hardware through ip address");
          last;
        }
      }
    }

    unless($hw) {
      $self->app->log->debug("nothing found!");

      #$hw = Rex::IO::Server::Model::Hardware->new(
      #  name => $ref->{CONTENT}->{HARDWARE}->{NAME},
      #  uuid => $ref->{CONTENT}->{HARDWARE}->{UUID} || '',
      #);
      $hw = $self->db->resultset("Hardware")->create({
        name => $ref->{CONTENT}->{HARDWARE}->{NAME},
        uuid => $ref->{CONTENT}->{HARDWARE}->{UUID} || '',
      });

      #$hw->update;
    }

    return eval {

      # inventor the hardware
      $self->inventor($hw, $ref);

      $self->app->log->debug("returning account_update");

      return $self->render( data =>
        compress(
          '<?xml version="1.0" encoding="UTF-8"?><REPLY>><RESPONSE>ACCOUNT_UPDATE</RESPONSE></REPLY>'
        )
      );
    } or do {

      $self->app->log->debug("Inventory failed: $@");

      return $self->render( data => 
        compress(
          '<?xml version="1.0" encoding="UTF-8"?><REPLY>ACCOUNT_NOT_UPDATED</REPLY>'
        ),
        status => 500
      );
    };

  }
}

sub _normalize_hash {
  my ($h) = @_;

  for my $key (keys %{$h}) {
    if(ref($h->{$key}) eq "ARRAY") {
      $h->{$key} = _normalize_array($h->{$key});
    }
    elsif(ref($h->{$key}) eq "HASH") {
      my @tmp = %{ $h->{$key} };
      if(scalar(@tmp) == 0) {
        $h->{$key} = "";
      }
      else {
        $h->{$key} = _normalize_hash($h->{$key});
      }
    }
    else {
      $h->{$key} = _normalize_scalar($h->{$key});
    }
  }

  return $h;
}

sub _normalize_scalar {
  my ($s) = @_;

  if($s) {
    return $s;
  }

  return "";
}

sub _normalize_array {
  my ($a) = @_;

  for (@{$a}) {
    if(ref($_) eq "ARRAY") {
      $_ = _normalize_array($_);
    }
    elsif(ref($_) eq "HASH") {
      $_ = _normalize_hash($_);
    }
    else {
      $_ = _normalize_scalar($_);
    }
  }

  return $a;
}

sub __register__ {
  my ($self, $app) = @_;
  my $r = $app->routes;

  # updating inventory, don't need authentication
  $r->post("/fusioninventory")->to("fusion_inventory#post");
}

1;
