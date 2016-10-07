#!/usr/bin/env perl

package UrlToDest;
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;


sub that{
 # преобразует url в имя файла для сохранения

 # params: prefix=>PREFIX_DIR||"", root=>STRING||"ROOT", suffix=>STRING||"saved"
 my $url = shift or die "Url!";
 my %pa = @_;
 $url =~ s/\"|\'//g; # убираются кавычки (любые, даже в тексте) 
 $url =~ s|^\w+://||; # отрезается протокол 
 $url =~ s|www\.||; # отрезается www.
 $url =~ s|[^\w\.\/]|-|g; # небуквы (в т.ч. все русские буквы) заменяются на "-" 
 $url =~ s|\.+/||g; # ссылки на текущ или родительск папку удаляются ./ или ../
 $url = lc($url);
 
 my ($d,$p) = split "/", $url, 2; # делится на домен и остальное
 my ($c1) = $d=~/^(.)/;
# warn $c1;
 my ($c2) = $d=~/^(..)/;
# warn $c2;
 my ($c3) = $d=~/^(...)/;
# warn $c3;
 my $root = $pa{root}||"ROOT"; # если пути нет - то ROOT
 $p ||= $root; # если пути нет - то ROOT 

 
 my $prefix = $pa{prefix}||"";
 $prefix=~s/^\s+|\s+$//g;
 $prefix.="/" if $prefix and not $prefix =~ m|/$|; # если у префикса нет / в конце, то добавляем /
 
# my $dompath_dest = "${prefix}$first/$d/$p.".($pa{suffix}||"saved"); # путь для dom+path
# my $dom_dest = "${prefix}$first/$d.".($pa{suffix}||"saved"); # путь для dom+path
 my $dom_dest;
 if (defined($c1) and defined($c2) and defined($c3)){ 
    $dom_dest = "${prefix}$c1/$c2/$c3/$d/";
 }elsif( defined($c1) and defined($c2) ){
    $dom_dest = "${prefix}$c1/$c2/$d/";
 }elsif( defined($c1) ){
    $dom_dest = "${prefix}$c1/$d/";
 }else{
    $dom_dest = "${prefix}$d/";
 }
 my $path_dest = "$p.".($pa{suffix}||"saved");
return wantarray ?
    ($dom_dest, $path_dest) :
    $dom_dest.$path_dest;
}

1;