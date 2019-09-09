# -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;
use Getopt::Long;
use lib 't/lib';
use Test::asub;
no lib 't/lib';

my ($sh, $out, $err);

sub qsub_arguments_ok {
    my ($asub_cmd, %tests) = (shift, @_);
    (my $bsub_opts = $out) =~ s/^.*\|\sqsub\s(.*)/$1/g;
    Getopt::Long::Configure(qw{pass_through no_bundling});
    my %parsed;
    my ($ret, $args) = Getopt::Long::GetOptionsFromString(
        $bsub_opts,
        'cwd!'       => \$parsed{save_cwd},
        'N=s'        => \$parsed{jobname},
        'o=s'        => \$parsed{outfile},
        'e=s'        => \$parsed{errfile},
        'l=s@'       => \$parsed{limits},
        'q=s'        => \$parsed{queue},
        'hold_jid=s' => \$parsed{dependency}
        );
    is $ret, 1, 'successful parse';

    foreach my $test(keys %tests) {
        subtest $test => sub {
            $tests{$test}->($bsub_opts, \%parsed);
        };
    }
}

my $t = Test::asub->new();

note "SGE";
($out, $err) = $t->asub_run_ok_with_sge("echo hello world\n");
($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
ok $sh;
like $out, qr/\|\sqsub/, 'SGE submission command';
is $err, '', 'no error messages';

note "SGE";
($out, $err) = $t->asub_run_ok_with_sge("echo hello world\n",
    qw{-q low-mem -R test -n 8 -W 3600 -M 4096 -w 2000});
($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
ok $sh;
qsub_arguments_ok $out,
    depend => sub { is pop->{dependency}, 2000, 'set' },
    queue  => sub { is pop->{queue}, 'low-mem', 'set' },
    working => sub { is pop->{save_cwd}, 1, 'set' };

is $err, '', 'no error messages';



done_testing;
