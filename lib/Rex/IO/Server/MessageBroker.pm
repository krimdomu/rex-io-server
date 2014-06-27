#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::MessageBroker;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;
use Mojo::JSON "j";
use Mojo::UserAgent;
use Rex::IO::Server::Helper::IP;
use Mojo::Redis;
use Gearman::Client;
use JSON::XS;

our $clients = {};

sub broker {
  my ($self) = @_;

  my $client_ip = $self->tx->remote_address;
  $self->app->log->debug("messagebroker / client connected: $client_ip");

  push
    @{ $clients->{ $self->tx->remote_address } },
    { tx => $self->tx, tx_id => sprintf( "%s", $self->tx ) };

  $self->on(
    finish => sub {
      $self->app->log->debug("client disconnected: $client_ip");
      my $new_clients = {};

      # remove client from client list
      for my $cl ( keys %$clients ) {
        for my $cl_conn ( @{ $clients->{$cl} } ) {
          if ( $cl_conn->{tx_id} ne sprintf( "%s", $self->tx ) ) {
            push @{ $new_clients->{$cl} }, $cl_conn;
          }
        }
      }

      $clients = $new_clients;
    }
  );

  $self->on(
    message => sub {
      my ( $tx, $message ) = @_;
      $self->app->log->debug("messagebroker: got message: $message");

      my $json = decode_json $message;
      if ( exists $json->{type} ) {
        my $klass = $json->{type};
        eval "use $klass";
        if ($@) {
          my $e = $@;
          $self->app->log->error(
            "Error loading messagebroker class: $klass.\n\nERROR: $e\n\n");
          $self->send(
            Mojo::JSON->encode(
              {
                type  => "error",
                error => "Unknown message. No message type given."
              }
            )
          );
        }
        else {
          my $c = $klass->new( ctrl => $self, app => $self->app );
          $c->messagebroker_process($json);
        }
      }
      else {
        $self->app->log->error(
          "messagebroker: unknown message! no message type given.");

        $self->send(
          Mojo::JSON->encode(
            {
              type  => "error",
              error => "Unknown message. No message type given."
            }
          )
        );
      }
    }
  );
}

sub clients {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('MB_GET_ONLINE_CLIENTS') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission MB_GET_ONLINE_CLIENTS.',
        data  => [],
      },
      status => 403
    );
  }

  my @ips = keys %{$clients};
  $self->render( json => { ok => Mojo::JSON->true, data => \@ips } );
}

sub is_online {
  my ($self) = @_;

  my $ip = $self->param("ip");

  $self->render_later;

  $self->redis->get(
    "status:$ip:online",
    sub {
      my ( $redis, $res ) = @_;
      if ($res) {
        $self->render( json => { ok => Mojo::JSON->true } );
      }
      else {
        $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
      }
    }
  );
}

sub message_to_server {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('MB_SEND_COMMAND') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission MB_SEND_COMMAND.'
      },
      status => 403
    );
  }

  my $json = $self->req->json;
  my ($to) = ( $self->req->url =~ m/^.*\/(.*?)$/ );

  map {
    #warn "Sending message to client...\n";
    #warn Mojo::JSON->encode($json) . "\n";
    $self->app->log->debug( "Sending message to client: "
        . $to . " => "
        . Mojo::JSON->encode($json) );

    if ( !exists $_->{sequences} ) {
      $_->{sequences} = [];
    }

    push( @{ $_->{sequences} }, $json->{seq} ) if ( $json->{seq} );

    $_->{tx}->send( Mojo::JSON->encode($json) );
  } @{ $clients->{$to} };

  $self->render( json => { ok => Mojo::JSON->true } );
}

sub _ua { return Mojo::UserAgent->new; }

sub get_random {
  my $self  = shift;
  my $count = shift;
  my @chars = @_;

  srand();
  my $ret = "";
  for ( 1 .. $count ) {
    $ret .= $chars[ int( rand( scalar(@chars) - 1 ) ) ];
  }

  return $ret;
}

sub get_client_info {
  my ($self) = @_;
}

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $r->websocket("/messagebroker")->to("message_broker#broker");

  $r->get("/1.0/messagebroker/client")->over( authenticated => 1 )
    ->to("message_broker#clients");

  $r->post("/1.0/messagebroker/client/:to")->over( authenticated => 1 )
    ->to("message_broker#message_to_server");

  $r->get("/1.0/messagebroker/client/*ip/online")->over( authenticated => 1 )
    ->to("message_broker#is_online");
}

1;
