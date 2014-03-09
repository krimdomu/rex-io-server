#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Dns;
use Mojo::Base 'Mojolicious::Controller';

use Net::DNS;
use Data::Dumper;
use Mojo::JSON "j";

sub list_domain {
  my ($self) = @_;

  my $domain = $self->param("domain");
  my @ret;

  for my $rr ($self->_dns->axfr($domain)) {
    if($rr->type eq "A") {
      push @ret, {
        data => $rr->address,
        ttl => $rr->ttl,
        type => $rr->type,
        name => $rr->name,
      };
    }
    elsif($rr->type eq "TXT") {
      push @ret, {
        data => $rr->rdata,
        ttl => $rr->ttl,
        type => $rr->type,
        name => $rr->name,
      };
    }
    elsif($rr->type eq "CNAME") {
      push @ret, {
        data => $rr->cname,
        ttl => $rr->ttl,
        type => $rr->type,
        name => $rr->name,
      };
    }
    elsif($rr->type eq "MX") {
      push @ret, {
        data => $rr->exchange,
        ttl => $rr->ttl,
        type => $rr->type,
        name => $rr->name,
      };
    }
    elsif($rr->type eq "PTR") {
      push @ret, {
        data => $rr->ptrdname,
        ttl => $rr->ttl,
        type => $rr->type,
        name => $rr->name,
      };
    }
    else {
      print STDERR Dumper($rr);
    }
  }

  $self->render(json => \@ret);
}

sub list_tlds {
  my ($self) = @_;

  my @ret = ();

  for my $tld (@{ $self->config->{dns}->{tlds} }) {
    if(ref $tld eq "HASH") {
      push @ret, $tld;
    }
    else {
      push @ret, {
        zone => $tld,
        name => $tld,
      };
    }
  }

  $self->render(json => \@ret);
}

sub get {
  my ($self) = @_;

  my $domain = $self->param("domain");
  my $host  = $self->param("host");

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

  $self->render(json => $ret);
}

# CALL:
# curl -X POST -d '{"data":"1.2.3.4","type":"A"}' http://localhost:5000/dns/stage.rexify.org/fe01
# curl -X POST -d '{"data":"fe01","type":"PTR"}' http://localhost:5000/dns/4.3.2.IN-ADDR.ARPA/1
sub add_record {
  my ($self) = @_;

  my $domain = $self->param("domain");
  my $host  = $self->param("host");

  my $update = Net::DNS::Update->new($domain);

  my $json = $self->req->json;
  my $ttl  = $json->{ttl} ||= "86400";
  my $data = $json->{data};

  my $record_type = "A";

  if(exists $json->{type}) {
    $record_type = $json->{type};
  }

  #if(! $self->_is_ip($ip)) {
  #  return $self->render(json => {ok => Mojo::JSON->false, error => "Not a valid IPv4 given."}, status => 500);
  #}

  #if(! $self->_is_hostname($host)) {
  #  return $self->render(json => {ok => Mojo::JSON->false, error => "Not a valid HOSTNAME given."}, status => 500);
  #}

  # don't add it, if there is already an A record
  $update->push(prerequisite => nxrrset("$host.$domain. $record_type"));

  if($record_type eq "TXT") {
    $data =~ s/\\/\\\\/gms;
    $data =~ s/"/\\"/gms;
    $data = "\"$data\"";
  }

  $update->push(update => rr_add("$host.$domain. $ttl $record_type $data"));

  $update->sign_tsig($self->config->{dns}->{key_name}, $self->config->{dns}->{key});

  my $res = $self->_dns;
  my $reply = $res->send($update);

  if($reply) {
    my $rcode = $reply->header->rcode;

    if($rcode eq "NOERROR") {
      return $self->render(json => {ok => Mojo::JSON->true});
    }
    else {
      return $self->render(json => {ok => Mojo::JSON->false, code => $rcode});
    }
  }
  else {
    return $self->render(json => ok => Mojo::JSON->false, error => $res->errorstring);
  }
}

sub delete_record {
  my ($self) = @_;

  my $domain = $self->param("domain");
  my $host  = $self->param("host");
  my $type  = $self->param("type");

  #if(! $self->_is_hostname($host)) {
  #  return $self->render(json => {ok => Mojo::JSON->false, error => "Not a valid HOSTNAME given."}, status => 500);
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
      return $self->render(json => {ok => Mojo::JSON->true});
    }
    else {
      return $self->render(json => {ok => Mojo::JSON->false, code => $rcode});
    }
  }
  else {
    return $self->render(json => ok => Mojo::JSON->false, error => $res->errorstring);
  }

}

sub __register__ {
  my ($self, $app) = @_;
  my $r = $app->routes;

  $r->post('/dns/#domain/#host')->over(authenticated => 1)->to('dns#add_record');
  $r->delete('/dns/#domain/:type/#host')->over(authenticated => 1)->to('dns#delete_record');

  $r->get('/dns/#domain/#host')->over(authenticated => 1)->to('dns#get');

  $r->route('/dns/#domain')->via("LIST")->over(authenticated => 1)->to('dns#list_domain');
  $r->route('/dns')->via("LIST")->over(authenticated => 1)->to('dns#list_tlds');
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
