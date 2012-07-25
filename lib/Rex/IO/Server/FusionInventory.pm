#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::FusionInventory;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use XML::Simple;
use Compress::Zlib;

use Data::Dumper;

sub post {
   my ($self) = @_;

   my $data = uncompress($self->req->body);
   my $ref = XMLin($data);

   if($ref->{QUERY} eq "PROLOG") {
      $self->render_data(
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

      $ref->{CONTENT} = _normalize_hash($ref->{CONTENT});

      my $data = $self->cmdb->add_section_to_server($server, "inventory", $ref->{CONTENT});
      $self->chi->remove($server);
      $self->chi->remove("server_list");

      if(! ref($data) ) {
         $self->render_data(
            compress(
               '<?xml version="1.0" encoding="UTF-8"?><REPLY>ACCOUNT_NOT_UPDATED</REPLY>'
            ),
            status => 500
         );
      }
      else {
         $self->render_data(
            compress(
               '<?xml version="1.0" encoding="UTF-8"?><REPLY>ACCOUNT_UPDATE</REPLY>'
            )
         );
      }
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

   $r->post("/fusioninventory")->to("fusion_inventory#post");
}

1;
