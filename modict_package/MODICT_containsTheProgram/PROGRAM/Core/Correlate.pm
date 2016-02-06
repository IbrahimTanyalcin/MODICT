#!/usr/bin/perl
package Core::Correlate;
use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(correlate);

sub correlate {
	my @X_values = @{$_[0]};
	my @Y_values = @{$_[1]};
	my $X_stdev = standard_deviation(@X_values);
	my $Y_stdev = standard_deviation(@Y_values);
	my $XY_cov = covariance(\@X_values,\@Y_values);
	my $correlation = $XY_cov/($X_stdev*$Y_stdev);
	return $correlation;
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

sub covariance {
	my @X_values = @{$_[0]};
	my @Y_values = @{$_[1]};
	my $X_mean = take_mean(@X_values);
	my $Y_mean = take_mean(@Y_values);
	my $N = (scalar(@X_values)+scalar(@Y_values))/2;
	my $covariance = 0;
	for (my $i = 0;$i<$N;$i++) {
		my $element = (($X_values[$i]-$X_mean)*($Y_values[$i]-$Y_mean))/($N-1);
		$covariance += $element;
	}
	return $covariance;
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

"Omnia fui, nihil expedit";
