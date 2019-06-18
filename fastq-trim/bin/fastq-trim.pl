#!/usr/bin/env perl

# Load modules
use Modern::Perl;
use Getopt::Long::Descriptive;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o",
	["Trim N nucleotides at the 5'/3' end of the sequences in a FASTQ file."],
	[],
	['input=s', "input FASTQ file; reads from STDIN if \"-\"", {required => 1}],
	['N=i', "number of nucleotides to trim", {required => 1}],
	['start', "trim N nucleotides from the 5'end"],
	['stop', "trim N nucleotides from the 3'end"],
	['delim=s', "if defined, trimmed sequences are appended to read names using STR as separator"],
	['parts-file=s', "if defined, trimmed FASTQ parts are printed in STR"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;

my $delim = $opt->delim;

my $PARTS;
if ($opt->parts_file) {
	$PARTS = IO::File->new($opt->parts_file, ">");
}

my $N = $opt->n;
if ($N <= 0) {
	die "N must be positive\n";
}

if (!$opt->start and !$opt->stop) {
	die "One of start or stop must be specified\n";
}

my $IN = filehandle_for($opt->input);
while (my $name = $IN->getline) {
	chomp $name;
	if ($name !~ /^\@/) {
		next;
	}
	my $seq = $IN->getline; chomp $seq;
	my $plus = $IN->getline; chomp $plus;
	my $qual = $IN->getline; chomp $qual;

	# skip very short sequences.
	if ($N >= length($seq)) {
		next;
	}

	# trim
	my ($seq_part, $qual_part);
	if ($opt->start) {
		$seq_part = substr($seq, 0, $N);
		$qual_part = substr($qual, 0, $N);
		$seq = substr($seq, $N);
		$qual = substr($qual, $N);
	} else {
		$seq_part = substr($seq, -$N);
		$qual_part = substr($qual, -$N);
		$seq = substr($seq, 0, -$N);
		$qual = substr($qual, 0, -$N);
	}

	# print
	if (defined $delim) {
		$name = join($delim, $name, $seq_part);
	}
	say $name;
	say $seq;
	say $plus;
	say $qual;

	if (defined $PARTS) {
		say $PARTS $name;
		say $PARTS $seq_part;
		say $PARTS $plus;
		say $PARTS $qual_part;
	}
}

exit;

sub filehandle_for {
	my ($file) = @_;

	if ($file eq '-'){
		return IO::File->new("<-");
	}
	else {
		return IO::File->new($file, "<");
	}
}
