#!/usr/bin/env perl

use Modern::Perl;
use Getopt::Long::Descriptive;

use GenOO::Data::File::FASTQ;
use GenOO::Data::File::SAM;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o",
	["Reports min/max quality score and guesses the quality type of a FASTQ/SAM file."],
	[],
	['input|i=s', 'input file. If not set use STDIN (-type is required).'],
	['type' => hidden => { one_of => [
		[ "fastq" => "input in FASTQ format" ],
		[ "sam" => "input in SAM format" ],
	] } ],
	['verbose|v', "print progress"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;
if (!$opt->input and !$opt->type) {
	print "Input format is required when -input is empty\n\n";
	print($usage->text);
	exit;
}

warn "specifying input type\n" if $opt->verbose;
my $itype = uc($opt->type || guess_input($opt->input));
my $qual_accessor = quality_accessor_for_itype($itype);

warn "opening input file\n" if $opt->verbose;
my $class = "GenOO::Data::File::".uc($itype);
my $fp = $class->new(file => $opt->input);

warn "Measuring nucleotide preference\n" if $opt->verbose;
my %counts;
while (my $r = $fp->next_record) {
	my $qual = &$qual_accessor($r);
	my @qualities = split(//, $qual);
	foreach my $q (@qualities) {
		my $num = ord($q);
		$counts{$num}++;
	}
};

my @sorted_nums = sort {$a <=> $b} keys %counts;
my $min = $sorted_nums[0];
my $max = $sorted_nums[-1];
say "quality range: [$sorted_nums[0], $sorted_nums[-1]]";

if ($min == 33 and $max == 73) {
	say "Phred+33 (Sanger)";
}
if ($min == 59 and $max == 104) {
	say "Solexa+64 (Solexa)";
}
if ($min == 64 and $max == 104) {
	say "Phred+64 (Illumina 1.3+)";
}
if ($min == 66 and $max == 104) {
	say "Phred+64 (Illumina 1.5+)";
}
if ($min == 33 and $max == 74) {
	say "Phred+33 (Illumina 1.8+)";
}



###########################################################################
sub guess_input {
	my ($file) = @_;

	if ($file =~ /\.fastq(.gz)*$/) {
		return 'FASTQ';
	}
	elsif ($opt->input =~ /\.sam(.gz)*$/) {
		return 'SAM';
	}
}

sub quality_accessor_for_itype {
	my ($type) = @_;

	return sub {my $r = shift; $r->qual} if $type eq 'SAM';
	return sub {my $r = shift; $r->quality};
}

