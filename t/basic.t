use Mojo::Base -strict;

use Test::More tests => 2;
use Test::Mojo;

# create a tmp conf file
open(my $fh, ">", "server.conf");
print $fh "{ cmdb => 'http://localhost:3000' }";
close($fh);

my $t = Test::Mojo->new('Rex::IO::Server');
$t->get_ok('/')->status_is(404);
