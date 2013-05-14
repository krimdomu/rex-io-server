use Test::More tests => 3;
use Data::Dumper;

use_ok 'Rex::IO::Server::Helper::Fdisk';
Rex::IO::Server::Helper::Fdisk->import;

my @lines = eval { local(@ARGV) = ("t/fdisk.out") ; <>; };

my $data = read_fdisk(@lines);

ok($data->{"/dev/sda"}->{size} == 500107862016, "got size of sda");
ok($data->{"/dev/md0"}->{size} == 2000405135360, "got size of md0");


