#!/usr/bin/env perl

# Load modules
use Modern::Perl;
use Getopt::Long::Descriptive;
use IO::Uncompress::Gunzip qw($GunzipError) ;

# Define and read command line options
my ($opt, $usage) = describe_options(
	"Usage: %c %o",
	["Print FASTQ entries whose sequence length is within given constrains."],
	[],
	['input=s', "input FASTQ file; reads from STDIN if \"-\"", {required => 1}],
	['min=i', "minimum accepted sequence length; (Default: 0)", {default => 0}],
	['max=i', "maximum accepted sequence length; unrestricted if non given"],
	['help|h', 'print usage and exit', {shortcircuit => 1}],
);
print($usage->text), exit if $opt->help;


my $MIN = $opt->min;
my $MAX = $opt->max;
if (defined $MAX and $MAX < $MIN) {
	die "max must be greater/equal than min\n";
}

my $IN = filehandle_for($opt->input);
while (my $name = $IN->getline) {
	if ($name !~ /^\@/) {
		next;
	}
	my $seq = $IN->getline;
	my $plus = $IN->getline;
	my $qual = $IN->getline;

	my $len = length($seq) - 1;

	# skip short sequences.
	if ($len < $MIN) {
		next;
	}
	# skip long sequences.
	if (defined $MAX and $len > $MAX) {
		next;
	}
	print $name;
	print $seq;
	print $plus;
	print $qual;
}

exit;

sub filehandle_for {
	my ($file) = @_;

	if (!defined $file) {
		die "Undefined file\n";
	}
	if ($file eq '-'){
		return IO::File->new("<-");
	}
	if ($file =~ /\.gz$/) {
		my $z = new IO::Uncompress::Gunzip $file or die "gunzip failed: $GunzipError\n";
		return $z
	}
	return IO::File->new($file, "<");
}

