# -*- mode: perl; -*-
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::asub;
no lib 't/lib';

Test::asub->new->asub_compile_ok->asub_help_ok;

done_testing;
