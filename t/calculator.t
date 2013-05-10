use Test::More tests => 2;

use_ok 'Rex::IO::Server::Calculator';


my $data = {
   "system.cpu.usage.user" => [qw/1 2 3 1 2 3 1 2 3/],
};

my $script = "
prev: system.cpu.usage.user, 5
agt: 5
";

my $ret = Rex::IO::Server::Calculator->parse($script, $data);

ok($ret == 0, "nothing is greater");

