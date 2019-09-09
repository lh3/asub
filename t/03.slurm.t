# -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::asub;
no lib 't/lib';

my ($sh, $out, $err);

my $t = Test::asub->new();

note "SLURM";
($out, $err) = 
    $t->asub_run_ok_with_slurm("echo hello world\n",
                               qw{-M 4 -x x -q default});
($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
ok $sh;
like $out, qr/\|\ssbatch/, 'SLURM submission command';
is $err, '', 'no error messages';

{
    local $TODO = 'uninit messages';
    
    ($out, $err) = 
        $t->asub_run_ok_with_slurm("echo hello world\n");
    ($sh = $out) =~ s{^.*(asub_[0-9]+\.sh).*$}{$1};
    ok $sh;
    like $out, qr/\|\ssbatch/, 'SLURM submission command';
    is $err, '', 'no error messages';
}


done_testing;
