#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

Rex::IO::Server - The webservice component of Rex.IO

This is the webservice component of Rex.IO tieing all supported services together under one API.

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-server/issues>

=back

=head1 INSTALLATION

With cpanminus:

 cpanm Rex::IO::Server

After installing create the file I</etc/rex/io/server.conf>. And set the url to Rex::IO::CMDB.

 {
    git  => "git://url/to/your/git/repository.git",
    checkout_path => "/var/lib/rex.io/services",
    branch => "master",
     
    plugins => [
      "Cmdb",
      "FusionInventory",
    ],
      
    cmdb => "http://rex-cmdb:3000", # only needed with Cmdb Plugin
 }

And start the server:

 rex_ioserver daemon

You can also define an other Listen Port (default is 3000)

 rex_ioserver daemon -l 'http://:4000'

Right now there is no Webinterface. You can test if everything is correct with the following command:

 curl -X LIST http://localhost:3000/server

If you get an answer like this it works:

 {"ok":true,"data":{}}


=cut

package Rex::IO::Server;
use Mojo::Base 'Mojolicious';
use Data::Dumper;

our $VERSION = "0.0.3";

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   $self->plugin('PODRenderer');

   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);

   $self->plugin("Rex::IO::Server::Mojolicious::Plugin::CMDB");
   $self->plugin("Rex::IO::Server::Mojolicious::Plugin::CHI");


   # Router
   my $r = $self->routes;

   $r->route("/repository/update")->via("UPDATE")->to("repository#update");
   $r->get("/repository/:service")->to("repository#get_service");

   # load server plugins
   for my $plug (@{ $self->{defaults}->{config}->{plugins} }) {
      my $s = "Rex::IO::Server::$plug";
      eval "require $s";
      $s->__register__($self);
   }

}

1;
