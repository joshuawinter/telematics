#!/usr/bin/perl
#punderwood regex magic
# ./geosql2csv.pl <filename>

$/="VALUES \(";

while(<>)
{
next if ( /commit/i);
if ( /\'\)\;/ )
{
s/\)\;\n.*//;
print $_ ;
print "\n";
}
}
