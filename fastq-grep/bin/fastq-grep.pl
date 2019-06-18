#!/usr/bin/env perl

# Load modules
use warnings;
use strict;
use Getopt::Long::Descriptive;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o",
	["Reads from STDIN and prints FASTQ entries that contain pattern in sequence."],
	[],
	['pattern=s', "keep entries with this pattern", {required => 1}],
	['add-to-header', "adds prefix to header"],
	['add-to-header-delim=s', "adds prefix to header", {default => ':'}],
	['inverse', "keep entries not matching the pattern"],
	['verbose|v', "print progress"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;

my $idx = $opt->pattern;
my $add_to_header = $opt->add_to_header;
my $delim = $opt->add_to_header_delim;
my $idxLen = length($idx);
my $inverse = $opt->inverse;

while (my $header = <>) {
	my $seq = <>;
	my $foo = <>;
	my $qual = <>;

	my $pass = 0;
	if ($seq =~ /$idx/) {
		if ($inverse) {
			next;
		}
	} else {
		if (!$inverse) {
			next;
		}
	}

	if ($add_to_header) {
		chomp $header;
		print $header . $delim . $idx . "\n";
	} else {
		print $header;
	}

	print $seq;
	print $foo;
	print $qual;
}

