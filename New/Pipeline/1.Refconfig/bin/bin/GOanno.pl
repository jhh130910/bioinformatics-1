#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fIn,$fOut,$tophit,$topmatch,$eval,$fa);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"d:s"=>\$fIn,
	"o:s"=>\$fOut,
	"i:s"=>\$fa,
			) or &USAGE;
&USAGE unless ($fIn and $fOut and $fa);
open In,$fa;
my %gene;
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/);
	my ($fafile,undef)=split(/\s+/,$_);
	$/=">";
	open Seq,$fafile;
	while (<Seq>) {
		chomp;
		next if ($_ eq ""||/^$/);
		my ($id,undef)=split(/\s+/,$_);
		$gene{$id}=1;
	}
	close Seq;
	$/="\n";
}
close In;
$tophit||=1;
$topmatch||=1;
$eval||="10e-5";
my @blast=glob("$fIn/*.blast");
	my %anno;

foreach my $blast (@blast) {
	open In,$blast;
	my ($query,$query_len,$match_num,$qFrom,$qTo,$hit,$hit_num,$hitID,$hit_len,$hFrom,$hTo,$identity,$percent,$gap,$length,$bits,$e_value,$annotation);
	while (<In>) {
		chomp;
		next if ($_ eq ""||/^$/);
		my @cycle=split("\n>",$_);
			if (/<(Iteration_query-def)>(.*)<\/\1/) {
				$query = $2;
			} elsif (/<(Iteration_query-len)>(.*)<\/Iteration_query-len>/) {
				$query_len = $2;
			} elsif (/<(Hit_num)>(.*)<\/Hit_num>/) {
				$hit_num = $2;
			} elsif (/<(Hit_id)>(.*)<\/\1/) {
				$hitID = $2;
			} elsif (/<(Hit_def)>(.*)<\/Hit_def>/) {
				$annotation =(split /&gt;/, $2)[0];
			} elsif (/<(Hit_len)>(.*)<\/Hit_len>/) {
				$hit_len = $2;
			} elsif (/<(Hsp_num)>(.*)<\/Hsp_num>/) {
				$match_num = $2;
			} elsif (/<(Hsp_bit-score)>(.*)<\/\1/) {
				$bits = int($2);
			} elsif (/<(Hsp_evalue)>(.*)<\/\1/) {
				$e_value = $2;
			} elsif (/<(Hsp_query-from)>(.*)<\/\1/) {
				$qFrom = $2;
			} elsif (/<(Hsp_query-to)>(.*)<\/\1/) {
				$qTo = $2;
			} elsif (/<(Hsp_hit-from)>(.*)<\/\1/) {
				$hFrom = $2;
			} elsif (/<(Hsp_hit-to)>(.*)<\/\1/) {
				$hTo = $2;
			} elsif (/<(Hsp_identity)>(.*)<\/\1/) {
				$identity = $2;
			} elsif (/<(Hsp_gaps)>(.*)<\/\1/) {
				$gap = $2;
			} elsif (/<(Hsp_align-len)>(.*)<\/\1/) {
				$length = $2;
			} elsif (/<\/Hsp>/) {
				$percent = sprintf("%.2f", $identity / $length * 100);
				$percent = "$identity\/$length\($percent\)";
				$annotation=~/^(\S+)\s.*/;
				$hit = $1;
				if ($hit_num<=$tophit && $match_num<=$topmatch && $e_value<=$eval) {
					my @GOid;
					my @detail;
					while ($annotation =~ m/\[(GO:\d+) "([^\"\']*)" evidence=\w+\]/g) {
						push @GOid,$1;
						push @detail,$2;
					}
					if (scalar @GOid == 0 || scalar @detail == 0) {
						 $anno{$query}="--\t--";
						next;
					}
					$anno{$query}=join("\t",join(",",@GOid),join(":",@detail));
				}
			}
		}
	close In;

}

open Out,">$fOut";
print Out "#GeneID\tGOTERM\tGOANNO\n";
foreach my $query (sort keys %gene) {
	$anno{$query}||="--\t--";
	print Out $query,"\t",$anno{$query},"\n";
}
close Out;




#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub USAGE {#
        my $usage=<<"USAGE";
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:

Usage:
  Options:
	-i	<file>	input file name
	-o	<file>	output file name
	-fa	<file>	input fasta file
	-h         Help

USAGE
        print $usage;
        exit;
}
