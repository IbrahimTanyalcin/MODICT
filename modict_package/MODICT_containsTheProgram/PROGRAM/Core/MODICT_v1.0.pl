#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

print "Welcome to MODICT Beta_v1.0\n";
#Below sub is to retrieve the arguments if any and sort them.
getopt();

if ((grep {$_ =~ /^-[hH]{1}$/} @ARGV)||(grep {$_ =~ /^-[Hh][Ee][Ll][Pp]$/} @ARGV)) {
print "
#IMPORTANT\n
#FOR PEOPLE WHO WANT TO USE MODICT WITH ARGUMENTS, BELOW ARE THE POSSIBLE ARGUMENTS\n
#PREFIXING WITH DOUBLE OR SINGLE DASHES DOES NOT MAKE A DIFFERENCE\n
#1: Eventistener. Keeps track of your answers in QA(question and answer) mode. This step is important for automization later on.\nEx: --eventlistener on OR --eventlistener off\n
#2: Automizer. Retrieves the answers from a previous launch of modict. Only turn this feature on at your second run.\nEx: --automiser on OR --automiser off\n
#3: Input. This is your file with RMSD values in it. Ex: --input yourinputfilename.txt\n
#4: Conservation. Conservation with single value per line. Number of lines must be equal to the aminoacid count of your protein.\nEx: --conservation yourconservationfilename.txt\n
#5: Weight. Weight scores with similar format to conservation. Ex: -weight yourweightscorefilename.txt\n
#6: Mode. You can ask modict to generate a random weight score configuration. This option is normally not for the user.\nEx: --mode iterate\n
#7: Path. Path to modict folder. Ex: --path C:/Desktop/MODICT\n
#8: Signal. This is not for the user. It is a commnunication between iterator and MODICT.\n";
exit;
} else {
}

if ((grep {$_ =~ /^-[vV]{1}$/} @ARGV)||(grep {$_ =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/} @ARGV)) {
	print "Version v1.0\n";
	exit;
} else {
}

my $PATH;
if ((defined $ARGV[6])&&($ARGV[6] =~ /.*\/.*/)) {
	$ARGV[6] =~ s/-//g;
	$PATH = $ARGV[6];
	chomp $PATH;
} else {
	$PATH = "..";
}

my $eventlistener_answer;
if  ((defined $ARGV[0])&&($ARGV[0] =~ /-eventlistener_.*/)) {
	$ARGV[0] =~ s/-eventlistener_//g;
	if ($ARGV[0] =~ /on/) {
	$eventlistener_answer = "yes";
	} else {
	$eventlistener_answer = "no";
	}
} else {
	print "Would you like to turn on the event listener. This step is required to automize later...[y/n]\n";
	$eventlistener_answer = <STDIN>;
	chomp $eventlistener_answer;
	if ($eventlistener_answer =~ /^[yY].*/) {
		print "You will find a list of your answers in ../Essentials folder.\nYou can edit these values here later on.\n";
	}
}
my @eventlistener;

my $automizer_answer;
if ((defined $ARGV[1])&&($ARGV[1] =~ /-automi[sz]er_.*/)) {
	$ARGV[1] =~ s/-automi[sz]er_//g;
	if ($ARGV[1] =~ /on/) {
	$automizer_answer = "yes";
	} else {
	$automizer_answer = "no";
	}
} else {
	print "Would you like to turn on the automizer?\nDo not select yes if this is the first time you are running the program for your protein of choice![y/n]\n";
	$automizer_answer = <STDIN>;
	chomp $automizer_answer;
}
my @automizer;

if ($automizer_answer =~ /^[yY].*/) {
	open (my $output_file, '<', "$PATH/Essentials/essentials_MODICT.txt") or die ("Cannot open the specified automizer file!\n");
	skip_header ($output_file);
	while (<$output_file>) {
	chomp;
	push (@automizer,$_)
	}
}
my $answer_counter = 0;
print "Please specify the name of your .txt file with the RMSD values in ../Input.[Ex: input.txt]\n";
my $input_name = program_mode(\@ARGV);
my $input_path = "$PATH/Input/$input_name";
open (my $input_file, '<', $input_path) or die("Cannot open the specified input file!\n");
open (my $output_file, '>', "$PATH/Output/output_MODICT.txt") or die ("Cannot open the specified output file!\n");
my @input_array;
while (<$input_file>) {
	chomp;
	push (@input_array, $_);
}
my @aa_count;
my $overall_RMSD;
my $forward_counter_input_array = 0;
until (($input_array[$forward_counter_input_array] =~ /[Rr][Mm][Ss][Dd]/)&&($input_array[$forward_counter_input_array] !~ /[Oo][Vv][Ee][Rr][Aa][Ll][Ll][\s_,;|-]?[Rr][Mm][Ss][Dd]/)) {
	if ($input_array[$forward_counter_input_array] =~ /[Gg][Rr][Oo][Uu][Pp][\s_,;|-]?[Cc][Oo][Uu][Nn][Tt]/) {
		push (@aa_count, $input_array[$forward_counter_input_array+1]);
	}
	if ($input_array[$forward_counter_input_array] =~ /[Oo][Vv][Ee][Rr][Aa][Ll][Ll]/) {
		$overall_RMSD = $input_array[$forward_counter_input_array+1];
	}
	shift (@input_array);
}
shift (@input_array);
 my $reverse_counter_input_array = scalar(@input_array)-1;
 until(($input_array[$reverse_counter_input_array] =~ /[Rr][Mm][Ss][Dd]/)&&($input_array[$reverse_counter_input_array] !~ /[Oo][Vv][Ee][Rr][Aa][Ll][Ll][\s_,;|-]?[Rr][Mm][Ss][Dd]/)) {
	if ($input_array[$reverse_counter_input_array-1] =~ /[Gg][Rr][Oo][Uu][Pp][\s_,;|-]?[Cc][Oo][Uu][Nn][Tt]/) {
		push (@aa_count, $input_array[$reverse_counter_input_array]);
	}
	if ($input_array[$reverse_counter_input_array-1] =~ /[Oo][Vv][Ee][Rr][Aa][Ll][Ll]/) {
		$overall_RMSD = $input_array[$reverse_counter_input_array];
	}
	pop (@input_array);
	$reverse_counter_input_array = scalar(@input_array)-1;
}
pop (@input_array);

#CONTROL POINT 1
#my $outputX = join ("\n", @aa_count, @input_array, "\n");
#my $outputX = join ("\n", @input_array, "\n");
#print $output_file $outputX;
#print "Overall RSMD is $overall_RMSD!\n";

my $aa_count_smallest = take_min(@aa_count);

my @domains;
my $domain_count = 1;
print "Please type the start of domain_$domain_count...\n";
RESIDUECAP1:
$_ = program_mode(\@ARGV);
chomp $_;
if ($_ !~ /^[-]?[1-9]{1}[0-9]*$/) {
	print "Only numbers are allowed...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP1;
} elsif ($_ > ($aa_count_smallest-1)) {
	print "You cannot enter a number greater than the maximum residue count - 1, please try again...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP1;
} elsif ($_ <= 0) {
	print "0 or negative numbers are not allowed. Maybe in some other world it is...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP1;
} else {
}
my $last_domain_entry = $_;
push (@domains, $_);
print "Please type the end of domain_$domain_count...\n";
RESIDUECAP2:
$_ = program_mode(\@ARGV);
chomp $_;
if ($_ !~ /^[-]?[1-9]{1}[0-9]*$/) {
	print "Only numbers are allowed...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP2;
} elsif ($_ > $aa_count_smallest) {
	print "You cannot enter a number greater than the maximum residue count, please try again...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP2;
} elsif (($_ - $last_domain_entry) <= 0) {
	print "There must be at least 1 aminoacid difference between domain start and end, please try again...\n";
	$answer_counter--;
	if ($eventlistener_answer =~ /^[yY].*/) {
		pop (@eventlistener);
	}
	goto RESIDUECAP2;
} else {
}
push (@domains, $_);
print "Are there more domains in your protein?[y/n]\n";
my $domain_continue = program_mode(\@ARGV);
chomp $domain_continue;
if ($domain_continue =~ /^[yY].*/) {
	list_creation ($domain_continue);
}

print "The length of your protein is $aa_count_smallest!\n";

#undef $_;
my $Total_Domain_Length;
my $initial_start = 0;
for (my $i = 0; $i < scalar (@domains); $i++) {
	if (($i % 2) == 0) {
		$initial_start -= $domains[$i];
	} elsif ($i == scalar(@domains)-1){
		$initial_start += $domains[$i];
		$Total_Domain_Length = $initial_start + (scalar(@domains)/2);
	} else {
		$initial_start += $domains[$i];
	}
}
#undef $_;

print "The total domain length is $Total_Domain_Length!\n";
my $Total_Domain_Ratio = sprintf("%.12f", ($Total_Domain_Length/$aa_count_smallest));
print  "Domains take up ".($Total_Domain_Ratio*100)." percent of your protein...\n";
my $One_minus_Total_Domain_Ratio;
if ((1-$Total_Domain_Ratio)<=0.5) {
	$One_minus_Total_Domain_Ratio = $Total_Domain_Ratio;
	#print "Your One_minus_Total_Domain_Ratio is $One_minus_Total_Domain_Ratio!\n";
} else {
	$One_minus_Total_Domain_Ratio = 1-$Total_Domain_Ratio;
	#print "Your One_minus_Total_Domain_Ratio is $One_minus_Total_Domain_Ratio!\n";
}
#Uncomment below if you want to check the value
#print "Just to check $One_minus_Total_Domain_Ratio\n";


my $domain_continue_output;
parser (\@domains);
print "Here is your domain configuration:\n$domain_continue_output\n";

$overall_RMSD =~ s/[,;:-_|]/./;
print "Overall RSMD is $overall_RMSD!\n";
my $rmsd_standard_deviation = standard_deviation(@input_array);
print "Standard deviation of your RMSD values is $rmsd_standard_deviation!\n";

print "Please choose a type of distribution to continue analyzing...\n1 for Gaussian, 2 for Poisson and 3 for Weibull\n(Note: For the moment only gaussian available)[Press 1 and enter]\n";
my $distribution_choice = program_mode(\@ARGV);
chomp $distribution_choice;
my $Z_score_threshold;
my @choice_1;
if ($distribution_choice =~ /^1.*$/) {
	@choice_1 = gaussian_distribution($One_minus_Total_Domain_Ratio);
	my $min = take_min(@choice_1);
	my @index = grep {$choice_1[$_] == $min} (0..$#choice_1);
	#Uncomment the below 2 lines to see the values
	#print "Your index is $index[0]!\n";
	#print "Here is your min $min!\n";
	if ((1-$Total_Domain_Ratio)<=0.5){
		$Z_score_threshold = sprintf ("%.3f", -1 * ($index[0]+1) * 0.001);
	} else {
		$Z_score_threshold = sprintf ("%.3f", ($index[0]+1) * 0.001);
	}
} else {
	print "Currently only Gaussian distribution is available...\nContinuing with choice 1...\n";
	@choice_1 = gaussian_distribution($One_minus_Total_Domain_Ratio);
	my $min = take_min(@choice_1);
	my @index = grep {$choice_1[$_] == $min} (0..$#choice_1);
	#Uncomment the below 2 lines to the values
	#print "Your index is $index[0]!\n";
	#print "Here is your min $min!\n";
	if ((1-$Total_Domain_Ratio)<=0.5){
		$Z_score_threshold = sprintf ("%.3f", -1 * ($index[0]+1) * 0.001);
	} else {
		$Z_score_threshold = sprintf ("%.3f", ($index[0]+1) * 0.001);
	}
}
#Below is the Z threshold
print "Your Z-score threshold is $Z_score_threshold!\n";
#Uncomment below to see the contents of the array(s)
#my $output = join ("\n", @choice_1, "\n");
#print $output_file $output;



#CONTROL POINT 2
#my $output = join ("\n", @aa_count,"\n");
#					OR
#my $output = join ("\n", @input_array, "\n");
#
#print $output_file $output;
#print "Overall RSMD is $overall_RMSD!\n";
#take_min(@domains);	

print "MODICT works via calculating area under the RMSD values by creating blocks.\nHow many consequtive amino acids do you want to include per block? (default value: 2)[Press 2 and enter]\n";
my $width = program_mode(\@ARGV);
chomp $width;
print "Each $width amino-acids will be treated as 1 unit...\n";
my @input_array_groupedby_width;
block_iterator1 (@input_array_groupedby_width);

#CONTROL POINT 3
#my $outputX = join ("\n", @input_array_groupedby_width, "\n");
#print $output_file $outputX;

print "Do you have your own Conservation scores?[y/n]\n";
my @conservation_scores;
my @conservation_scores_parsed;
my $conservation_answer = program_mode(\@ARGV);
chomp $conservation_answer;
if (($conservation_answer =~ /^[yY].*/)||((defined $ARGV[3])&&($ARGV[3] =~ /-.*[.]txt/))) {
	print "What is the name of your conservation file?[Ex: conservation.txt]\n";
	my $conservation_file_name = program_mode(\@ARGV, $conservation_answer);
	chomp $conservation_file_name;
	my $conservation_file_path = "$PATH/Input/$conservation_file_name";
	open (my $input_file, '<', $conservation_file_path) or die("Cannot open the specified conservation file!\n");
	while (<$input_file>) {
		chomp $_;
		push(@conservation_scores, $_);
	}
	if (scalar (@conservation_scores) != (scalar (@input_array))) {
		print "Please check your conservation file, it needs to have a score per aminoacid per line...\n";
		exit;
	} else {
		print "You conservation file is ok, continuing with parsing...\n";
		block_iterator2 (@conservation_scores);
		#Uncomment below to check the values
		#my $output = join ("\n", @conservation_scores_parsed, "\n");
		#print $output_file $output;
	}
} else {
	#change here your default value.
	my $score = 1.000;
	print "For all aminoacids a default conservation of $score will be assigned...\n";
	for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
		push (@conservation_scores_parsed, $score);
	}
	#Uncomment below to check the values
	#my $outputX = join ("\n", @conservation_scores_parsed, "\n");
	#print $output_file $outputX;
}

print "Do you have your own weight scores? These are basically arbitrary scores given to residues based on their importance...[y/n]\n";
my @weight_scores;
my @weight_scores_parsed;
my $weight_answer = program_mode(\@ARGV);
chomp $weight_answer;
if (($weight_answer =~ /^[yY].*/)||((defined $ARGV[4])&&($ARGV[4] =~ /-.*[.]txt/))) {
	print "What is the name of your weight score file?[Ex: weight.txt]\n";
	my $weight_file_name = program_mode(\@ARGV, $weight_answer);
	chomp $weight_file_name;
	if (($weight_file_name !~ /iterate_MODICT[.]txt/)&&($weight_file_name !~ /iterate_MODICT_trial[.]txt/)) {
	my $weight_file_path = "$PATH/Input/$weight_file_name";
	open (my $input_file, '<', $weight_file_path) or die("Cannot open the specified weight file!\n");
	while (<$input_file>) {
		chomp $_;
		push(@weight_scores, $_);
	}
	if (scalar (@weight_scores) != (scalar (@input_array))) {
		print "Please check your weight score file, it needs to have a score per aminoacid...\n";
		exit;
	} else {
		print "You weight score file is ok, continuing with parsing...\n";
		block_iterator3 (@weight_scores);
		#Uncomment below to check the values
		#my $output = join ("\n", @weight_scores_parsed, "\n");
		#print $output_file $output;
	}
	} else {
		my $weight_file_path = "$PATH/Essentials/$weight_file_name";
		open (my $input_file, '<', $weight_file_path) or die("Cannot open the specified weight file!\n");
		while (<$input_file>) {
			chomp $_;
			push(@weight_scores, $_);
		}
		@weight_scores_parsed = @weight_scores;
		#Uncomment below to check the values
		#my $outputX = join ("\n", @weight_scores_parsed, "\n");
		#print $output_file $outputX;
	}
} elsif ((defined $ARGV[5])&&($ARGV[5] =~ /-iterate\s*$/)) {
	for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
		my $random_variable = sprintf("%.0f",(rand()*10));
		push (@weight_scores_parsed, $random_variable);
	}
} elsif ((defined $ARGV[5])&&($ARGV[5] =~ /-iterate_evolve\s*$/)) {
	#below lines are trivial additions I would like to experiment with later on.
	#my $signal = $ARGV[7];
	#$signal =~ s/-//g;
	my $signal = $ARGV[7];
	$signal =~ s/-//g;
	my $weight_file_path;
	if ($signal == 0) {
		$weight_file_path = "$PATH/Essentials/iterate_MODICT.txt";
	} elsif ($signal == 1) {
		$weight_file_path = "$PATH/Essentials/iterate_MODICT_trial.txt";
	}
	open (my $input_file, '<', $weight_file_path) or die("Cannot open the specified weight file!\n");
	#my $i = 0;
	#my $trial = $ARGV[8];
	#$trial =~ s/-//g;
	while (<$input_file>) {
		chomp $_;
		#if ($i == $signal) {
		#$_ = $trial;
		#}
		#$i++;
		if (rand() >= 0.1 + abs($_ - 5)/5*0.85) {
			if (rand() <= 0.5 + (sprintf("%.0f",(rand()*10)) - $_)/10) {
				if ( $_ != 0) {
					$_ -= sprintf("%.0f",(rand()*$_/2));
				}
			} 
			if (rand() <= (sprintf("%.0f",(rand()*10))+$_)/20) {
				if ($_ != 10) {
					$_ += sprintf("%.0f",(rand()*(10-$_)/2));
				}
			}
			#$_ += sprintf("%.0f",(rand()*10));
			#$_ = sprintf("%.0f",$_/2);
		} else {
			#$_ += sprintf("%.0f",(rand()*10));
			#$_ = sprintf("%.0f",$_/2);
		}
		push(@weight_scores, $_);
	}
	@weight_scores_parsed = @weight_scores;
}
#VERY IMPORTANT: YOU WILL SEE BELOW THAT THE DEFAULT VALUE IS 1 OR 10. HOWEVER WHEN DOING ITERATIONS, MODICT WILL TRY TO ASSESS WHICH PARTS OF THE MOLECULE IS AFFECTED THE MOST,
#THEREFORE IT IS BETTER TO CHANGE THIS VALUE TO 10. IN THE MODICT PAPER THE DEFAULT VALUES ARE 1 (UPDATED IN PUBLISHED VERSION). WHATEVER VALUE YOU CHOOSE HERE, MAKE SURE THAT YOU STAY CONSISTENT THROUGH OUT YOUR
# CONTROL AND TEST FILES. 
  else {
	#change here your default value.
	my $score = 10;
	print "For all aminoacids a default weight score of $score will be assigned...\n";
	for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
		push (@weight_scores_parsed, $score);
	}
	#Uncomment below to check the values
	#my $output = join ("\n", @weight_scores_parsed, "\n");
	#print $output_file $output;
}
#print "The number of array elements here is:  $#weight_scores_parsed\n";
#print "The number of array elements here is:  $#conservation_scores_parsed\n";

#Create a "Background Signal" array
my @Overall_RMSD_Array;
for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
	push (@Overall_RMSD_Array, $overall_RMSD);
}
#Uncomment below to check the values
#my $output = join ("\n", @Overall_RMSD_Array, "\n");
#print $output_file $output;

#SCALE
Scale(@Overall_RMSD_Array);
#Uncomment below to check the values
#my $output = join ("\n", @Overall_RMSD_Array, "\n");
#print $output_file $output;
Scale(@input_array_groupedby_width);
#Uncomment below to check the values
#my $output = join ("\n", @input_array_groupedby_width, "\n");
#print $output_file $output;

#CREATE A DOMAIN ARRAY
#first a residue count array
my @residue_count_array;
for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
	push (@residue_count_array,(($width*$i)+1));
}
#This array should include all the residue numbers that should account for the calculation. Other residues outside the scope of this array will receive a constant of 0.
my @domain_capture;
my $domain_capture_count = 0;
until ($domain_capture_count == scalar(@domains)) {
	if (($domain_capture_count % 2) == 0) {
		push(@domain_capture, ($domains[$domain_capture_count]..$domains[$domain_capture_count + 1]));
		$domain_capture_count++;
	} else {
		$domain_capture_count++
	}
}
#Uncomment below to check the values
#my $outputX = join ("\n", @domain_capture, "\n");
#print $output_file $outputX;
#Now based on the @domain_capture array we can assign 1 or 0 to the blocks based on whether they are in or out of a domain.
my @Domain_Array;
for (my $i = 0; $i < scalar (@residue_count_array); $i++) {
	if ($residue_count_array[$i] ~~ @domain_capture) {
		push (@Domain_Array,1);
	} else {
		push (@Domain_Array,0);
	}
}
#Uncomment below to check the values
#my $outputX = join ("\n", @Domain_Array, "\n");
#print $output_file $outputX;

#CHECKPOINT
#All arrays that will be used further on should have equal amount of elements
if (($#Overall_RMSD_Array == $#input_array_groupedby_width)&&($#input_array_groupedby_width == $#Domain_Array)&&($#Domain_Array == $#weight_scores_parsed)&&($#weight_scores_parsed ==  $#conservation_scores_parsed)) {
	print "CHECKPOINT: OK...\n"
} else {
	print "There was a problem with the number of array elements necessary for calculation.\nPlease check your weight score and conservation score files and \nmake sure that they have equivalent number of data points...\n";
	exit;
}         

#NOW WE WILL CALCULATE THE FINAL BACKGROUND AND DOMAIN RELATED RMSD VALUES FOR EACH BLOCK. (the array names is somewhat misleading, however I named them like this to remember which ones to take into account in the end.)
#First create a new arrays called the @Overall_RMSD_Array_Sum and @input_array_groupedby_width_sum
my @Overall_RMSD_Array_Sum;
my @input_array_groupedby_width_sum;
for (my $i = 0; $i < scalar (@Overall_RMSD_Array); $i++) {
	$_ = $Overall_RMSD_Array[$i]*$Domain_Array[$i]*$conservation_scores_parsed[$i]*$weight_scores_parsed[$i];
	push (@Overall_RMSD_Array_Sum, $_);
}
#Uncomment below to check the values
#my $outputX = join ("\n", @Overall_RMSD_Array_Sum, "\n");
#print $output_file $outputX;
for (my $i = 0; $i < scalar (@input_array_groupedby_width); $i++) {
	$_ = $input_array_groupedby_width[$i]*$Domain_Array[$i]*$conservation_scores_parsed[$i]*$weight_scores_parsed[$i];
	push (@input_array_groupedby_width_sum, $_);
}
#Uncomment below to check the values
#my $outputX = join ("\n", @input_array_groupedby_width_sum, "\n");
#print $output_file $outputX;

#CREATE A ARRAY THAT CONTAINS DIFFERENCES BETWEEN DOMAIN RMSD and OVERALL RMSD
my @difference;
for (my $i = 0; $i < scalar (@input_array_groupedby_width_sum); $i++) {
	$_ = $input_array_groupedby_width_sum[$i] - $Overall_RMSD_Array_Sum[$i];
	push ( @difference, $_);
}
#Uncomment below to check the values
#my $outputX = join ("\n", @difference, "\n");
#print $output_file $outputX;

#Now we create an array that contains elements to ascertain how significant the results in that block would be. It can be negative in cases where most residues are comprised of domains. You do not want to make something significant insignificant.
my @significance;
for (my $i = 0; $i < scalar (@input_array_groupedby_width_sum); $i++) {
	$_ = $Z_score_threshold*$rmsd_standard_deviation*($width/$aa_count_smallest)*$Domain_Array[$i];
	push (@significance, $_);
}
#Uncomment below to check the values
#my $outputX = join ("\n", @significance, "\n");
#print $output_file $outputX;

#HERE WE CALCULATE THE MAIN SIGNIFICANCE 
my $sum_significance = take_sum(@significance);
my $sum_difference = take_sum(@difference);

my $Main_Significance;
if ((abs($sum_difference)+abs($sum_significance)) == 0) {
	print "Coefficient of significance is substituted by 1 to prevent illigal division!..\n";
	$Main_Significance = 1;
} else {
	$Main_Significance = (1+(($sum_difference-$sum_significance)/(abs($sum_difference)+abs($sum_significance))))/2;
}
#Uncomment below to check the values
#my $outputX = $Main_Significance;
#print "Your value is $outputX\n";

#CALCULATE THE MAIN OVERALL BACKGROUND
my $overall_background = take_sum(@Overall_RMSD_Array_Sum);
#Uncomment below to check the values
#my $outputX = $overall_background;
#print "Your value is $outputX\n";
#CALCULATE THE MAIN RMSD COMING FROM DOMAIN
my $overall_domain = take_sum(@input_array_groupedby_width_sum);
#Uncomment below to check the values
#my $output = $overall_domain;
#print "Your value is $output\n";
#TOTAL
my $total = $overall_background + $overall_domain;
if ($total == 0) {
	print "Your total change (Modict paper algorithm step 4) is 0!\nForcing completion by setting raw score to 0...\n";
	goto OBLIGATE_ZERO;
}

#HERE WE CALCULATE THE RATIOS. ASSUMING THAT THE RESULT IS A 2 DIMENSIONAL VECTOR WITH AXES OVERALL/TOTAL AND DOMAIN/TOTAL. YOU NORMALLY WANT MAJORITY OF THE SCORE COMING FROM THE DOMAIN COMPONENT.
my $overall_to_total =  $overall_background/$total;
my $domain_to_total = $overall_domain/$total;
#Above 2 are your x and y axis values respectively. The higher your y value the less the background.
my $hypothenus = sqrt($overall_to_total**2 + $domain_to_total**2);
my $sinus = $domain_to_total/$hypothenus;
#NOW WE CAN CALCULATE THE RAW SCORE
my $raw_score = $total*$sinus/2;
#Uncomment below to check the values
#print "Your value is $raw_score\n";
#EXPRESS THE FINAL SCORE BY MULTIPLYING RAW SCORE AND MAIN SIGNIFICANCE
OBLIGATE_ZERO:
if ($total == 0) {
	$raw_score = 0;
}
my $final = $raw_score * $Main_Significance;
my $final_rounded = sprintf("%.3f",$final);
print "Your final result is $final_rounded.\nBeware that this is a unitless score and must be compared to an another score\nFor more information about the rationle of comparison:\nPlease read the manual.\nThank you and goodbye...\n";
my $output = $final_rounded;
print $output_file "your final value is $output!\n\n";
print $final."\n";
if ($eventlistener_answer =~ /^[yY].*/) {
	my $output2 = join ("\n", @eventlistener, "\n");
	open (my $output_file, '>', "$PATH/Essentials/essentials_MODICT.txt") or die ("Cannot open the specified essential file!\n");
	print $output_file "Below are your answers. Next time you turn on automizer you can edit the ones you like.\n";
	print $output_file $output2;
}
if ((defined $ARGV[5])&&($ARGV[5] =~ /-iterate\s*$/)) {
	#The new line below makes a problem and the program fails at checkpoint...
	#my $output3 = join ("\n",@weight_scores_parsed,"\n");
	my $output3 = join ("\n",@weight_scores_parsed);
	open (my $output_file, '>', "$PATH/Essentials/iterate_MODICT.txt") or die ("Cannot open the specified iteration file!\n");
	print $output_file $output3;
} elsif ((defined $ARGV[5])&&($ARGV[5] =~ /-iterate_evolve\s*$/)) {
	my $signal = $ARGV[7];
	$signal =~ s/-//g;
	if ($signal == 0) {
		my $output3 = join ("\n",@weight_scores_parsed);
		open (my $output_file, '>', "$PATH/Essentials/iterate_MODICT_trial.txt") or die ("Cannot open the specified iteration file!\n");
		print $output_file $output3;
	} elsif ($signal == 1) {
		my $output3 = join ("\n",@weight_scores_parsed);
		open (my $output_file, '>', "$PATH/Essentials/iterate_MODICT.txt") or die ("Cannot open the specified iteration file!\n");
		print $output_file $output3;
	}
}


sub list_creation {
	$domain_count++;
	print "Please type the start of domain_$domain_count...[Enter integer greater than 0]\n";
	RESIDUECAP1sub:
	$_ = program_mode(\@ARGV);
	chomp $_;
	my $overlap_quiery = $_;
	my $overlap_score = 0;
	if ($_ !~ /^[-]?[1-9]{1}[0-9]*$/) {
		print "Only numbers are allowed...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP1sub;
	}
	for (my $i = 0; $i <= ($#domains - 1); $i+= 2) {
		if ((($overlap_quiery >= $domains[$i])&& ($overlap_quiery <= $domains[$i+1])) || ($overlap_quiery == $domains[$i]) || ($overlap_quiery == $domains[$i + 1]) || (($domains[$i] != 0)&&($overlap_quiery == $domains[$i]-1))) {
			$overlap_score++;
		}
	}
	if ($_ > ($aa_count_smallest-1)) {
		print "You cannot enter a number greater than the maximum residue count - 1, please try again...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP1sub;
	} elsif ((($_ <= $domains[$#domains]) && ($_ >= $domains[$#domains - 1])) || ($overlap_score > 0)) {
		print "You cannot enter overlaping regions, please try again...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP1sub;
	} elsif ($_ <= 0) {
		print "0 or negative numbers are not allowed. Maybe in some other world it is...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP1sub;
	} else {
	}
	$last_domain_entry = $_;
	push (@domains, $_);
	print "Please type the end of domain_$domain_count...[Enter integer smaller than maximum aminoacid count]\n";
	RESIDUECAP2sub:
	$_ = program_mode(\@ARGV);
	chomp $_;
	$overlap_quiery = $_;
	$overlap_score = 0;
	if ($_ !~ /^[-]?[1-9]{1}[0-9]*$/) {
		print "Only numbers are allowed...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP2sub;
	}
	for (my $i = 0; $i <= ($#domains - 2); $i+= 2) {
		if ((($overlap_quiery >= $domains[$i])&& ($overlap_quiery <= $domains[$i+1])) || ($overlap_quiery == $domains[$i]) || ($overlap_quiery == $domains[$i + 1]) || (($overlap_quiery >= $domains[$i + 1])&&($domains[$#domains] <= $domains[$i + 1])) ) {
			$overlap_score++;
		}
	}
	if ($_ > $aa_count_smallest) {
		print "You cannot enter a number greater than the maximum residue count, please try again...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP2sub;
	} elsif (($_ - $last_domain_entry) <= 0) {
		print "There must be at least 1 aminoacid difference between domain start and end, please try again...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP2sub;
	} elsif ((($_ >= $domains[$#domains - 2]) && ($domains[$#domains] <= $domains[$#domains - 2])) || ($overlap_score > 0) ) {
		print "You cannot enter overlaping regions, please try again...\n";
		$answer_counter--;
		if ($eventlistener_answer =~ /^[yY].*/) {
			pop (@eventlistener);
		}
		goto RESIDUECAP2sub;
	} else {
	}
	push (@domains, $_);
	print "Are there more domains in your protein?[y/n]\n";
	$_ = program_mode(\@ARGV);
	chomp $_;
	until (($_ =~ /^n.*/) || ($_ !~ /^[yY].*/)) {
		list_creation ($_);
	}
}

sub parser {
my @parsed;
push (@parsed, "\t"."start\t");
push (@parsed, "end\n");
my $i = 0;
my $domain_number;
until ($i == scalar(@domains)) {
	if (($i % 2) == 0) {
		$domain_number = ($i/2)+1;
		push (@parsed, "domain"."$domain_number"."\t");
		$_ = $domains[$i]."\t";
		push (@parsed, $_);
		$i++;
	} else {
		$_ = $domains[$i]."\n";
		push (@parsed, $_);
		$i++;
	}
	
}
$domain_continue_output = join ("",@parsed,"\n");
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

sub block_iterator1 {

my $interval_sum_for_iterator=0;
my $counter = 0;
my $result_rounded;
my $result;
my $i = 0;
my $j = 0;
my @outcome_block_iterator;
until ($counter == int($aa_count_smallest/$width)) {
	until ($i == $width) {
		$input_array[$j] =~ s/[,;:-_|]/./;
		#To check, uncomment below to see the value of $input_array[$j]
		#print "$input_array[$j]";
		$interval_sum_for_iterator += $input_array[$j];
		$j++;
		$i++;
	}
	$result = ($interval_sum_for_iterator/$width);
	$result_rounded = sprintf( "%.12f", $result);
	push (@outcome_block_iterator,$result_rounded);
	$i = 0;
	$interval_sum_for_iterator=0;
	$counter++;
}
@input_array_groupedby_width = @outcome_block_iterator;
#You can uncomment below to check the values
#print "@outcome_block_iterator\n\n\n";
#print "@_\n\n\n";
#print "@input_array_groupedby_width\n\n\n";
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

sub gaussian_distribution {
#Assign the given variable
my $given = $One_minus_Total_Domain_Ratio;
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

#Now subtract from the cumulative values, 1-(total domain to protein ratio) and take absolute value.
my @subtracted_cumulative_paired_values;
for (my $i = 0; $i < scalar (@cumulative_paired_values); $i++) {
	push(@subtracted_cumulative_paired_values, abs($cumulative_paired_values[$i]-$given));
}
#Uncomment the below lines to see if it works properly
#my $output = join ("\n", @subtracted_cumulative_paired_values, "\n");
#print $output_file $output;
#print "Your given was $given!\n";
#return the array
return (@subtracted_cumulative_paired_values);
}

sub block_iterator2 {

my $interval_sum_for_iterator=0;
my $counter = 0;
my $result_rounded;
my $result;
my $i = 0;
my $j = 0;
my @outcome_block_iterator;
until ($counter == int($aa_count_smallest/$width)) {
	until ($i == $width) {
		$conservation_scores[$j] =~ s/[,;:-_|]/./;
		#Sometimes excel or tab-delimited format insert " around. 
		$conservation_scores[$j] =~ s/["]//g;
		#To check, uncomment below to see the value of $conservation_scores[$j]
		#print "$conservation_scores[$j]";
		$interval_sum_for_iterator += $conservation_scores[$j];
		$j++;
		$i++;
	}
	$result = ($interval_sum_for_iterator/$width);
	$result_rounded = sprintf( "%.3f", $result);
	push (@outcome_block_iterator,$result_rounded);
	$i = 0;
	$interval_sum_for_iterator=0;
	$counter++;
}
@conservation_scores_parsed = @outcome_block_iterator;
#You can uncomment below to check the values
#print "@outcome_block_iterator\n\n\n";
#print "@_\n\n\n";
#print "@conservation_scores_parsed\n\n\n";
#my $output = join ("\n", @conservation_scores_parsed, "\n");
#print $output_file $output;
}

sub block_iterator3 {

my $interval_sum_for_iterator=0;
my $counter = 0;
my $result_rounded;
my $result;
my $i = 0;
my $j = 0;
my @outcome_block_iterator;
until ($counter == int($aa_count_smallest/$width)) {
	until ($i == $width) {
		$weight_scores[$j] =~ s/[,;:-_|]/./;
		#Sometimes excel or tab-delimited format inserts """ around.
		$weight_scores[$j] =~ s/["]//g;
		#To check, uncomment below to see the value of $conservation_scores[$j]
		#print "$weight_scores[$j]";
		$interval_sum_for_iterator += $weight_scores[$j];
		$j++;
		$i++;
	}
	$result = ($interval_sum_for_iterator/$width);
	$result_rounded = sprintf( "%.3f", $result);
	push (@outcome_block_iterator,$result_rounded);
	$i = 0;
	$interval_sum_for_iterator=0;
	$counter++;
}
@weight_scores_parsed = @outcome_block_iterator;
#You can uncomment below to check the values
#print "@outcome_block_iterator\n\n\n";
#print "@_\n\n\n";
#print "@weight_scores_parsed\n\n\n";
#my $output = join ("\n", @weight_scores_parsed, "\n");
#print $output_file $output;
}

sub Scale {
#my @test_array = @_;
foreach my $element (@_) {
	$element = $element*$width/$aa_count_smallest;
}
}

sub take_sum {
my @test_array = @_;
my $sum;
for (my $i = 0; $i < scalar (@test_array); $i++) {
	$sum += $test_array[$i]
}
return $sum;
}

sub program_mode {
my $ref = $_[0];
#test to see if you have captured the reference
#print ${$ref}[0]."\n";
# OR
#print $ref -> [1]."\n";
#print $ref -> [4]."\n";
if ($automizer_answer =~ /^[yY].*/) {
	if ((defined $ARGV[2])&&($ref -> [2] =~ /-.*[.]txt/)&&($answer_counter == 0)) {
		$ref -> [2] =~ s/-//g;
		$_ = $ref -> [2];
		chomp $_;
	} elsif ((defined $ARGV[3])&&($ref -> [3] =~ /-.*[.]txt/)&&(defined $_[1])) {
		$ref -> [3] =~ s/-//g;
		$_ = $ref -> [3];
		chomp $_;
	} elsif ((defined $ARGV[4])&&($ref -> [4] =~ /-.*[.]txt/)&&(defined $_[1])) { 
		$ref -> [4] =~ s/-//g;
		$_ = $ref -> [4];
		chomp $_;
	} else {
	$_ = $automizer[$answer_counter];
	chomp $_;
	}
} else {
	$_ = <STDIN>;
}
chomp $_;
if ($eventlistener_answer =~ /^[yY].*/) {
	push (@eventlistener,$_)
}
$answer_counter++;
#Check what the program mode returns
#print $_;
return $_;
}

sub skip_header {
  my $FH = shift;
  <$FH>;
}

sub getopt {
#Define the possible arguments first.
my $argv_0 = "";
my $argv_1 = "";
my $argv_2 = "";
my $argv_3 = "";
my $argv_4 = "";
my $argv_5 = "";
my $argv_6 = "";
my $argv_7 = "";
my $argv_8 = "";
#Use the getoptions module.
GetOptions ("eventlistener=s" => \$argv_0, "automiser=s" => \$argv_1, "input=s" => \$argv_2, "conservation=s" => \$argv_3, "weight=s" => \$argv_4, "mode=s" => \$argv_5, "path=s" => \$argv_6, "signal=s" => \$argv_7, "need=s" => \$argv_8) or die ("Error parsing the command line arguments!\n");
#add the prefixes to the evenlistener and automizer
$argv_0 = "-eventlistener_".$argv_0;
$argv_1 = "-automiser_".$argv_1;
#Form an hash that keeps all of the references to raw arguments chopped from GetOptions. If they already come with dashes, dashes will not be added. This is crucial for inter-script interactions. For eventlistener and automiser we know that this is already not the case.
my %raw_argv = ("eventlistener" => \$argv_0, "automiser" => \$argv_1, "input" => \$argv_2, "conservation" => \$argv_3, "weight" => \$argv_4, "mode" => \$argv_5, "path" => \$argv_6, "signal" => \$argv_7, "need" => \$argv_8);
for my $element (keys %raw_argv) {
	if ((${$raw_argv{$element}} !~ /eventlistener/)&&(${$raw_argv{$element}} !~ /automi[sz]er/)&&(${$raw_argv{$element}} !~ /^\s*\t*-/)) {
		${$raw_argv{$element}} = "-".${$raw_argv{$element}};
		#check to see them.
		#print ${$raw_argv{$element}}."\n";
	} elsif (${$raw_argv{$element}} =~ /[-]+/) {
	#replace all instances of multi dashes to single dashes.
		${$raw_argv{$element}} =~ s/[-]+/-/g;
	}
}
#Extention check
my %extentions = ("input" => \$argv_2, "conservation" => \$argv_3, "weight" => \$argv_4);
for my $element (keys %extentions) {
	if (${$raw_argv{$element}} !~ /^-$/) {
		if (${$raw_argv{$element}} !~ /[.]txt/) {
			print "The files you have specified has to be entered with their extention.\nWhen you specify file write --input file.txt instead of --input file!\n";
			exit;
		}
	}
}
@ARGV = ();
#Sorting arguments.
if (($argv_8 =~ /^-[vV]{1}$/) || ($argv_8 =~ /^-[Vv][Ee][Rr][Ss][Iiı][Oo][Nn]$/) || ($argv_8 =~ /^-[hH]{1}$/) || ($argv_8 =~ /^-[Hh][Ee][Ll][Pp]$/)) {
	push (@ARGV, $argv_8);
} else {
if (($argv_0 eq "-eventlistener_") && ($argv_1 eq "-automiser_")) {
	print "You have not defined parameters. Entering QA mode...\n";
} elsif ((($argv_0 eq "-eventlistener_") || ($argv_1 eq "-automiser_"))&&(($argv_2 ne "-")||($argv_3 ne "-")||($argv_4 ne "-")||($argv_5 ne "-")||($argv_6 ne "-")||($argv_7 ne "-"))) {
	print "Evenlistener and automiser options have to be clearly defined before using other arguments!..\n";
	print "Entering QA mode...\n";
} elsif (($argv_1 !~ /-automi[sz]er_on/)&&(($argv_2 ne "-")||($argv_3 ne "-")||($argv_4 ne "-")||($argv_5 ne "-")||($argv_6 ne "-")||($argv_7 ne "-"))) {
	print "You cannot define automiser as off and then define other parameters.\n";
	print "You must at least run Modict in QA mode once before turning on automiser and other parameters...\n";
	exit;
} else {
	print "Your parameters are taken...\n\n";
	push (@ARGV, $argv_0);
	push (@ARGV, $argv_1);
	push (@ARGV, $argv_2);
	push (@ARGV, $argv_3);
	push (@ARGV, $argv_4);
	push (@ARGV, $argv_5);
	push (@ARGV, $argv_6);
	push (@ARGV, $argv_7);
#Remove unnecessary dashes in the end. Dashes in between should still remain...
	until ($ARGV[$#ARGV] ne "-") {
		pop @ARGV;
	}
}
}
#Uncomment below to see if the arguments are taken and sorted properly.
#for (my $i = 0; $i<=$#ARGV; $i++) {
#print $ARGV[$i]."\n";
#}

}
	