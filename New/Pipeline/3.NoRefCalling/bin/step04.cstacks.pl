#!/usr/bin/perl -w
use strict;
use warnings;
my $BEGIN_TIME=time();
use Getopt::Long;
my ($ulist,$clist,$dOut,$dShell,$sample,$check);
use Data::Dumper;
use FindBin qw($Bin $Script);
use File::Basename qw(basename dirname);
my $version="1.0.0";
GetOptions(
	"help|?" =>\&USAGE,
	"ulist:s"=>\$ulist,
	"out:s"=>\$dOut,
	"dsh:s"=>\$dShell,
	"sample:s"=>\$sample,
			) or &USAGE;
&USAGE unless ($ulist and $dOut and $dShell);
mkdir $dOut if (!-d $dOut);
$dOut=ABSOLUTE_DIR($dOut);
mkdir $dShell if(!-d $dShell);
$dShell=ABSOLUTE_DIR($dShell);
$ulist=ABSOLUTE_DIR($ulist);
my $total_sample = `wc -l $ulist/ustacks.list`;
chomp $total_sample;
$total_sample=(split(/\s+/,$total_sample))[0];
my $check_sample = `ls $ulist/\*.snps.tsv.gz|wc -l`;
chomp $check_sample;
$check_sample = (split(/\s+/,$check_sample))[0];
if ($total_sample ne $check_sample){
	print "There are some wrong in step03,please check!";
	die;
}
my %group;
my $Ulist = "$ulist/ustacks.list";
if ($sample) {
	open In,$sample;
	open Out,">$dOut/sample.list";
	while (<In>) {
		chomp;
		next if ($_ eq "" ||/^$/);
		my $id=(split(/\s+/,$_))[0];
		$group{$id}=1;
		print Out $_,"\n";
	}
	close In;
	close Out;
}else{
	open In,$Ulist;
	my %tag;
	while (<In>) {
		chomp;
		next if ($_ eq ""||/^$/);
		my ($sample,$ustacks)=split(/\s+/,$_);
		open Stat,"$ustacks.tags.stat";
		while (<Stat>) {
			chomp;
			next if ($_ eq ""||/^$/||/^#/);
			my ($id,$ntag,$dep,$ad)=split(/\t/,$_);
			$tag{$sample}=$ntag;
		}
		close Stat;
	}
	close In;
	open Out,">$dOut/sample.list";
	my $n=0;
	foreach my $sam (sort {$tag{$a}<=> $tag{$b}} keys %tag) {		
		if (scalar keys %tag > 50){
			#next if ($n % 5 !=0);
		}
		print "$sam\n";
		$n++;
		$group{$sam}=1;
		print Out $sam,"\n";
	}
	close Out;
}
#print Dumper \%group;die;
open In,$Ulist;
open SH,">$dShell/step04.cstacks.sh";
my $ustack;
my $n=0;
while (<In>) {
	chomp;
	next if ($_ eq ""||/^$/);
	my ($sample,$ustacks)=split(/\s+/,$_);
	next if ($sample && !exists $group{$sample});
	if ($n == 0) {
		print SH "/mnt/ilustre/users/dna/.env/stacks-2.1/bin/cstacks  -s $ustacks -n 4 -p 32  -o $dOut 2>$dOut/cstacks.$sample.log ";
	}else{
		print SH "&& /mnt/ilustre/users/dna/.env/stacks-2.1/bin/cstacks  -s $ustacks -n 4 -p 32  -o $dOut --catalog $dOut/catalog   2>$dOut/cstacks.$sample.log ";
	}
	$n++;
}
close In;
open Out,">$dOut/cstacks.list";
print Out "cstacks\t$dOut/\n";
close Out;
my $job="perl /mnt/ilustre/users/dna/.env//bin//qsub-sge.pl --Queue dna --Resource mem=256G --CPU 32 --Nodes 1 $dShell/step04.cstacks.sh";
print "$job\n";
`$job`;
print "$job\tdone!\n";

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
        -ulist  <dir>  input ustacks list dir
        -out    <dir>   output dir
        -dsh    <dir>   output workshell dir
        -sample <file>  sample list if no use all 
  -h         Help

USAGE
        print $usage;
        exit;
}
