#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Dns;
use Mojo::Base 'Mojolicious::Controller';

use Net::DNS;
use Data::Dumper;
use Mojo::JSON;

sub list {
   my ($self) = @_;

   my ($domain) = ($self->req->url =~ m/^.*\/(.*?)$/);
   my $ret = {};

   for my $rr ($self->_dns->axfr($domain)) {
      if($rr->type eq "A") {
         $ret->{ $rr->name } = {
            ip => $rr->address,
            ttl => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
         };
      }
   }

   $self->render_json($ret);
}

sub get {
   my ($self) = @_;

   my ($host, $domain) = ($self->req->url =~ m/^.*\/([^\/]+)\/(.*?)$/);

   my $query = $self->_dns->search("$host.$domain");

   my $ret = {};

   foreach my $rr ($query->answer) {
      $ret->{ $rr->name } = {
         ip => $rr->address,
         ttl => $rr->ttl,
         name => $rr->name,
         type => $rr->type,
      };
   }

   $self->render_json($ret);
}

sub add {
   my ($self) = @_;

   my ($host, $domain) = ($self->req->url =~ m/^.*\/([^\/]+)\/(.*?)$/);
   my $update = Net::DNS::Update->new($domain);

   my $json = $self->req->json;
   my $ttl = $json->{ttl} ||= "86400";
   my $ip  = $json->{ip};

   # don't add it, if there is already an A record
   $update->push(prerequisite => nxrrset("$host.$domain. A"));

   $update->push(update => rr_add("$host.$domain.  $ttl  A  $ip"));

   $update->sign_tsig($self->config->{dns}->{key_name}, $self->config->{dns}->{key});

   my $res = $self->_dns;
   my $reply = $res->send($update);

   if($reply) {
      my $rcode = $reply->header->rcode;

      if($rcode eq "NOERROR") {
         return $self->render_json({ok => Mojo::JSON->true});
      }
      else {
         return $self->render_json({ok => Mojo::JSON->false, code => $rcode});
      }
   }
   else {
      return $self->render_json(ok => Mojo::JSON->false, error => $res->errorstring);
   }
}

sub delete {
   my ($self) = @_;

   my ($host, $domain) = ($self->req->url =~ m/^.*\/([^\/]+)\/(.*?)$/);
   my $update = Net::DNS::Update->new($domain);

   $update->push(prerequisite => yxrrset("$host.$domain A"));
   $update->push(update => rr_del("$host.$domain A"));

   $update->sign_tsig($self->config->{dns}->{key_name}, $self->config->{dns}->{key});

   my $res = $self->_dns;
   my $reply = $res->send($update);

   if($reply) {
      my $rcode = $reply->header->rcode;

      if($rcode eq "NOERROR") {
         return $self->render_json({ok => Mojo::JSON->true});
      }
      else {
         return $self->render_json({ok => Mojo::JSON->false, code => $rcode});
      }
   }
   else {
      return $self->render_json(ok => Mojo::JSON->false, error => $res->errorstring);
   }

}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get('/dns/list/:domain')->to('dns#list');
   $r->get('/dns/:host/:domain')->to('dns#get');
   $r->post('/dns/:host/:domain')->to('dns#add');
   $r->delete('/dns/:host/:domain')->to('dns#delete');
}

sub _dns {
   my ($self) = @_;

   my $res = Net::DNS::Resolver->new;
   $res->nameservers($self->config->{dns}->{server});

   return $res;
}

1;
