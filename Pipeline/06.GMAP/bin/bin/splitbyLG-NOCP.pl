#!/usr/bin/perl -w
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
use Cwd qw(abs_path);
my $BEGIN_TIME=time();
my $version="1.0.0";
#######################

# ------------------------------------------------------------------
# GetOptions
# ------------------------------------------------------------------
my ($fIn,$dOut,$fLG,$fKey,$type,$Pos);
GetOptions(
				"help|?" =>\&USAGE,
				"i:s"=>\$fIn,
				"l:s"=>\$fLG,
				"d:s"=>\$dOut,
				"p:s"=>\$Pos,
				"t:s"=>\$type,
				) or &USAGE;
&USAGE unless ($fIn and $dOut and $fLG);
mkdir $dOut if (!-d $dOut);
if ($type !~ /RI/ || $type !~/ri/) {
	$type ="DH";
}
open In,$fIn;
my %info;
my $Head;
my $nind;
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/);
	if (/^#/) {
		my ($id,$type,$info)=split(/\s+/,$_,3);
		$id=~s/#//g;
		$Head=join("\t",$id,$info);
		next;
	}
	my ($id,$type,$info)=split(/\s+/,$_,3);
	$info{$id}=$info;
	my @ind=split(/\t/,$info);
	$nind=scalar @ind;
}
close In;
open List,">$dOut/pri.marker.list";
open In,$fLG;
$/=">";
while (<In>) {
	chomp;
	next if ($_ eq "" ||/^$/);
	my ($id,$marker)=split(/\n/,$_,2);
	$id=(split(/\s+/,$id))[0];
	open Out,">$dOut/$id.marker";
	print List $id,"\t","$dOut/$id.marker\n";
	my @marker=split(/\s+/,$marker);
	my @out;
	my $nloc=scalar @marker;
	my %pos;
	my $chr;
	$chr=$id;
	for (my $i=0;$i<@marker;$i++) {
		$pos{$chr}{$marker[$i]}=$i;
	}
	foreach my $chr (sort keys %pos) {
		foreach my $m (sort {$pos{$chr}{$a}<=>$pos{$chr}{$b}} keys %{$pos{$chr}}) {
			$info{$m}=~s/\ba\b/A/g;
			$info{$m}=~s/\bb\b/B/g;
			$info{$m}=~s/(..)x(..)//g;
			$info{$m}=~s/\bh\b/X/g;
			$info{$m}=~s/aa/A/g;
			$info{$m}=~s/bb/B/g;
			$info{$m}=~s/--/U/g;
			$info{$m}=~s/ab/X/g;
			$info{$m}=~s/-/U/g;
			push @out,join("\t",$m,$info{$m});
		}
	}
my $head = <<"Headend" ;
population_type $type
population_name $id
distance_function kosambi
cut_off_p_value 2.0
no_map_dist 15.0
no_map_size 0
missing_threshold 1.00
estimation_before_clustering yes
detect_bad_data yes
objective_function ML
number_of_loci $nloc
number_of_individual $nind
Headend
	print Out $head,"\n";
	print Out $Head,"\n";
	print Out join("\n",@out),"\n";
	close Out;
}
close List;
close In;
#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################

# ------------------------------------------------------------------
# sub function
# ------------------------------------------------------------------

sub GetTime {
	my ($sec, $min, $hour, $day, $mon, $year, $wday, $yday, $isdst)=localtime(time());
	return sprintf("%4d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $day, $hour, $min, $sec);
}

sub USAGE {#
	my $usage=<<"USAGE";
Program: $0
Version: $version
Contact: huangl <long.huang\@majorbio.com> 

Options:
  -help			USAGE,
  -i	genotype file�� forced
  -l	linkage lg file
  -d	output dir
  -t	population type
  
   
USAGE
	print $usage;
	exit;
}
