# -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::asub;
no lib 't/lib';

note "Simulate running on farm";
my ($out, $err);

my $t = Test::asub->new();
$t->farm_context->write_farm_script(
q/echo "hello world 1"/,
q/echo "hello world 2"/,
q/echo "hello world 3"/,
q/echo "hello world 4"/,
q/echo "hello world 5"/,
q/echo "hello world 6"/,
q/echo "hello world 7"/,
q/echo "hello world 8"/,
q/echo "hello world 9"/,
q/echo "hello world 10"/,
);

($out, $err) = $t->asub_farm_run_ok;

like $_, qr/^\[asub\]/ for split /\n/, $err;
# diag $err;
like $out, qr/^hello world [0-9]+/;

$t->farm_context->write_farm_script(
q/echo "hello world 1" >&2/,
q/echo "hello world 2" >&2/,
q/echo "hello world 3" >&2/,
q/echo "hello world 4" >&2/,
q/echo "hello world 5" >&2/,
q/echo "hello world 6" >&2/,
q/echo "hello world 7" >&2/,
q/echo "hello world 8" >&2/,
q/echo "hello world 9" >&2/,
q/echo "hello world 10" >&2/,
);

($out, $err) = $t->asub_farm_run_ok;

my @messages = grep { m/^[^[]/ } split /\n/ => $err;
is @messages, 1, 'one message';
like $_, qr/^hello world [0-9]+/ for @messages;
is $out, '', 'nothing output';

$t->farm_context(10, '-G')->write_farm_script(
q/echo "hello world 1" >&2/,
q/echo "hello world 2" >&2/,
q/echo "hello world 3" >&2/,
q/echo "hello world 4" >&2/,
q/echo "hello world 5" >&2/,
q/echo "hello world 6" >&2/,
q/echo "hello world 7" >&2/,
q/echo "hello world 8" >&2/,
q/echo "hello world 9" >&2/,
q/echo "hello world 10" >&2/,
);

($out, $err) = $t->asub_farm_run_ok();

@messages = grep { m/^[^[]/ } split /\n/ => $err;
is @messages, 10, 'one message';
like $_, qr/^hello world [0-9]+/ for @messages;
is $out, '', 'nothing output';


done_testing;
