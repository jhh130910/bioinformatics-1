#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($proc,$vcflist,$dOut,$dShell,$ref,$dict);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"vcf:s"=>\$vcflist,
	"ref:s"=>\$ref,
	"out:s"=>\$dOut,
	"proc:s"=>\$proc,
	"dsh:s"=>\$dShell
			) or &USAGE;
&USAGE unless ($vcflist and $dOut and $dShell);
$proc||=20;
mkdir $dOut if (!-d $dOut);
$dOut=ABSOLUTE_DIR($dOut);
$vcflist=ABSOLUTE_DIR($vcflist);
$ref=ABSOLUTE_DIR($ref);
mkdir $dShell if (!-d $dShell);
$dShell=ABSOLUTE_DIR($dShell);
open SH,">$dShell/step07.vcf-merge.sh";
open In,$vcflist;
my $vcfs;
my $number=0;
my $nct=8;
while (<In>) {
	chomp;
	next if ($_ eq "" || /^$/);
	my ($sampleID,$vcf)=split(/\s+/,$_);
	$vcfs.=" -V $vcf ";
}
close In;
print SH "java -Djava.io.tmpdir=$dOut/tmp/ -Xmx20G -jar $Bin/bin/GATK/GenomeAnalysisTK.jar -T CombineVariants -R $ref $vcfs -o $dOut/pop.noid.vcf --genotypemergeoption UNSORTED -log $dOut/pop.merge.log && ";
print SH "bcftools annotate --set-id +\'\%CHROM\\_\%POS\' $dOut/pop.noid.vcf -o $dOut/pop.variant.vcf\n";
close SH;
my $job="perl /mnt/ilustre/users/long.huang/Pipeline/v2.0/09_Qsub/qsub-sge.pl --Resource mem=20G   --maxjob $proc $dShell/step07.vcf-merge.sh";
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
	fq thanslate to fa format
	eg:
	perl $Script -i -o -k -c

Usage:
  Options:
  -vcf	<file>	input bamlist file
  -ref	<file>	input reference file
  -out	<dir>	output dir
  -proc <num>	number of process for qsub,defaule 20
  -dsh	<dir>	output shell dir
  -h         Help

USAGE
        print $usage;
        exit;
}