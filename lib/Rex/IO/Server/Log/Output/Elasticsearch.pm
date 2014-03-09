#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Log::Output::Elasticsearch;

use strict;
use warnings;
use POSIX 'strftime';
use Data::Dumper;
use Mojo::UserAgent;

use Rex::IO::Server::Log::Output::Base;
use base qw(Rex::IO::Server::Log::Output::Base);

sub new {
  my $that = shift;
  my $proto = ref($that) || $that;
  my $self = $proto->SUPER::new(@_);

  bless($self, $proto);

  $self->{ua} = Mojo::UserAgent->new;

  return $self;
}

sub write {
  my ($self, $tag, $data) = @_;

  my $target_index = "logstash-" . strftime("%Y.%m.%d", localtime($data->{time}));

  # always use the same timezone on your hosts
  $data->{'@timestamp'} = strftime("%Y-%m-%dT%H:%M:%S%z", localtime($data->{time}));
  $data->{tag} = $tag;

  my $index_type = $self->app->config->{logstream}->{output}->{index_type};
  
  my $message = [
    Mojo::JSON->encode({
      index => { "_index" => $target_index, "_type" => $index_type },
    }),
    
    Mojo::JSON->encode($data),
  ];

  my $server = $self->app->config->{logstream}->{output}->{host};
  my $port  = $self->app->config->{logstream}->{output}->{port};

  $self->app->log->debug("Sending log data to elasticsearch:");

  $self->ua->post("http://$server:$port/_bulk", {}, join("\n", @{ $message }) . "\n", sub {
  });

}

sub search {
  my ($self, %opt) = @_;

  my $index_type = $self->app->config->{logstream}->{output}->{index_type};

  my $query = {
    query => {
      bool => {
        must => [
          {
            query_string => {
              default_field => "logs.host",
              query => $opt{host},
            },
          },
        ],
      },
    },
    from => $opt{from} || 0,
    size => $opt{size} || 50,
    sort => $opt{sort} || [],
  };

  my $target_index = "logstash-" . strftime("%Y.%m.%d", localtime(time));
  my $server = $self->app->config->{logstream}->{output}->{host};
  my $port  = $self->app->config->{logstream}->{output}->{port};

  print STDERR Dumper($query);

  my $tx = $self->ua->post("http://$server:$port/$target_index/_search", {}, json => $query);
  if (my $res = $tx->success) {
    return $res->json;
  }
  
  return {};
}

sub ua { (shift)->{ua} }

1;
