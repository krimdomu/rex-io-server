#!/usr/bin/env perl

use strict;
use warnings;
use Text::Markdown;


my $doc = $ARGV[0];
my $m = Text::Markdown->new;
my $content = eval { local(@ARGV, $/) = ($doc); <>; };
my $out = $m->markdown($content);

print $out;

sub interp_line {
   my ($line) = shift;

   $line =~ s|^### (.*)$|<h3>$1</h3>|gms;
   $line =~ s|^## (.*)$|<h2>$1</h2>|gms;
   $line =~ s|^# (.*)$|<h1>$1</h1>|gms;

   $line =~ s|\*|<li>$1</li>|gms;
}


