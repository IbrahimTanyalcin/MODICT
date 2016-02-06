#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;
use lib "../";
use Core::Correlate qw(correlate);

print "Welcome to trainer for MODICT v1.0\nThis tool will try to maximize the correlation between given experimental measurements and modict scores.\n";
#Below sub is to retrieve the arguments if any and sort them.
getopt();

if ((grep {$_ =~ /^-[hH]{1}$/} @ARGV)||(grep {$_ =~ /^-[Hh][Ee][Ll][Pp]$/} @ARGV)) {
print "
#IMPORTANT\n
#FOR PEOPLE WHO WANT TO USE TRAINER WITH ARGUMENTS, BELOW ARE THE POSSIBLE ARGUMENTS\n
#PREFIXING THE ARGUMENTS WITH - OR -- AND ADDING = or SPACE AT THE END DOES NOT MATTER\n
#1: PATH  //Point to the MODICT directory.\nTrainer will directly hand it to MODICT. You should NOT put a slash at the end.\nEx: -path C:/Desktop/MODICT OR --path C:/Desktop/MODICT or -path=C:/Desktop/MODICT\n
#2: Conservation file name Ex: --conservation conservation.txt OR -conservation=conservation.txt\n
#2: Input file name. The input should be tab separated values of modict score, enzymatic activity and file name.\nEach observation should be separated by a new line.\nEx: --input list.txt OR -input=list.txt\n";
exit;
} else {
}

if ((grep {$_ =~ /^-[vV]{1}$/} @ARGV)||(grep {$_ =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/} @ARGV)) {
	print "Version v1.0\n";
	exit;
} else {
}

#SET THE BELOW PARAMETER TO THE VERSION OF THE MODICT YOU WANT TO USE WITH TRAINER:
my $which_MODICT = "MODICT_v1.0.pl";

#The first argument you pass to trainer will be used as path. Trainer will directly hand it to MODICT. You should not put a slash at the end. Ex: C:/Desktop/MODICT
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
		#Below is not needed on this case;
		#print "Remember that optimized weight score results can differ greatly with/out the presence of conservation scores...\nProceeding...\n";
		$conservation = "-";
	}
}

my $input;
if ((defined $ARGV[2])&&($ARGV[2] =~ /.*[.]txt/)) {
	chomp $ARGV[2];
	$input = $ARGV[2];
} else {
	RETRY_input:
	print "Please type the name of your input file...[list.txt]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ !~ /^.*[.]txt/) {
		goto RETRY_input;
	}
	$input = $_;
}

###RESIDUAL ENZYME ACTIVITY --> @X_values, MODICT SCORES --> @Y_values###
my @X_values;
my @Y_values;
my @fileNames;
open(my $inputFile, '<',"$PATH_domestic/Input/$input") or die "Cannot open the input file!\n";
print "Should we skip the header?\n";
my $answer = <STDIN>;
chomp $answer;
if ($answer =~ /y.*/) {
	print "How many times should the header be skipped?\n";
	my $header_skip_times = <STDIN>;
	chomp $header_skip_times;
	my $skip_count = 0;
	until ($skip_count == $header_skip_times) {
		print "Skipping header...\n";
		skip_header($inputFile);
		$skip_count++;
	}
} else {
	print "The header will NOT be skipped...\n";
}
while (<$inputFile>) {
	my @splitted = split(/\t+|\s+/,$_);
	chomp $splitted[0];
	push (@X_values,$splitted[0]);
	push (@Y_values,$splitted[1]);
	push (@fileNames,$splitted[2]);
}
my $initialCorrelation = correlate(\@X_values,\@Y_values);
print "Your initial pearson correlation coefficient is $initialCorrelation\n";

my $failedIterationThreshold;
print "Please enter the maximum number of iterations that can be performed without any improvement..[Hint: Enter a number between 1000 and 100000]\n";
RETRY_threshold:
$failedIterationThreshold = <STDIN>;
chomp $failedIterationThreshold;
if ($failedIterationThreshold !~ /^[1-9][0-9]{3}[0-9]*$/) {
	print "Retry...\n";
	goto RETRY_threshold;
}
print "Value accepted..\n";

#######SEED########
my $seed = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$fileNames[0], "--conservation=".$conservation, "--weight=-", "--mode=-iterate", "--path=".$PATH);
#######SEED########

#$i --> input file number, $j --> switch control, $k --> number of iteration to determine termination
my @switch = qw(0 1);
my $j = 0;
my $signal = $switch[($j % 2)];
my $k = 0;
my $iterationNumber = 0;
my $improvedCorrelation = 0;
until ($k == $failedIterationThreshold) {
	my @results;
	for (my $i = 0;$i<scalar(@fileNames);$i++) {
		if ($i == 0) {
			my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$fileNames[$i], "--conservation=".$conservation, "--weight=-", "--mode=-iterate_evolve", "--path=".$PATH, "--signal=".$signal);
			my @output = split (/\n/, $results);
			my $value = $output[$#output];
			chomp $value;
			push (@results, $value);
		} else {
			my $results;
			if ($signal == 0) {
				$results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$fileNames[$i], "--conservation=".$conservation, "--weight=-iterate_MODICT_trial.txt", "--mode=-", "--path=".$PATH);
			} elsif ($signal == 1) {
				$results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$fileNames[$i], "--conservation=".$conservation, "--weight=-iterate_MODICT.txt", "--mode=-", "--path=".$PATH);
			}
			my @output = split (/\n/, $results);
			my $value = $output[$#output];
			chomp $value;
			push (@results, $value);
		}
	}
	$iterationNumber++;
	$k++;
	my $correlation = correlate(\@X_values,\@results);
	print "Current value $correlation..\n";
	if ($correlation < $improvedCorrelation) {
		$k = 0;
		$j++;	
		$signal = $switch[($j % 2)];
		$improvedCorrelation = $correlation;
		print "Loop changed!\n";
	}
	if (($iterationNumber != 0)&&($iterationNumber % 100 == 0)) {
		print "$iterationNumber iterations complete!\n";
	}
	if ($iterationNumber >= 1000000) {
		print "You have performed 1000000 iterations!\n";
		exit;
	}
}
print "REPORT:\n";
if (($initialCorrelation>0)&&($initialCorrelation*$improvedCorrelation < 0)) {
	print "Sign: Your initial correlations were positive (not good), we were able to reverse that..\n";
} elsif (($initialCorrelation>0)&&($initialCorrelation*$improvedCorrelation > 0)) {
	print "Sign: Your initial correlations were positive (not good), we could not obtain a negative one..\n";
} elsif (($initialCorrelation<0)&&($initialCorrelation*$improvedCorrelation > 0)) {
	print "Sign: Your initial correlations were negative, Somehow we reversed that...to positive.\nThere is something terribly wrong going on here...\n";
} elsif (($initialCorrelation<0)&&($initialCorrelation*$improvedCorrelation < 0)&&($initialCorrelation<$improvedCorrelation)) {
	print "Sign: Your initial correlations were negative, but we couldn't find a better weight score combination other than the default one.\n";
} elsif (($initialCorrelation<0)&&($initialCorrelation*$improvedCorrelation < 0)&&($initialCorrelation>$improvedCorrelation)) {
	print "Sign: Your initial correlations were negative and we were able to find a better alternative:$improvedCorrelation\n";
	print "We were able to improve your correlation coefficient by ". sprintf("%.0f",(abs($improvedCorrelation)/abs($initialCorrelation)*100)) ." percent!\n";
}
if ($signal == 0) {
	copy ("$PATH_domestic/Essentials/Iterate_MODICT.txt","$PATH_domestic/Output/Trainer_results.txt") or  die "Copy of trainer results failed!..\n";
} elsif ($signal == 1) {
	copy ("$PATH_domestic/Essentials/Iterate_MODICT_trial.txt","$PATH_domestic/Output/Traniner_results.txt") or  die "Copy of trainer results failed!..\n";
}
print "You can find your results in ../Output/.\nThank you and goodbye...\n";


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
GetOptions ("path=s" => \$argv_0, "conservation=s" => \$argv_1, "input=s" => \$argv_2, "need=s" => \$argv_3) or die ("Error parsing the command line arguments!\n");

#Form an hash that keeps all of the references to raw arguments chopped from GetOptions. If they already come with dashes, dashes will not be added. This is crucial for inter-script interactions. For refine mod we know that this is already not the case.
my %raw_argv = ("path" => \$argv_0, "conservation" => \$argv_1, "input" => \$argv_2, "need" => \$argv_3);
for my $element (keys %raw_argv) {
	if (${$raw_argv{$element}} !~ /^\s*\t*-/) {
		${$raw_argv{$element}} = "-".${$raw_argv{$element}};
		#check to see them.
		#print ${$raw_argv{$element}}."\n";
	} elsif (${$raw_argv{$element}} =~ /[-]+/) {
	#replace all instances of multi dashes to single dashes.
		${$raw_argv{$element}} =~ s/[-]+/-/g;
	}
}
#Extention check
my %extentions = ("conservation" => \$argv_1, "input" => \$argv_2);
for my $element (keys %extentions) {
	if (${$raw_argv{$element}} !~ /^-$/) {
		if (${$raw_argv{$element}} !~ /[.]txt/) {
			print "The files you have specified has to be entered with their extention.\nWhen you specify file write --fasta file.txt instead of --fasta file!\n";
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
	push (@ARGV, $argv_3);
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