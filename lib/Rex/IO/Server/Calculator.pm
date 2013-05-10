#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Calculator;

use strict;
use warnings;
use Data::Dumper;

#
# simple calculator engine
#
# cur: system.load
# prev: system.load
# math: +
# push: $solution
#

sub parse {
   my ($class, $script, $data) = @_;

   my @math_register;
   my $data_register = {};

   my $cmd_map = {
      cur => sub {
         my ($key) = @_;
         push(@math_register, $data->{$key}->[-1]);
      },
      prev => sub {
         my ($args) = @_;
         my ($key, $count) = split(/,\s?/, $args);

         if($count) {
            my $i = -2;
            while($i != (($count * -1) -2)) {
               if($data->{$key}->[$i]) {
                  push(@math_register, $data->{$key}->[$i]);
               }
               else { last; }

               $i--;
            }
         }
         else {
            push(@math_register, $data->{$key}->[-2]);
         }
      },
      math => sub {
         my ($op) = @_;
         my @ops = split(/\s+/, $op);

         for my $o (@ops) {
            my $last = pop @math_register;
            my $prev = pop @math_register;
            push(@math_register, eval "$prev $o $last");
         }
      },
      push => sub {
         my ($var) = @_;
         $data_register->{$var} = $math_register[-1];
      },
      pop => sub {
         my ($var) = @_;
         if(exists $data_register->{$var}) {
            push(@math_register, $data_register->{$var});
         }
         else {
            push(@math_register, $var);
         }
      },
      dump => sub {
         print STDERR "==== MATH REGISTER ====\n";
         print STDERR Dumper(\@math_register);

         print "==== DATA REGISTER ====\n";
         print STDERR Dumper($data_register);
      },
      agt => sub {
         # all greater than
         my ($n) = @_;

         my $lower = 0;
         for my $itm (@math_register) {
            if($itm < $n) {
               $lower = 1;
               last;
            }
         }

         $data_register->{'$solution'} = $lower == 1 ? 0 : 1;
      },
      alt => sub {
         # all lower than
         my ($n) = @_;

         my $higher = 0;
         for my $itm (@math_register) {
            if($itm > $n) {
               $higher = 1;
               last;
            }
         }

         $data_register->{'$solution'} = $higher == 1 ? 0 : 1;
      },
      lt => sub {
         my ($n) = @_;

         if($math_register[-1] < $n) {
            $data_register->{'$solution'} = 1;
         }
         else {
            $data_register->{'$solution'} = 0;
         }
      },
      gt => sub {
         my ($n) = @_;

         if($math_register[-1] > $n) {
            $data_register->{'$solution'} = 1;
         }
         else {
            $data_register->{'$solution'} = 0;
         }
      },
      cmr => sub {
         @math_register = ();
      },
 
   };


   my @lines = split(/\r?\n/, $script);
   for my $line(@lines) {
      chomp $line;
      next if($line =~ m/^#/);
      next if($line =~ m/^$/);

      my ($cmd, $data) = split(/:\s+?/, $line, 2);

      my $code = $cmd_map->{$cmd};
      $code->($data);
   }

   return $data_register->{'$solution'};
}

1;
