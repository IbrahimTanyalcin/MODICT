#!/usr/bin/perl
use strict;
use warnings;
use IPC::System::Simple qw(system capture);
use File::Copy qw(copy);
use File::Copy qw(move);
use Getopt::Long;

print "Welcome to Iterator for MODICT v1.0\nThis tool compares reference and test models\nand determines which residues account the most for structural difference.\n";
#Below sub is to retrieve the arguments if any and sort them.
getopt();

if ((grep {$_ =~ /^-[hH]{1}$/} @ARGV)||(grep {$_ =~ /^-[Hh][Ee][Ll][Pp]$/} @ARGV)) {
print "
#IMPORTANT\n
#FOR PEOPLE WHO WANT TO USE ITERATOR WITH ARGUMENTS, BELOW ARE THE POSSIBLE ARGUMENTS\n
#PREFIXING THE ARGUMENTS WITH - OR -- AND ADDING = or SPACE AT THE END DOES NOT MATTER\n
#1: PATH  //Point to the MODICT directory.\nIterator will directly hand it to MODICT. You should NOT put a slash at the end.\nEx: -path C:/Desktop/MODICT OR --path C:/Desktop/MODICT or -path=C:/Desktop/MODICT\n
#2: Conservation file name Ex: --conservation conservation.txt OR -conservation=conservation.txt\n
#3: Fasta file name Ex: --fasta fasta.txt OR --fasta=fasta.txt\n
#4: Stringency parameter Ex: --stringency 2/10/1000 OR -stringency=2.5/13.5/1500 OR --stringency vh/vvl/m \nFor an explanation of stringency parameters please read the manual\n.
#5: Refinemod Ex: --refine on OR -refine 4 OR -refine off\n";
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

#The first argument you pass to iterator will be used as path. Iterator will directly hand it to MODICT. You should not put a slash at the end. Ex: C:/Desktop/MODICT
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

my $conservationfile;
my $conservation_filename;
if ($conservation =~ /.*[.]txt/) {
$conservation_filename = $conservation;
$conservation_filename =~ s/-//g;
open($conservationfile, '<',"$PATH_domestic/Input/$conservation_filename") or die "Cannot open conservationfile!\n";
}

my @conservation_array = ();
if ($conservation =~ /.*[.]txt/) {
	while (<$conservationfile>) {
		chomp $_;
		push  (@conservation_array, $_);
	}
}



my $fasta;
my $fastafile;
if ((defined $ARGV[2])&&($ARGV[2] =~ /.*[.]txt/)) {
	chomp $ARGV[2];
	$ARGV[2] =~ s/-//g;
	$fasta = $ARGV[2];
	open($fastafile, '<',"$PATH_domestic/Input/$fasta") or die "Cannot open fastafile!\n";
} else {
	print "Do you have your fasta file?[y/n]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^[yY].*/) {
		print "Please enter the full name of your fasta file with the extention...[Ex: fasta.txt]\n";
		$_ = <STDIN>;
		chomp $_;
		$fasta = $_;
		open($fastafile, '<',"$PATH_domestic/Input/$fasta") or die "Cannot open fastafile!\n";
	} else {
		#print "You will have to manually generate your graph from the results of iterator.\n";
		print "Your graphical output will not include aminoacid names and color codes according to conservation scores...\n";
		$fasta = "";
	}
}

my @fasta_array = ();
if ($fasta =~ /.*[.]txt/) {
	while (<$fastafile>) {
		if ($_ =~ /.*[>]+.*/ || $_ =~ /.*[|.;]+.*/ || $_ !~ /^[ARNDBCQEZGHILKMFPSTWYVarndbcqezghilkmfpstwyv]+\s*$/) {
		} else {
		chomp $_;
		my @splitted = split ("",$_);
		push  (@fasta_array, @splitted);
		}
	}
}

my %stringency = ("vvl" => [0.5, 2.5, 100], "vl" => [1, 5, 250], "l" => [1.5, 10, 500], "m" => [2, 15, 1000], "h" => [2.5, 20, 1500], "vh" => [3, 25, 2000], "vvh" => [6, 50, 4000]);
my $stringency_argument;
my @stringency_parameters;
my $phase1_stdev;
my $phase2_stdev;
my $loop_limit;
if ((defined $ARGV[3])&&($ARGV[3] =~ /^-(([Mm]{1})|([Vv]?[Vv]?[LlHh]{1}))\/(([Mm]{1})|([Vv]?[Vv]?[LlHh]{1}))\/(([Mm]{1})|([Vv]?[Vv]?[LlHh]{1}))$/)) {
	chomp $ARGV[3];
	$stringency_argument = $ARGV[3];
	$stringency_argument =~ s/V/v/g;
	$stringency_argument =~ s/L/l/g;
	$stringency_argument =~ s/H/h/g;
	$stringency_argument =~ s/M/m/g;
	$stringency_argument =~ s/-//g;
	@stringency_parameters = split ("/",$stringency_argument);
	$phase1_stdev = ${$stringency{$stringency_parameters[0]}}[0];
	$phase2_stdev = ${$stringency{$stringency_parameters[1]}}[1];
	$loop_limit = ${$stringency{$stringency_parameters[2]}}[2];
} elsif ((defined $ARGV[3])&&($ARGV[3] =~ /^-(([0-9]+)|([0-9]+[.]{1}[0-9]+))\/(([0-9]+)|([0-9]+[.]{1}[0-9]+))\/(([0-9]+)|([0-9]+[.]{1}[0-9]+))$/)) {
	$stringency_argument = $ARGV[3];
	$stringency_argument =~ s/-//g;
	@stringency_parameters = split ("/",$stringency_argument);
	$phase1_stdev = $stringency_parameters[0];
	#There is a bug here from the if statement if you were to remove the sprintf function while testing if phase 1 parameter is a multiple of 0.1, for some legitimate numbers the inequality somehow holds true...That's why I used the sprintf there...
	#print $phase1_stdev." ".sprintf("%.1f",$phase1_stdev/0.1)." ".sprintf("%.1f",int($phase1_stdev*10))."\n";
	$phase2_stdev = $stringency_parameters[1];
	$loop_limit = $stringency_parameters[2];
	if((sprintf("%.1f",$phase1_stdev/0.1) != sprintf("%.1f",int($phase1_stdev*10))) || ($phase2_stdev != int($phase2_stdev)) || ($loop_limit != int($loop_limit))) {
	print "Your stringency parameters are not defined properly. Phase 1 parameter should be a multiple of 0.1.\nPhase 2 and loop limit parameters should be integers.\nRedirecting...\n";
	goto REDEFINE_STRINGENCY;
	}
} else {
	REDEFINE_STRINGENCY:
	stringency ();
}

my $refine_answer;
my $refine_counter = 0;
my $refine_counter_limit;
if ((defined $ARGV[4])&&($ARGV[4] =~ /^-refine_.+$/)) {
	$refine_answer = $ARGV[4];
	$refine_answer =~ s/-refine_//g;
	if ($refine_answer =~ /[Oo][Nn]/) {
		$refine_answer = "on";
		$refine_counter_limit = 11;
		print "Refined mod on. Grand iteration limit is $refine_counter_limit\n";
	} elsif ($refine_answer =~ /^([2-9]{1}\s*\t*)|([1-9]+[0-9]+\s*\t*)$/) {
		chomp $refine_answer;
		$refine_counter_limit = $refine_answer;
		$refine_answer = "on";
		print "Refined mod on. Grand iteration limit is $refine_counter_limit\n";
	} else {
		print "Parameter is not clear or set to off. Refined mod off...\n";
		$refine_answer = "off";
	}
} else {
	print "Would you like to run in refined mode?\nThis mode will execute iteration process n times to\nminimize non-specific signals...[y/n]\n";
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^[yY].*/) {
		print "Refined mod on...What would be your limit?[Enter a number bigger than or equal to 2]\n";
		$refine_answer = "on";
		$_ = <STDIN>;
		chomp $_;
		$refine_counter_limit = $_;
		print "Grand iteration limit is $refine_counter_limit\n";
	} else {
		print "Refined mod off...\n";
		$refine_answer = "off";
	}
}

my @reference;
my @test;
print "If this is the first time you are entering reference and test files to iterator,\nyou are advised to take a look at page 16 of MODICT documentation for the rationale...\n";
list_creation ("reference");
list_creation ("test");
print "Starting random iterations. Please be patient...\n";

my %refine_dataset;
REFINE:
if ($refine_answer =~ /on/) {
	print "Initializing grand iteration ". ($refine_counter+1) ."...\n";
}

my @test_values = ();
my @reference_values = ();
my $mean_test = 0;
my $mean_reference = 0;
my $iterations = 0;
my @control_n_benign = ();
my $mean = 0;
my $stdev = 0;
my $stdev_mean = 0;
#
my $threshold = $phase1_stdev*$stdev;
my $threshold_counter = 0;
until (($mean_test >= ($mean+$threshold))&&($iterations>2000)&&((grep {$reference_values[$_] > $mean_test} 0..$#reference_values) == 0)) {
	@test_values = ();
	my $i = 0;
	until ($i == scalar (@test)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$test[$i], "--conservation=".$conservation, "--weight=-", "--mode=-iterate", "--path=".$PATH);
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		push (@test_values, $value);
		$i++;
	}
	$mean_test = take_mean(@test_values);
	
	@reference_values = ();
	$i = 0;
	until ($i == scalar (@reference)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$reference[$i], "--conservation=".$conservation, "--weight=-iterate_MODICT.txt", "--mode=-", "--path=".$PATH);
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		push (@reference_values, $value);
		push (@control_n_benign, $value);
		$i++;
	}
	$mean_reference = take_mean(@reference_values);
	
	$mean = ($iterations*$mean + $mean_reference)/($iterations+1);
	$stdev = standard_deviation(@control_n_benign);
	#
	$threshold = $phase1_stdev*$stdev-$threshold_counter*0.1*$stdev;
	$stdev_mean = $stdev/(scalar(@control_n_benign)**(1/2));
	
	$iterations++;
	
	if (($iterations != 0)&&($iterations % 100 == 0)) {
		print "$iterations iterations complete!\n";
	}
#I WOULD NORMALLY PREVENT THE THRESHOLD FROM FALLING BELOW 0.5 STDEV BUT I LEAVE IT HERE AT 0 STDEV. THE PROGRAM WILL KEEP DECREASING THE THRESHOLD UNTIL THE VALUE IS MET...
	if (($iterations > 2500)&&($iterations % 1000 == 0)&&($threshold != 0*$stdev)) {
	#
		print "Target ".($phase1_stdev-$threshold_counter*0.1)."SD couldn't be reached after $iterations iterations...Lowering threshold by 0.1SD!\n";
		$threshold_counter++;
	}
	if (($iterations % 50000 == 0)&&($threshold > 1*$stdev)) {
		print "50000 iterations have been performed! Setting threshold to 1 SD...\n";
		$phase1_stdev = 1;
		$threshold_counter = 0;
	}
	if ($threshold == 0) {
		print "Target test mean is still smaller than reference sample mean after setting threshold to 0!\nBreaking out of loop and continuing to phase 2...\n";
		last;
	}
}
#
my $record_old = $phase1_stdev-$threshold_counter*0.1;
print $phase1_stdev-$threshold_counter*0.1."SD target reached after $iterations iterations...\n";
print "Your last test mean value: ".$mean_test."\n"."Your last reference mean value: ".$mean_reference."\n"."Your reference sample mean value: ".$mean."\n"."Your standard deviation of reference samples: ".$stdev."\n"."Your standard deviation of the reference sample mean: ".$stdev_mean."\n";
print "Ratio of last test to last reference scores: ".sprintf("%.2f",($mean_test/$mean_reference))."\n";
print "Altering iteration algorithm and maximizing SD difference. Please be patient...\n";
print "Fixing reference sample mean and standard deviation of the reference sample mean...\n";
my $stdev_fixed = $stdev;
my $mean_fixed = $mean + 3*$stdev_mean;


#Number of iterations might be referred in studies later on. I decided not to reset this value when the algorithm swaps.
#$iterations = 0;
my @switch = qw(0 1);
my $j = 0;
my $threshold_constant = $phase2_stdev;
my $loop_count = 0;
$threshold_counter = 0;
$threshold = $threshold_constant*$stdev;
my $record = ($mean_test - $mean_fixed)/$stdev_fixed;
my $ratio = ($mean_test/$mean_reference);
my $ratio_old = $ratio;
my $signal = $switch[($j % 2)];
my @records = ();
push (@records, $record);
push (@records, $ratio);
until ((sprintf("%.1f", $records[0]) >= ($threshold/$stdev)) || $loop_count >= $loop_limit) {
	#$record = ($mean_test - $mean)/$stdev;
	#push (@records, $record);
	@test_values = ();
	my $i = 0;
	until ($i == scalar (@test)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$test[$i], "--conservation=".$conservation, "--weight=-", "--mode=-iterate_evolve", "--path=".$PATH, "--signal=".$signal);
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		push (@test_values, $value);
		$i++;
	}
	$mean_test = take_mean(@test_values);
	
	@reference_values = ();
	$i = 0;
	until ($i == scalar (@reference)) {
		my $results;
		if ($signal == 0) {
			$results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$reference[$i], "--conservation=".$conservation, "--weight=-iterate_MODICT_trial.txt", "--mode=-", "--path=".$PATH);
		} elsif ($signal == 1) {
			$results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$reference[$i], "--conservation=".$conservation, "--weight=-iterate_MODICT.txt", "--mode=-", "--path=".$PATH);
		}
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		push (@reference_values, $value);
		push (@control_n_benign, $value);
		$i++;
	}
	$mean_reference = take_mean(@reference_values);
	
	$mean = ($iterations*$mean + $mean_reference)/($iterations+1);
	$stdev = standard_deviation(@control_n_benign);
	$threshold = $threshold_constant*$stdev-$threshold_counter*0.05*$stdev;
	$stdev_mean = $stdev/(scalar(@control_n_benign)**(1/2));
	
	$iterations++;
	
	if(((($mean_test - $mean_fixed)/$stdev_fixed) > $record)&&(($mean_test/$mean_reference) > $ratio)&&(sprintf("%.1f",(($mean_test - $mean_fixed)/$stdev_fixed)) > 2)) {
		print sprintf("%.2f",$threshold_constant-$threshold_counter*0.05 -(($mean_test - $mean_fixed)/$stdev_fixed))." standard deviations left to ".($threshold_constant-$threshold_counter*0.05)."SD difference!\n";
	}
	
	if ((($mean_test - $mean_fixed)/$stdev_fixed > $records[0])&&(($mean_test/$mean_reference) > $records[1])) {
		$record = ($mean_test - $mean_fixed)/$stdev_fixed;
		$ratio = ($mean_test/$mean_reference);
		pop (@records);
		pop (@records);
		push (@records, $record);
		push (@records, $ratio);
		$j++;
		$loop_count = 0;
		$signal = $switch[($j % 2)];
		print "Loop changed!\n";
	} else {
		$signal = $switch[($j % 2)];
	}
	
	#BELOW LINES WERE TRIVIAL-disregard
	#if (((sprintf("%.1f",(($mean_test - $mean)/$stdev))- $record)>= 0.1)&&(((($mean_test - $mean)/$stdev) - $record) >= 0.05 )) {
	#	if ($signal == 9) {
	#	} else {
	#	print "SD difference improved around 0.1SD...\n";
	#	#$signal++;
	#	}
	#}
	
	#if (((sprintf("%.1f",(($mean_test - $mean)/$stdev))- $record)<= 0)&&(($record - (($mean_test - $mean)/$stdev)) >= 0.05 )) {
	#	if ($signal == 0) {
	#	} else {
	#	print "SD difference dropped...\n";
	#	#$signal--;
	#	}
	#}
	
	if (($iterations != 0)&&($iterations % 100 == 0)) {
		print "$iterations iterations complete!\n";
	}
	
	if (($iterations > 0)&&($iterations % 500 == 0)&&($threshold != 2*$stdev)&&($loop_count >= 500)) {
		print "Target ".($threshold_constant-$threshold_counter*0.05)."SD couldn't be reached after $iterations iterations...Lowering threshold by 0.05SD!\n";
		$threshold_counter++;
	}
	
	if ($iterations >= 100000) {
		print "You have performed 100000 iterations!\n";
		exit;
	}
	
	$loop_count++;
}

#print $threshold_constant-$threshold_counter*0.05."SD target reached after $iterations iterations...\n";
print sprintf("%.2f", $records[0])."SD target reached after $iterations iterations...\n";

my $k = 0;
if ($signal == 1) {
	until ($k == scalar (@test)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$test[$k], "--conservation=".$conservation, "--weight=-iterate_MODICT_trial.txt", "--mode=-", "--path=-");
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		if (($k+1)==1) {
			print "Your ".($k+1)."st positive control score: ".$value."\n";
		} elsif (($k+1)==2) {
			print "Your ".($k+1)."nd positive control score: ".$value."\n";
		} elsif (($k+1)==3) {
			print "Your ".($k+1)."rd positive control score: ".$value."\n";
		} else {
			print "Your ".($k+1)."th positive control score: ".$value."\n";
		}
		$k++;
	}
} elsif ($signal == 0) {
	until ($k == scalar (@test)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$test[$k], "--conservation=".$conservation, "--weight=-iterate_MODICT.txt", "--mode=-", "--path=-");
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		if (($k+1)==1) {
			print "Your ".($k+1)."st positive control score: ".$value."\n";
		} elsif (($k+1)==2) {
			print "Your ".($k+1)."nd positive control score: ".$value."\n";
		} elsif (($k+1)==3) {
			print "Your ".($k+1)."rd positive control score: ".$value."\n";
		} else {
			print "Your ".($k+1)."th positive control score: ".$value."\n";
		}
		$k++;
	}
}
print "The last score of reference sample mean: ".$mean."\n";
print "The last standard deviation of sample reference scores is :".$stdev."\n";
#print "The records[0] is: ".$records[0]."\n";
print "The ratio is improved by: ".sprintf("%.2f",($ratio/$ratio_old))." fold!\n";
print "The SD is improved by: ".sprintf("%.2f",($record-$record_old))."SD!\n";

$k = 0;
if ($signal == 1) {
	until ($k == scalar (@reference)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$reference[$k], "--conservation=".$conservation, "--weight=-iterate_MODICT_trial.txt", "--mode=-", "--path=-");
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		if (($k+1)==1) {
			print "Your ".($k+1)."st negative control score: ".$value."\n";
		} elsif (($k+1)==2) {
			print "Your ".($k+1)."nd negative control score: ".$value."\n";
		} elsif (($k+1)==3) {
			print "Your ".($k+1)."rd negative control score: ".$value."\n";
		} else {
			print "Your ".($k+1)."th negative control score: ".$value."\n";
		}
		$k++;
	}
} elsif ($signal == 0) {
	until ($k == scalar (@reference)) {
		my $results = capture($^X, "./$which_MODICT", "--eventlistener=off", "--automiser=on", "--input=".$reference[$k], "--conservation=".$conservation, "--weight=-iterate_MODICT.txt", "--mode=-", "--path=-");
		my @output = split (/\n/, $results);
		my $value = $output[$#output];
		chomp $value;
		if (($k+1)==1) {
			print "Your ".($k+1)."st negative control score: ".$value."\n";
		} elsif (($k+1)==2) {
			print "Your ".($k+1)."nd negative control score: ".$value."\n";
		} elsif (($k+1)==3) {
			print "Your ".($k+1)."rd negative control score: ".$value."\n";
		} else {
			print "Your ".($k+1)."th negative control score: ".$value."\n";
		}
		$k++;
	}
}
#print "signal: ".$signal."\n";

if ($signal == 0) {
	copy ("$PATH_domestic/Essentials/Iterate_MODICT.txt","$PATH_domestic/Output/Iterator_results.txt") or  die "Copy of iterator results failed!..\n";
} elsif ($signal == 1) {
	copy ("$PATH_domestic/Essentials/Iterate_MODICT_trial.txt","$PATH_domestic/Output/Iterator_results.txt") or  die "Copy of iterator results failed!..\n";
}

my @iterator_results = ();
open(my $iterator_result_file, '<',"$PATH_domestic/Output/Iterator_results.txt") or die "Cannot open iterator result file!\n";
while (<$iterator_result_file>) {
	chomp $_;
	push (@iterator_results,$_);
}

if (($refine_answer =~ /on/)&&($refine_counter < $refine_counter_limit)) {
	my $file_number = $refine_counter + 1;
	move ("$PATH_domestic/Essentials/Iterate_MODICT.txt","$PATH_domestic/Essentials/Dump/Iterate_MODICT_$file_number.txt") or  die "Move of iterator results failed!..\n";
	move ("$PATH_domestic/Essentials/Iterate_MODICT_trial.txt","$PATH_domestic/Essentials/Dump/Iterator_MODICT_trial_$file_number.txt") or  die "Move of iterator results failed!..\n";
	$refine_counter++;
	my $counter = 0;
	until ($counter == scalar (@iterator_results)) {
		push (@{$refine_dataset{$counter}},$iterator_results[$counter]);
		$counter++;
	}
	if ($refine_counter == $refine_counter_limit) {
	} else {
		goto REFINE;
	}
}
if ($refine_answer =~ /on/) {
	open(my $iterator_result_file, '>',"$PATH_domestic/Output/Iterator_results.txt") or die "Cannot open iterator result file!\n";
	for (my $i = 0;$i < scalar (@iterator_results);$i++) {
		my $min = take_min(@{$refine_dataset{$i}});
		my $max = take_max(@{$refine_dataset{$i}});
		my $mean  = take_mean(@{$refine_dataset{$i}});
		my $difference = abs($min - $max);
		if($min == 0){
			print $iterator_result_file 0 ."\n";
		} elsif ($difference/$min > 0.25) {
			print $iterator_result_file 0 ."\n";
		} else {
			print $iterator_result_file $mean."\n";
		}
	}
} 
if ($refine_answer =~ /on/) {
	@iterator_results = ();
	open(my $iterator_result_file, '<',"$PATH_domestic/Output/Iterator_results.txt") or die "Cannot open iterator result file!\n";
	while (<$iterator_result_file>) {
		chomp $_;
		push (@iterator_results,$_);
	}
}


if (($#fasta_array == $#conservation_array)&&((($#fasta_array != 0)&&($#conservation_array != 0)))) {
	print "Your conservation and fasta files looks in phase...Continuing...\n";
} elsif (($#fasta_array != 0)&&($#conservation_array != 0)&&($#fasta_array != -1)) {
	print "You need to check your conservation and fasta files and see if they contain the same number of elements...\nContinuing...\n";
} elsif ($#fasta_array == -1) {
	print "You have not specified a fasta file. Some information will be missing in the graphical output...\n";
}


#HERE THE ITERATOR WILL EXTRACT THE DOMAIN INFORMATION FROM ..ESSENTIALS FOLDER AND PLOT THE THE DOMAINS ON THE X-AXIS
print "Extracting domain anotation...\n";
open(my $eventlistener_file, '<',"$PATH_domestic/Essentials/essentials_MODICT.txt") or die "Cannot open the file of answers!\n";
my @domains;
while (<$eventlistener_file>) {
		if ($_ =~ /^[0-9]+\s*$/) {
			chomp $_;
			push (@domains, $_);
		} elsif ($_ =~ /no/) {
			last;
		}
}
#You check below if the file is read correctly and have the correct number of elements
#print @domains."\n";
my @domain_array;
my $m = 0;
until ( $m == scalar (@domains)) {
	if ($m % 2 == 0) {
#you have to add a small number 0.1 below to force the rounding correctly work...
		my  @array = ((sprintf("%.0f",$domains[$m]/2+0.1)-1)..(sprintf("%.0f",$domains[$m+1]/2+0.1)-1));
		push (@domain_array, @array);
		$m++;
	} else {
		$m++;
	}
}
#my $output = join("\n",@domain_array);
#open(my $test_output, '>',"$PATH_domestic/Output/this_is_a_test.txt") or die "Cannot open the file!\n";
#print $test_output $output;


print "Parsing the aminoacid data...\n";
my $line = "var dataset_score = [";
for ( my $i = 0; $i < scalar (@iterator_results); $i++) {
	my $element = "";
	$element = $element."["."'".$iterator_results[$i]."', ";
	if (($#fasta_array != 0) && ($#fasta_array/$#iterator_results >= 2)) {
		$element = $element."'".$fasta_array[2*$i]."', '".$fasta_array[2*$i+1]."', ";
	} else {
		$element = $element."'"."X"."', '"."X"."', ";
	}
	if (($#conservation_array != 0) && ($#conservation_array/$#iterator_results >= 2)) {
		$element = $element."'".sprintf ("%.1f",(($conservation_array[2*$i]+$conservation_array[2*$i+1])/2))."', ";
	} else {
		$element = $element."'"."1"."', ";
	}
	if ($i ~~ @domain_array) {
		$element = $element."'"."1"."']";
	} else {
		$element = $element."'"."0"."']";
	}
	if ($i == scalar (@iterator_results) - 1) {
	} else {
		$element = $element.", ";
	}
	$line = $line.$element;
}
$line = $line."];";

print "Creating graphical representation...\n";
open(my $templatefile, '<',"$PATH_domestic/Essentials/Template.html") or die "Cannot open template file!\n";
open(my $graphfile, '>',"$PATH_domestic/Output/Graphical_Output.html") or die "Cannot open graphical output file!\n";
while (<$templatefile>) {
	my $line_local = $_;
	if ($line_local =~ /var dataset_score =/) {
		$line_local = $line;
	}
	print $graphfile $line_local."\n";
}

print "You can find your results in ../Output/.\nThank you and goodbye...\n";

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

sub list_creation {
	if ($_[0] eq "reference") {
		print "Please type the name of your reference file with the extention...[Ex: wildtype.txt]\n";
		RETRY_reference:
		$_ = <STDIN>;
		chomp $_;
		if (($_ =~ /(^[Nn][Oo]*$)|(^[Yy][Ee]*[Ss]*$)/) || ($_ !~ /[.]txt/)) {
			print "That's not a valid file name. Retry...\n";
			goto RETRY_reference;
		}
		push (@reference, $_);
	} elsif ($_[0] eq "test") {
		print "Please type the name of your test file with the extention...[Ex: mutated.txt]\n";
		RETRY_test:
		$_ = <STDIN>;
		chomp $_;
		if (($_ =~ /(^[Nn][Oo]*$)|(^[Yy][Ee]*[Ss]*$)/) || ($_ !~ /[.]txt/)) {
			print "That's not a valid file name. Retry...\n";
			goto RETRY_test;
		}
		push (@test, $_);
	}
	if ($_[0] eq "reference") {
		print "Are there more reference files...[y/n]\n";
		$_ = <STDIN>;
		chomp $_;
		if ((($_ =~ /^n.*/) || ($_ !~ /^[yY].*/)) && (scalar(@reference) == 1)) {
			print "You must supply at least 2 reference models.\nIf you are only comparing a wildtype and a mutated protein,\nenter your mutated protein in reference section as well as the test section.\n";
			list_creation ("reference");
		} else {
			until (($_ =~ /^n.*/) || ($_ !~ /^[yY].*/)) {
				list_creation ("reference");
			}
		}
	} elsif ($_[0] eq "test") {
		print "Are there more test files...[y/n]\n";
		$_ = <STDIN>;
		chomp $_;
		until (($_ =~ /^n.*/) || ($_ !~ /^[yY].*/)) {
			list_creation ("test");
		}
	}
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

sub stringency {
	print "MODICT follows a 2 phase approach to iterations with a trial(loop) limit.\nStringency parameter can be m (medium), l (low) or h (high)\npreceded by 0 to 2 v (very).\nEtc. vvl, vh, m...\nYou can also use bare numbers such as 1.5, 2 etc...\nPlease enter the stringency of first phase...\n";
	RETRY1:
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^([Mm]{1})|([Vv]?[Vv]?[LlHh]{1})$/) {
		print "Value accepted...\n";
		$_ =~ s/V/v/g;
		$_ =~ s/L/l/g;
		$_ =~ s/H/h/g;
		$_ =~ s/M/m/g;
		$phase1_stdev = ${$stringency{$_}}[0];
	} elsif (($_ =~ /^(([0-9]+)|([0-9]+[.]{1}[0-9]+))$/) && ($_/0.1 == int($_*10))) {
		print "Value accepted...\n";
		$phase1_stdev = $_;
	} else {
		print "Value is not accepted! Please retry...\n";
		goto RETRY1;
	}
	print "Please enter the stringency of second phase...\n";
	RETRY2:
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^([Mm]{1})|([Vv]?[Vv]?[LlHh]{1})$/) {
		print "Value accepted...\n";
		$_ =~ s/V/v/g;
		$_ =~ s/L/l/g;
		$_ =~ s/H/h/g;
		$_ =~ s/M/m/g;
		$phase2_stdev = ${$stringency{$_}}[1];
	} elsif (($_ =~ /^(([0-9]+)|([0-9]+[.]{1}[0-9]+))$/) && ($_ == int($_))) {
		print "Value accepted...\n";
		$phase2_stdev = $_;
	} else {
		print "Value is not accepted! Please retry...\n";
		goto RETRY2;
	}
	print "Please enter the loop limit. The higher this limit is, the more iterator will look for better alternatives.\nThe default value is 1000 iterations...\n";
	RETRY3:
	$_ = <STDIN>;
	chomp $_;
	if ($_ =~ /^([Mm]{1})|([Vv]?[Vv]?[LlHh]{1})$/) {
		print "Value accepted...\n";
		$_ =~ s/V/v/g;
		$_ =~ s/L/l/g;
		$_ =~ s/H/h/g;
		$_ =~ s/M/m/g;
		$loop_limit = ${$stringency{$_}}[2];
	} elsif (($_ =~ /^(([0-9]+)|([0-9]+[.]{1}[0-9]+))$/) && ($_ == int($_))) {
		print "Value accepted...\n";
		$loop_limit = $_;
	} else {
		print "Value is not accepted! Please retry...\n";
		goto RETRY3;
	}
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
my $argv_4 = "";
my $argv_5 = "";
#Use the getoptions module.
GetOptions ("path=s" => \$argv_0, "conservation=s" => \$argv_1, "fasta=s" => \$argv_2, "stringency=s" => \$argv_3, "refine=s" => \$argv_4, "need=s" => \$argv_5) or die ("Error parsing the command line arguments!\n");
#add the prefix to refine mod.
$argv_4 = "-refine_".$argv_4;
#Form an hash that keeps all of the references to raw arguments chopped from GetOptions. If they already come with dashes, dashes will not be added. This is crucial for inter-script interactions. For refine mod we know that this is already not the case.
my %raw_argv = ("path" => \$argv_0, "conservation" => \$argv_1, "fasta" => \$argv_2, "stringency" => \$argv_3, "refine" => \$argv_4, "need" => \$argv_5);
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
my %extentions = ("conservation" => \$argv_1, "fasta" => \$argv_2);
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
if (($argv_5 =~ /^-[vV]{1}$/) || ($argv_5 =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/) || ($argv_5 =~ /^-[hH]{1}$/) || ($argv_5 =~ /^-[Hh][Ee][Ll][Pp]$/)) {
	push (@ARGV, $argv_5);
} elsif (($argv_4 eq "-refine_")&&($argv_0 eq "-")&&($argv_1 eq "-")&&($argv_2 eq "-")&&($argv_3 eq "-")) {
	print "You did not define any parameters. Entering QA mode...\n";
} elsif ($argv_4 eq "-refine_") {
	print "You must define the refine parameter either as off or on or a number between 2-11...\n";
	print "Entering QA mode...\n";
} else {
	print "Your parameters are taken...\n\n";
	push (@ARGV, $argv_0);
	push (@ARGV, $argv_1);
	push (@ARGV, $argv_2);
	push (@ARGV, $argv_3);
	push (@ARGV, $argv_4);
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