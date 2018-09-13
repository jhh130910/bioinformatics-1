#!/usr/bin/env perl
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($fa,$out,$type,$dsh);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"fa:s"=>\$fa,
	"type:s"=>\$type,
	"out:s"=>\$out,
	"dsh:s"=>\$dsh,
	) or &USAGE;
&USAGE unless ($fa and $out and $dsh );
mkdir $out if (!-d $out);
$out=ABSOLUTE_DIR($out);
mkdir $dsh if (!-d $dsh);
$dsh=ABSOLUTE_DIR($dsh);
 $type||="nucl";
my $emapper="pfam_scan.pl -clan_overlap -align -cpu 8 ";
if ($type eq "nucl") {
	$emapper.="-translate all ";
}
open SH,">$dsh/step08.pfam.sh";
open In,$fa;
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/);
	my $fname=basename($_);
	print SH "$emapper -fasta $_ -dir $out/ -json pretty -dir /mnt/ilustre/users/long.huang/DataBase/2018-8-27/pfam > $out/$fname.pfam.json && ";
	print SH "perl $Bin/bin/pfam-json.pl -input $out/$fname.pfam.json -output $out/$fname.pfam.table\n";
}
close SH;
close In;
my $job="perl /mnt/ilustre/users/dna/.env//bin//qsub-sge.pl $dsh/step08.pfam.sh --maxjob=20 --CPU 8 --Resource mem=8G";
`$job`;

#######################################################################################
print STDOUT "\nDone. Total elapsed time : ",time()-$BEGIN_TIME,"s\n";
#######################################################################################
sub ABSOLUTE_DIR #$pavfile=&ABSOLUTE_DIR($pavfile);
{
	my $cur_dir=`pwd`;chomp($cur_dir);
	my ($in)=@_;
	my $return="";
	if(-f $in){
		my $dir=dirname($in);
		my $file=basename($in);
		chdir $dir;$dir=`pwd`;chomp $dir;
		$return="$dir/$file";
	}elsif(-d $in){
		chdir $in;$return=`pwd`;chomp $return;
	}else{
		warn "Warning just for file and dir \n$in";
		exit;
	}
	chdir $cur_dir;
	return $return;
}

sub USAGE {#
        my $usage=<<"USAGE";
Contact:        long.huang\@majorbio.com;
Script:			$Script
Description:

Usage:
  Options:
  -ref	<file>	input genome name,fasta format,
  -gff	<file>	input genome gff file,
  -out	<dir>	output data prefix
  -chr	<file>	chromosome change file
  -dsh	<dir>	output work sh dir

  -h         Help

USAGE
        print $usage;
        exit;
}
