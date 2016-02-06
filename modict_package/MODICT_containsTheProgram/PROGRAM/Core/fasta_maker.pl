#!/usr/bin/perl
use strict;
use warnings;
#use IPC::System::Simple qw(system capture);
use File::Copy qw(copy);

print "Welcome to fastamaker.\nWhat this program will do for you is to take a list of mutations like:\np.A345V\np.D400N\nand perform these changes in a new fasta file.\nYou will need:\n1.Fasta file of wildtype protein.\n2.List of mutations, one mutation per line.\n\n";

our $ERROR = 0;
print "Set the number of aminoacids per line..[enter a number]\n";
RESET_PERLINE:
our $perline_element = <STDIN>;
if ($perline_element !~ /^[1-9]+[0-9]*$/) {
	goto RESET_PERLINE;
}
chomp $perline_element;

#Commented lines are not necessary anymore
#my $PATH;
#if ((defined $ARGV[0])&&(($ARGV[0] =~ /.*\/.*/)||($ARGV[0] =~ /-/))) {
#	$PATH = $ARGV[0];
#	chomp $PATH;
#} else {
#	print "Please type the path or press enter to skip...\n";
#	$_ = <STDIN>;
#	chomp $_;
#	$PATH = "-".$_;
#	if ($PATH !~ /.*\/.*/) {
#	$PATH = ".";
#	}
#}
my $PATH_domestic = "..";
#$PATH_domestic =~ s/-//g;
#if ($PATH_domestic eq "") {
#	$PATH_domestic = ".";
#}

#Write in your fasta file name
print "Write in your fasta filename...[Ex:fasta.txt]\n";
my $filename_fasta = <STDIN>;
chomp $filename_fasta;

open(my $fasta_file, '<',"$PATH_domestic/Input/$filename_fasta") or die "Cannot open fasta file!\n";
open(my $outputfile, '>',"$PATH_domestic/Output/fastamaker_fastas.txt") or die "Cannot write to file!\n";

my @fasta_array = ();
while (<$fasta_file>) {
	if ($_ =~ /.*[>]+.*/ || $_ =~ /.*[|.;]+.*/ || $_ !~ /^[ARNDBCQEZGHILKMFPSTWYVarndbcqezghilkmfpstwyv]+\s*$/) {
		} else {
		chomp $_;
		my @splitted = split ("",$_);
		push  (@fasta_array, @splitted);
	}
}
my $protein_code = join ("",@fasta_array);
print "Below is your protein code from fasta file:\n";
print $protein_code."\n";

print "Write in your mutations filename. 1 mutation in p.XNNNY format per line...[Ex:mutationfile.txt]\n";
my $filename_mutations = <STDIN>;
chomp $filename_mutations;

open(my $mutations_file, '<',"$PATH_domestic/Input/$filename_mutations") or die "Cannot open mutations file!\n";

my @mutations_array = ();
my $line_number = 1;
my $item_number = 0;
while (<$mutations_file>) {
	chomp $_;
	if ($_ =~ /^\s*\t*$/) {
		print "Empty line detected. Passing..";
		$line_number++;
		next;
	}
	my @splitted = split("",$_);
	my @first_aminoacid = grep{($splitted[$_] =~ /^[A-Z]$/)&&($splitted[$_+1] !~ /\./)&&($splitted[$_+1] =~ /[0-9]+/)&&($splitted[$_] ne $splitted[$#splitted])}(0..$#splitted-1);
	#check if it captures correctly. Normally it will print 20, 2 for the second element, 0 means only 1 element..
	#print $first_aminoacid[0].$#first_aminoacid."\n";
	if ($#first_aminoacid != 0) {
		print "First aminoacid detection error at line $line_number!\n";
		$ERROR++;
		$line_number++;
		next;
	}
	my @last_aminoacid = grep{($splitted[$_] =~ /^[A-Z]$/)&&($splitted[$_] eq $splitted[$#splitted])&&($splitted[$_] ne $first_aminoacid[0])}(0..$#splitted);
	#similar situation to above..
	#print $last_aminoacid[0].$#last_aminoacid.$splitted[$last_aminoacid[0]]."\n";
	if ($#last_aminoacid != 0) {
		print "Last aminoacid detection error at line $line_number!\n";
		$ERROR++;
		$line_number++;
		next;
	}
	$_ =~ s/[A-Z]|\.//gi;
	#print $_."\n";
	if ($_ =~ /^[1-9]+[0-9]*$/) {
		my @residue_number_first_aminoacid_last_aminoacid = ();
		push (@residue_number_first_aminoacid_last_aminoacid,$_);
		push (@residue_number_first_aminoacid_last_aminoacid,$splitted[$first_aminoacid[0]]);
		push (@residue_number_first_aminoacid_last_aminoacid,$splitted[$last_aminoacid[0]]);
		@{$mutations_array[$item_number]} = @residue_number_first_aminoacid_last_aminoacid;
		$item_number++;
		#push(@mutations_array,@residue_number_first_aminoacid_last_aminoacid);
		#watch out that if you use "push(@mutations_array,@residue_number_first_aminoacid_last_aminoacid);" it infact creates only one array, NOT array of array...
		#print @mutations_array."\n";
	} else {
		print "Format error at line $line_number.\n";
		$ERROR++;
	}
	$line_number++;
}

#print some things below for check purposes
#print $mutations_array[0]."\n";
#print @{$mutations_array[0]}."\n";
#print ${$mutations_array[0]}[0]."\n";
#print $fasta_array[${$mutations_array[0]}[0]-1]."\n";

for (my $i = 0;$i <= $#mutations_array;$i++) {
	my @mutated_fasta = @fasta_array;
	if ($mutated_fasta[${$mutations_array[$i]}[0]-1] eq ${$mutations_array[$i]}[1]) {
		$mutated_fasta[${$mutations_array[$i]}[0]-1] = ${$mutations_array[$i]}[2];
	} else {
		print "The native amino acid cannot be matched on mutation at line $i!\n";
		$ERROR++;
		next;
	}
	my $output = ">".${$mutations_array[$i]}[1].${$mutations_array[$i]}[0].${$mutations_array[$i]}[2].":\n";
	for (my $i = 1;$i <= $#mutated_fasta+1;$i++) {
		$output = $output.$mutated_fasta[$i-1];
		if (($i % $perline_element == 0) && ($i != $#mutated_fasta+1)) {
			$output = $output."\n";
		}
	}
	$output = $output."\n";
	print $outputfile $output;
}

print "Would you like batch file for polyphen 2?[y/n]";
my $polyphen = <STDIN>;
chomp $polyphen;
if ($polyphen =~ /^y.*/i) {
	open(my $polyphenfile, '>',"$PATH_domestic/Output/fastamaker_polyphen.txt") or die "Cannot write to polyphen file!\n";
	print "Enter accession number..\n";
	my $accession = <STDIN>;
	chomp $accession;
	for (my $i = 0;$i <= $#mutations_array;$i++) {
		print $polyphenfile $accession." ".${$mutations_array[$i]}[0]." ".${$mutations_array[$i]}[1]." ".${$mutations_array[$i]}[2]."\n";
	}
}


print "Job processed with $ERROR errors...\n";

exit;
