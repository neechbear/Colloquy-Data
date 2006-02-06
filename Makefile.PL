# vim:ts=4:sw=4:tw=78

require 5.005;
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

$|++;

my $name = 'Colloquy::Data';
my $from = 'lib/Colloquy/Data.pm';

# Make the Makefile as per usual
WriteMakefile(
		NAME          => $name,
		VERSION_FROM  => $from,
		ABSTRACT_FROM => $from,
		AUTHOR        => 'Nicola Worthington <nicolaw@cpan.org>',
		PREREQ_PM     => {
				'Carp' => 0,
				'Test::More' => 0,
				'Test::Assertions' => 0,
			},
	);

# Send perl and module version information home if we've been
# given permission to do so by a human being - default to not
# send for automated testing environments, of if the user does
# not respond within 20 seconds.
my $url = $ENV{AUTOMATED_TESTING} ? undef : may_send_version_information();
if ($url) {
	my @resp = ();
	eval {
		local $SIG{ALRM} = sub { exit; };
		alarm 10;
		for (split(/\s*\n+\s*/, LWP::Simple::get($url))) {
			push @resp, $_ if $_;
		}
		alarm 0;
	};
	print substr($resp[0],200) || "Thank you for sending this information.";
	print "\n\n";
}

sub may_send_version_information {
	eval {
		require Term::ReadKey;
		require Config;
		require LWP::Simple;
	};
	return undef if $@;

	my $version = '';
	eval { $version = ExtUtils::MM_Unix::parse_version({},$from); };
	if (!$version && open(FH,'<META.yml')) {
		while (local $_ = <FH>) {
			if (/version:\s*([0-9\.]+)/i) {
				$version = $1;
				last;
			}
		} close(FH);
	}

	my $str = sprintf('%s?%s=%s&%s=%s&%s=%s&%s=%s&%s=%s&%s=%s',
			'http://perlgirl.org.uk/lib/usage.cgi',
			'name',     $name,
			'version',  $version,
			'osname',   $Config::Config{osname},
			'archname', $Config::Config{archname},
			'osver',    $^O,
			'perlver',  $]
		);

	print "\nThank you for downloading $name\n\n";
	print "I would like to find out how many people are using this software,\n";
	print "and on what operating systems and Perl versions. If you have an\n";
	print "internet connection, may I transmit the following information:\n\n";
	print "$str\n";
	print "\nSend this anonymous information? (Y/n): ";

	my $send = 0;
	Term::ReadKey::ReadMode(4);
	1 while (defined($send = Term::ReadKey::ReadKey(20)) && $send !~ /^[yn]*$/i);
	$send = $send =~ /^y$/i ? 1 : 0;
	print $send ? "y\n\n" : "n\n\n";
	Term::ReadKey::ReadMode(0);

	return $send ? $str : undef;
}

