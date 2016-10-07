#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my $usage = q{
 Usage:
 cat myfile.txt | randlines -n=3 # ... and see stdout
};

my $n = 1; # number of random lines
my $len = 250; 

GetOptions(
 "n=i" => \$n,    
 "len=i" => \$len,
) or die "Bad opt!";

my @lines = grep { length($_)<=$len } <STDIN>;
my $i = 1;
my %was;
my $cnt=0;
while ($i<=$n and $cnt<@lines){
 $cnt++;
 my $ind = int(rand()*@lines);
 next if $was{$ind};
 $was{$ind}=1;
 my $line = $lines[$ind];
 chomp($line);
 next if !$line;
 $i++;
 print $line."\n";
}