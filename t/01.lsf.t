# -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;
use Getopt::Long;
use lib 't/lib';
use Test::asub;
no lib 't/lib';

my ($sh, $out, $err);

my $t = Test::asub->new();

sub bsub_arguments_ok {
    my ($asub_cmd, %tests) = (shift, @_);
    (my $bsub_opts = $out) =~ s/^.*\|\sbsub\s(.*)/$1/g;
    Getopt::Long::Configure(qw{pass_through bundling});
    my %parsed;
    my ($ret, $args) = Getopt::Long::GetOptionsFromString(
        $bsub_opts,
        'R=s' => \$parsed{resources},
        'J=s' => \$parsed{jobname},
        'm=s' => \$parsed{hosts},
        'n=s' => \$parsed{processors},
        'o=s' => \$parsed{outfile},
        'e=s' => \$parsed{errfile},
        'W=s' => \$parsed{runtimelimit},
        'c=s' => \$parsed{cputimelimit},
        'q=s' => \$parsed{queue},
        'w=s' => \$parsed{dependency},
        );
    is $ret, 1, 'successful parse';
    
    foreach my $test(keys %tests) {
        subtest $test => sub {
            $tests{$test}->($bsub_opts, { %parsed });
        };
    }
}

note "LSF";
($out, $err) = $t->asub_run_ok_with_lsf("echo hello world\n");
($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
ok $sh;
is $err, '', 'no error messages';
bsub_arguments_ok $out,
    resources => sub { is pop->{resources}, 'span[hosts=1]', 'default span' };

note "LSF";
($out, $err) = $t->asub_run_ok_with_lsf("echo hello world\n",
                                        qw{-R rusage[mem=200]});
($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
ok $sh;
like $out, qr/\|\sbsub/, 'LSF submission command';
is $err, '', 'no error messages';

bsub_arguments_ok $out,
    resources => sub {
        my ($ret, $args) = Getopt::Long::GetOptionsFromString(
            shift,
            'R=s@' => \my @resources,
            );
        is $ret, 1, 'success';
        is @resources, 1, 'single -R option';
        is shift->{resources}, 'rusage[mem=200] span[hosts=1]';
},
    jobname => sub {
        my ($opts, $parsed) = @_;
        like $parsed->{jobname}, qr/^asub_[0-9]+\[1\-1\]$/;
};

note "LSF";
($out, $err) = $t->asub_run_ok_with_lsf(
    "echo hello world\n",
    qw{-M 2048 -j example -n 10 -w 1 -q default});
($sh = $out) =~ s{^.*(example\.sh).*$}{$1};
ok $sh;
like $out, qr/\|\sbsub/, 'LSF submission command';
is $err, '', 'no error messages';

bsub_arguments_ok $out,
    jobname => sub { is pop->{jobname}, 'example[1-1]', 'correct job name'; },
    jobname => sub { is pop->{queue}, 'default', 'correct queue name'; },
    resources => sub {
        my ($string, $args) = @_;
        local $TODO = 'see above';
        my ($ret) = Getopt::Long::GetOptionsFromString(
            $string,
            'R=s@' => \my @resources,
            );
        is $ret, 1, 'success';
},
    options => sub {
        my ($string, $args) = @_;
        is_deeply [ @$args{qw(jobname processors errfile outfile dependency)} ],
        [ 'example[1-1]', 10, 'example.err/%I.err', 'example.out/%I.out', 1 ],
        'sliced arguments as expected';
};

note "LSF arguments with -g";
($out, $err) = $t->asub_run_ok_with_lsf(
    "echo hello world\n",
    qw{-m assembly -n 2 -W 5000 -C 3600 -j example -g 10});
($sh = $out) =~ s{^.*(example\.sh).*$}{$1};
ok $sh;
like $out, qr/\|\sbsub/, 'LSF submission command';
is $err, '', 'no error messages';

bsub_arguments_ok $out,
    jobname  => sub { is pop->{jobname}, 'example[1-1]', 'correct job name'; },
    runlimit => sub { is pop->{runtimelimit}, 5000, 'correct limit'; },
    cpulimit => sub { is pop->{cputimelimit}, 3600, 'correct limit'; },
    hosts    => sub { is pop->{hosts}, 'assembly', 'host set' },
    processors => sub { is pop->{processors}, 10, 'per job cpu set -g' },
;

$t->asub_arguments_ok($out,
    arguments => sub {
        my ($ref) = @_;
        is_deeply $ref, {
            group => undef,
            group_size => 10,
            index => '${LSB_JOBINDEX}'
        }, 'expected group and index settings'; }
    );

note "LSF grouping -G and -g";
($out, $err) = $t->asub_run_ok_with_lsf(
    "echo hello world\n",
    qw{-G -g 50});
$t->asub_arguments_ok($out,
    arguments => sub {
        my ($ref) = @_;
        is_deeply $ref, {
            group      => 1,
            group_size => 50,
            index      => '${LSB_JOBINDEX}'
        }, 'expected group and index settings'; }
    );



done_testing;
