use strict;
use warnings;
use utf8;
use Test::More;

use t::Util;
use Workman::Queue::Qudo;
use Workman::Test::Queue;

my $qudo  = t::Util->setup();
my $queue = Workman::Queue::Qudo->new(qudo => $qudo);
my $test  = Workman::Test::Queue->new($queue);
# $test->verbose(1);
$test->run;
