#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my $usage = q{ Usage: };

my $prefix;
my $suffix;
my $root;
my $onlydom;

GetOptions(
 "prefix=s" => \$prefix,
 "suffix=s" => \$suffix,
 "root=s" => \$root,
 "onlydom" => \$onlydom,
) or die "Bad opt!";


use UrlToDest; 

$\="\n";
while ( my $url = <STDIN> ){
 chomp $url;
 my ($dom_dest, $path_dest) = UrlToDest::that($url, prefix=>$prefix, root=>$root, suffix=>$suffix);
 if ($onlydom){ print "$dom_dest.$suffix" }
 else{ print $dom_dest.$path_dest }
} 