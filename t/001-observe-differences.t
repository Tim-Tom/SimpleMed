use strict;
use warnings;

use Test::More tests => 5;

use SimpleMed::Logger;

# Create null logger for now.
$SimpleMed::Logger::Logger = bless { adapters => [] }, 'SimpleMed::Logger';

use_ok 'SimpleMed::Observer';

my $int_cmp = SimpleMed::Observer::observe_integer('int');
my $abs_cmp = SimpleMed::Observer::observe_real_abs('real absolute');
my $rel_cmp = SimpleMed::Observer::observe_real_rel('real relative');
my $str_cmp = SimpleMed::Observer::observe_string('string');
ok(defined $int_cmp, 'Int compare exists');
ok(defined $abs_cmp, 'Real compare (absolute) exists');
ok(defined $rel_cmp, 'Real compare (relative) exists');
ok(defined $str_cmp, 'String compare exists');
