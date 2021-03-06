#!/usr/bin/env perl -w

use strict;
use warnings;

use Digest::Bcrypt;

$|++;

if(@ARGV < 2) {
   print "Usage: generate_user.pl <conf-file> <username>\n";
   exit 1;
}

my $conf_file = $ARGV[0];
my $user      = $ARGV[1];

print "Enter password: ";
my $pass      = <STDIN>;
chomp $pass;

unless(-f $conf_file) {
   print "$conf_file is not a file\n";
   exit 2;
}

my $content = eval { local(@ARGV, $/) = ($conf_file); <>; };
my $config  = eval 'package Rex::IO::Server::Config::Loader;'
                     . "no warnings; $content";

die "Couldn't load configuration file: $@" if(!$config && $@);
die "Config file invalid. Did not return HASH reference." if( ref($config) ne "HASH" );

my $salt = $config->{auth}->{salt};
my $cost = $config->{auth}->{cost};

my $bcrypt = Digest::Bcrypt->new;
$bcrypt->salt($salt);
$bcrypt->cost($cost);
$bcrypt->add($pass);

my $pw = $bcrypt->hexdigest;

print "INSERT INTO users (name, password) VALUES('$user', '$pw')\n";

