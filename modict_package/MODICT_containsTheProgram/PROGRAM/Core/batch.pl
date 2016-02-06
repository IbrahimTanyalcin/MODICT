#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;

print "Welcome to batch processor.\n";
#Below sub is to retrieve the arguments if any and sort them.
getopt();

if ((grep {$_ =~ /^-[hH]{1}$/} @ARGV)||(grep {$_ =~ /^-[Hh][Ee][Ll][Pp]$/} @ARGV)) {
print "
#This is the batch processor. Please refer to i-pv.org to learn more..";
exit;
} else {
}

if ((grep {$_ =~ /^-[vV]{1}$/} @ARGV)||(grep {$_ =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/} @ARGV)) {
	print "Version v1.0\n";
	exit;
} else {
}

#SET THE BELOW PARAMETER TO THE VERSION OF THE MODICT YOU WANT TO USE WITH ITERATOR:
my $which_MODICT = "MODICT_v1.0.pl";

#The first argument you pass will be used as path. Then it will be directly handed to MODICT. You should not put a slash at the end. Ex: C:/Desktop/MODICT
my $PATH;
if ((defined $ARGV[0])&&(($ARGV[0] =~ /.*\/.*/)||($ARGV[0] =~ /-/))) {
	$PATH = $ARGV[0];
	chomp $PATH;
} else {
	print "Please type the path to MODICT or press enter to skip...\n";
	$_ = <STDIN>;
	chomp $_;
	$PATH = "-".$_;
	if ($PATH !~ /.*\/.*/) {
	$PATH = "..";
	}
}
my $PATH_domestic = $PATH;
$PATH_domestic =~ s/-//g;
if ($PATH_domestic eq "") {
	$PATH_domestic = "..";
}

my $conservation;
if ((defined $ARGV[1])&&(($ARGV[1] =~ /.*[.]txt/)||($ARGV[1] =~ /-/))) {
	chomp $ARGV[1];
	$conservation = $ARGV[1];
} else {
	print "Do you have your conservation scores?[y/n]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^[yY].*/) {
		print "Please type the name of your conservation file with the extention.\nRemember that this file should be located in ../MODICT/Input...[Ex: conservation.txt]\n";
		$conservation = <STDIN>;
		chomp $conservation;
		$conservation = "-".$conservation;
	} else {
		print "Remember that optimized weight score results can differ greatly with/out the presence of conservation scores...\nProceeding...\n";
		$conservation = "-";
	}
}

my $list = $ARGV[2];
$list =~ s/-//g;
chomp $list;

open (my $list_file, '<', "$PATH_domestic/Input/$list") or die ("Cannot open the specified list file!\n");
my @list_array;
while (<$list_file>) {
	chomp $_;
	if ($_ =~ /^\s*\t*\n*$/) {
		next;
	}
	push (@list_array,$_);
}

open (my $result_file, '>', "$PATH_domestic/Output/Batch.txt") or die ("Cannot write to batch output file!\n");

for (my $i = 0; $i < scalar(@list_array); $i++ ) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$list_array[$i], "--conservation=".$conservation, "--weight=-", "--path=".$PATH);
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		$value = sprintf("%.3f",$value);
		my $list_item = $list_array[$i];
		$list_item =~ s/([.]txt)//g;
		print $result_file $list_item."\t".$value."\n";
}

print "You can find your results in ../Output/List.txt.\nThank you and goodbye...\n";

sub standard_deviation {
#Here we will calculate the standard deviation of the RMSD values from the initial @input_array
my @test_array = @_;
#First change the commas or any other punctuation to dots in the @input_array, if there is any
for (my $i = 0; $i < scalar (@test_array); $i++) {
	$test_array[$i] =~ s/[,;:-_|]/./;
}
#Then, find the mean
my $mean;
my $stdev;
for (my $i = 0; $i < scalar (@test_array); $i++) {
	$mean += $test_array[$i];
}
$mean = $mean/scalar(@test_array);
#Now calculate the standard deviation
my $sum = 0;
for (my $i = 0; $i < scalar (@test_array); $i++) {
	$sum += ($test_array[$i]-$mean)**2;
}
my $result = ($sum/(scalar (@test_array)-1))**(1/2);

#Uncomment below to check if the sub works correctly
#print "The mean here is $mean!\n";
#print "The sum here is $sum!\n";
#my $item_count = scalar (@test_array);
#print "The number of items here is $item_count!\n";

#retrieve the result
#return sprintf ("%.6f",$result)
return $result;
}


sub take_mean {
	my @array = @_;
	my $sum = 0;
	my $count = 0;
	foreach my $element (@array) {
		$sum += $element;
		$count++;
	}
	my $mean = $sum/$count;
	return $mean;
}

sub skip_header {
  my $FH = shift;
  <$FH>;
}


sub take_min {
my @min;
my @test_set;
@test_set = @_;
my $i = 0;
push (@min, $test_set[$i]);
$i++;
until ($i == scalar(@test_set)) {
	if ($test_set[$i]<$min[0]){
		shift (@min);
		push (@min, $test_set[$i]);
		$i++;
	} else {
		$i++;
	}
}
return $min[0];
#Uncomment below to test your array
#print "your min value for the test is $min[0]!\n";
}

sub take_max {
my @max;
my @test_set;
@test_set = @_;
my $i = 0;
push (@max, $test_set[$i]);
$i++;
until ($i == scalar(@test_set)) {
	if ($test_set[$i]>$max[0]){
		shift (@max);
		push (@max, $test_set[$i]);
		$i++;
	} else {
		$i++;
	}
}
return $max[0];
#Uncomment below to test your array
#print "your max value for the test is $max[0]!\n";
}

sub getopt {
#Define the possible arguments first.
my $argv_0 = "";
my $argv_1 = "";
my $argv_2 = "";
my $argv_3 = "";
#Use the getoptions module.
GetOptions ("path=s" => \$argv_0, "conservation=s" => \$argv_1, "list=s" => \$argv_2, "need=s" => \$argv_3) or die ("Error parsing the command line arguments!\n");
#Form an hash that keeps all of the references to raw arguments chopped from GetOptions. If they already come with dashes, dashes will not be added. This is crucial for inter-script interactions. For refine mod we know that this is already not the case.
my %raw_argv = ("path" => \$argv_0, "conservation" => \$argv_1, "list" => \$argv_2, "need" => \$argv_3);
for my $element (keys %raw_argv) {
	if ((${$raw_argv{$element}} !~ /refine/)&&(${$raw_argv{$element}} !~ /^\s*\t*-/)) {
		${$raw_argv{$element}} = "-".${$raw_argv{$element}};
		#check to see them.
		#print ${$raw_argv{$element}}."\n";
	} elsif (${$raw_argv{$element}} =~ /[-]+/) {
	#replace all instances of multi dashes to single dashes.
		${$raw_argv{$element}} =~ s/[-]+/-/g;
	}
}
#Extention check
my %extentions = ("conservation" => \$argv_1, "list" => \$argv_2);
for my $element (keys %extentions) {
	if (${$raw_argv{$element}} !~ /^-$/) {
		if (${$raw_argv{$element}} !~ /[.]txt/) {
			print "The files you have specified has to be entered with their extention.\nWhen you specify file write --list file.txt instead of --list file!\n";
			exit;
		}
	}
}
@ARGV = ();
#Sorting arguments.
if (($argv_3 =~ /^-[vV]{1}$/) || ($argv_3 =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/) || ($argv_3 =~ /^-[hH]{1}$/) || ($argv_3 =~ /^-[Hh][Ee][Ll][Pp]$/)) {
	push (@ARGV, $argv_3);
} elsif (($argv_0 eq "-")&&($argv_1 eq "-")&&($argv_2 eq "-")&&($argv_3 eq "-")) {
	print "You did not define any parameters. Entering QA mode...\n";
} else {
	print "Your parameters are taken...\n\n";
	push (@ARGV, $argv_0);
	push (@ARGV, $argv_1);
	push (@ARGV, $argv_2);
#Remove unnecessary dashes in the end. Dashes in between should still remain...
	until ($ARGV[$#ARGV] ne "-") {
		pop @ARGV;
	}
	
}
#Uncomment below to see if the arguments are taken and sorted properly.
#for (my $i = 0; $i<=$#ARGV; $i++) {
#print $ARGV[$i]."\n";
#}

}