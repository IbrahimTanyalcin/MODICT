#!/usr/bin/perl
use strict;
use warnings;

print "Welcome to MODICT tester\nThis script will plot a ROC curve for the given model data...\nWhat is your input file name?\n";
my $input_file_name = <STDIN>;
chomp $input_file_name;
my $PATH;
if ((defined $ARGV[0])&&($ARGV[0] =~ /.*\/.*/)) {
	$ARGV[0] =~ s/-//g;
	$PATH = $ARGV[0];
	chomp $PATH;
} else {
	$PATH = "..";
}
open (my $input_file, '<', "$PATH/ROC/$input_file_name") or die ("Cannot open the specified input file!\n");
open (my $output_file, '>', "$PATH/ROC/output_ROC.txt") or die ("Cannot open the specified output file!\n");
print "Skip header?[y/n]\n";
my $skip_answer = <STDIN>;
chomp $skip_answer;
if ($skip_answer =~ /^y.*/) {
	print "How many header lines does your input file contain?[enter a number]\n";
	my $count = <STDIN>;
	chomp $count;
	my $i = 0;
	until ($i == $count) {
		skip_header( $input_file);
		$i++;
	}
} else {
}

print "Forming dataset...\n";
my %dataset;

my $set_id = 0;
my $number_negatives = 0;
my $number_positives = 0;
my $number_partials = 0;
while (<$input_file>) {
	chomp $_;
	my @splitted = split (/\t/,$_);
	if ($splitted[3] =~ /delete/) {
		$number_positives++;
	} elsif ($splitted[3] =~ /benign/) {
		$number_negatives++;
	} elsif ($splitted[3] =~ /partial/) {
		$number_partials++;
	}
	my $identifier = "set".$set_id;
	@{$dataset{$identifier}} = @splitted;
	$set_id++;
}
print "Dataset parsed...\n";

print "Starting stringecy calculation...\n";
print $output_file "stringency"."\t"."P-Value"."\t"."Accuracy"."\t"."sensitivity"."\t"."specificity"."\t"."true-partials"."\n";
my $i = 0;
my $j = 0;
my $threshold_y = 100-$i;
my $threshold_x = 100-$j;
my $stringency = take_mean($threshold_y,$threshold_x);
until (($threshold_y < 0) && ($threshold_x < 0)) {
	print "$i percent complete!\n";
	my $score_positives = 0;
	my $score_negatives = 0;
	my $score_partials = 0;
	my $false_positives = 0;
	my $false_negatives = 0;
	my $false_nonpartials = 0;
	foreach my $element (keys %dataset) {
		if (${$dataset{$element}}[3] =~ /deleterious/) {
			if (${$dataset{$element}}[4] =~ /benign/) {
				my $mean = take_mean(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				my $stdev = standard_deviation(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				if (${$dataset{$element}}[2] >= ($mean+$threshold_y/100*3*$stdev)) {
					$score_positives++;
				} else {
					$false_negatives++;
				}
			} elsif (${$dataset{$element}}[4] =~ /deleterious/) {
				my $imaginary_benign = (2*${$dataset{$element}}[1] + (3*sqrt(2)-1)* ${$dataset{$element}}[0])/(3*sqrt(2)+1);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] >= ($mean+$threshold_y/100*3*$stdev)) {
					$score_positives++;
				} else {
					$false_negatives++;
				}
			} elsif (${$dataset{$element}}[4] =~ /partial/) {
				my $imaginary_benign = (4*${$dataset{$element}}[1] + (3*sqrt(2)-2)* ${$dataset{$element}}[0])/(3*sqrt(2)+2);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] >= ($mean+$threshold_y/100*3*$stdev)) {
					$score_positives++;
				} else {
					$false_negatives++;
				}
			}
		} elsif (${$dataset{$element}}[3] =~ /benign/) {
			if (${$dataset{$element}}[4] =~ /deleterious/) {
				my $imaginary_benign = (2*${$dataset{$element}}[1] + (3*sqrt(2)-1)* ${$dataset{$element}}[0])/(3*sqrt(2)+1);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] <= ($mean+(100 - $threshold_x)/100*3*$stdev)) {
					$score_negatives++;
				} else {
					$false_positives++;
				}
			} elsif (${$dataset{$element}}[4] =~ /partial/) {
				my $imaginary_benign = (4*${$dataset{$element}}[1] + (3*sqrt(2)-2)* ${$dataset{$element}}[0])/(3*sqrt(2)+2);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] <= ($mean+(100 - $threshold_x)/100*3*$stdev)) {
					$score_negatives++;
				} else {
					$false_positives++;
				}
			} elsif (${$dataset{$element}}[4] =~ /benign/) {
				my $mean = take_mean(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				my $stdev = standard_deviation(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				if (${$dataset{$element}}[2] <= ($mean+(100 - $threshold_x)/100*3*$stdev)) {
					$score_negatives++;
				} else {
					$false_positives++;
				}
			}
		} elsif (${$dataset{$element}}[3] =~ /partial/) {
			if (${$dataset{$element}}[4] =~ /benign/) {
				my $mean = take_mean(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				my $stdev = standard_deviation(${$dataset{$element}}[0],${$dataset{$element}}[1]);
				if (${$dataset{$element}}[2] >= ($mean+$stringency/100*3/2*$stdev)) {
					$score_partials++;
				} else {
					$false_nonpartials++;
				}
			} elsif (${$dataset{$element}}[4] =~ /deleterious/) {
				my $imaginary_benign = (2*${$dataset{$element}}[1] + (3*sqrt(2)-1)* ${$dataset{$element}}[0])/(3*sqrt(2)+1);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] >= ($mean+$stringency/100*3/2*$stdev)) {
					$score_partials++;
				} else {
					$false_nonpartials++;
				}
			} elsif (${$dataset{$element}}[4] =~ /partial/) {
				my $imaginary_benign = (4*${$dataset{$element}}[1] + (3*sqrt(2)-2)* ${$dataset{$element}}[0])/(3*sqrt(2)+2);
				my $mean = take_mean(${$dataset{$element}}[0],$imaginary_benign);
				my $stdev = standard_deviation(${$dataset{$element}}[0],$imaginary_benign);
				if (${$dataset{$element}}[2] >= ($mean+$stringency/100*3/2*$stdev)) {
					$score_partials++;
				} else {
					$false_nonpartials++;
				}
			}
		}
	}
	my $true_positive_rate = sprintf("%.6f",$score_positives/($score_positives + $false_negatives));
	my $true_negative_rate = sprintf("%.6f",$score_negatives/($score_negatives + $false_positives));
	my $true_partial_rate = sprintf("%.6f",$score_partials/($score_partials + $false_nonpartials));
	my $Z_score = $stringency/100*3;
	my $p_value = gaussian_distribution($Z_score);
	my $accuracy = sprintf("%.3f",(($score_positives + $score_negatives + $score_partials)/($number_positives + $number_negatives + $number_partials)));
	print $output_file $stringency."\t".$p_value."\t".$accuracy."\t".$true_positive_rate."\t".$true_negative_rate."\t".$true_partial_rate."\n";
	$i++;
	$j++;
	$threshold_y = 100-$i;
	$threshold_x = 100-$j;
	$stringency = take_mean($threshold_y,$threshold_x);
}
print "Execution finished...\nThank you and goodbye...\n";



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
#If you run the script with the -population argument then 1 is not subtracted from the denominator.
my $correction_sd;
if (grep {$_ =~ /-[Pp][Oo][Pp][Uu][Ll][Aa][Tt][Ii][Oo][Nn]/} @ARGV) {
	$correction_sd = 0;
} else {
	$correction_sd = 1;
}
my $result = ($sum/(scalar (@test_array)-$correction_sd))**(1/2);

#Uncomment below to check if the sub works correctly
#print "The mean here is $mean!\n";
#print "The sum here is $sum!\n";
#my $item_count = scalar (@test_array);
#print "The number of items here is $item_count!\n";

#retrieve the result
#return sprintf ("%.6f",$result)
return $result;
}


sub take_sum {
my @test_array = @_;
my $sum;
for (my $i = 0; $i < scalar (@test_array); $i++) {
	$sum += $test_array[$i]
}
return $sum;
}


sub skip_header {
  my $FH = shift;
  <$FH>;
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

sub gaussian_distribution {
#THE BELOW PART IS TAKEN FROM MODICT.PL
#first get values of the function for steps of 0.001
my @point_values;
#value of pi
my $pi = 3.1415926;
#value of e
my $e = 2.71828182845904523536;
for (my $i = 1; $i < 4001; $i++) {
	push (@point_values, (1/sqrt(2*$pi))*($e**(-1*((($i*0.001)**2))/2)));
}
#Convert the point_values into consecutive paired values to construct rectangles
my @paired_values;
for (my $i = 0; $i < scalar (@point_values)-1; $i++) {
	$_ = ($point_values[$i]+$point_values[$i+1])/2*0.001;
	push (@paired_values, $_);
}
#Now cumulatively add these rectangles. They should be close the half the area of bell curve
my @cumulative_paired_values;
for (my $i = 0; $i < scalar (@paired_values); $i++) {
	if ($i == 0) {
		$_ = $paired_values[$i];
	} else {
		$_ = $paired_values[$i] + $cumulative_paired_values[$i-1];
	}
	push (@cumulative_paired_values, $_)
}
#Uncomment below to see the value if correct
#print "the cumulative value is ".$cumulative_paired_values[0]."\n";

#Complete to whole curve by adding the other half
foreach my $element (@cumulative_paired_values) {
	$element += 0.5;
}

#UNTIL THIS PART THIS SUBROUTINE IS TAKEN FROM MODICT.PL
#Modify each element by subtracting them from 1 to have the p value...

foreach my $element (@cumulative_paired_values) {
	$element = 1 - $element;
}
my $p_value = $cumulative_paired_values[(sprintf("%.3f",$_[0])*1000)];
return sprintf("%.4f",$p_value);
}