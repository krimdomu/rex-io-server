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
            '<?xml version="1.0" encoding="UTF-8"?><XML><PROLOG_FREQ>60</PROLOG_FREQ><RESPONSE>SEND</RESPONSE></XML>'
         )
      );
   }
   elsif($ref->{QUERY} eq "INVENTORY") {
      my $server = $ref->{CONTENT}->{HARDWARE}->{NAME};

      # delete the processlist
      delete $ref->{CONTENT}->{PROCESSES};
      # delete the envs
      delete $ref->{CONTENT}->{ENVS};

      my $data = $self->cmdb->add_section_to_server($server, "inventory", $ref->{CONTENT});

      if(! ref($data) ) {
         $self->render_data(
            compress(
               '<?xml version="1.0" encoding="UTF-8"?><XML><RESPONSE>ACCOUNT_NOT_UPDATED</RESPONSE></XML>'
            ),
            status => 500
         );
      }
      else {
         $self->render_data(
            compress(
               '<?xml version="1.0" encoding="UTF-8"?><XML><RESPONSE>ACCOUNT_UPDATE</RESPONSE></XML>'
            )
         );
      }
   }
}


1;
