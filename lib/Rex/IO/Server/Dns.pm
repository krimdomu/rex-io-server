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

sub list_domain {
   my ($self) = @_;

   my $domain = $self->param("domain");
   my $ret = {};

   for my $rr ($self->_dns->axfr($domain)) {
      if($rr->type eq "A") {
         $ret->{ $rr->name } = {
            data => $rr->address,
            ttl => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
         };
      }
      elsif($rr->type eq "TXT") {
         $ret->{ $rr->name } = {
            data => $rr->rdata,
            ttl => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
         };
      }
      elsif($rr->type eq "CNAME") {
         $ret->{ $rr->name } = {
            data => $rr->cname,
            ttl => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
         };
      }
      elsif($rr->type eq "MX") {
         $ret->{ $rr->name } = {
            data => $rr->exchange,
            ttl => $rr->ttl,
            type => $rr->type,
            name => $rr->name,
         };
      }
      else {
         print STDERR Dumper($rr);
      }
   }

   $self->render_json($ret);
}

sub list_tlds {
   my ($self) = @_;
   $self->render_json($self->config->{dns}->{tlds});
}

sub get {
   my ($self) = @_;

   my $domain = $self->param("domain");
   my $host   = $self->param("host");

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

sub add_record {
   my ($self) = @_;

   my $domain = $self->param("domain");
   my $host   = $self->param("host");

   my $update = Net::DNS::Update->new($domain);

   my $json = $self->req->json;
   my $ttl  = $json->{ttl} ||= "86400";
   my $data = $json->{data};

   my $record_type = "A";

   if(exists $json->{type}) {
      $record_type = $json->{type};
   }

   #if(! $self->_is_ip($ip)) {
   #   return $self->render_json({ok => Mojo::JSON->false, error => "Not a valid IPv4 given."}, status => 500);
   #}

   #if(! $self->_is_hostname($host)) {
   #   return $self->render_json({ok => Mojo::JSON->false, error => "Not a valid HOSTNAME given."}, status => 500);
   #}

   # don't add it, if there is already an A record
   $update->push(prerequisite => nxrrset("$host.$domain. $record_type"));

   $update->push(update => rr_add("$host.$domain.  $ttl  $record_type  $data"));

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

sub delete_record {
   my ($self) = @_;

   my $domain = $self->param("domain");
   my $host   = $self->param("host");
   my $type   = $self->param("type");

   #if(! $self->_is_hostname($host)) {
   #   return $self->render_json({ok => Mojo::JSON->false, error => "Not a valid HOSTNAME given."}, status => 500);
   #}

   warn "Got $domain / $type / $host";

   my $update = Net::DNS::Update->new($domain);

   $update->push(prerequisite => yxrrset("$host.$domain $type"));
   $update->push(update => rr_del("$host.$domain $type"));

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

   $r->post('/dns/#domain/#host')->to('dns#add_record');
   $r->delete('/dns/#domain/:type/#host')->to('dns#delete_record');

   $r->get('/dns/#domain/#host')->to('dns#get');

   $r->route('/dns/#domain')->via("LIST")->to('dns#list_domain');
   $r->route('/dns')->via("LIST")->to('dns#list_tlds');
}

sub _dns {
   my ($self) = @_;

   my $res = Net::DNS::Resolver->new;
   $res->nameservers($self->config->{dns}->{server});

   return $res;
}

sub _is_ip {
   my ($self, $ip) = @_;

   if($ip =~ m/^((25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})\.){3}(25[0-5]|2[0-4]\d|1\d{2}|\d{1,2})$/) {
      return 1;
   }
}

sub _is_hostname {
   my ($self, $hostname) = @_;

   if($hostname =~ m/^([a-zA-Z0-9\-]*[a-zA-Z0-9])$/) {
      return 1;
   }
}

1;
