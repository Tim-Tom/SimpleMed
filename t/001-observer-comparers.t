use strict;
use warnings;

use Test::More tests => 38;

use SimpleMed::Logger;
use SimpleMed::Observer qw(:compare);

is(compare_undef(undef, undef), 0, 'compare_undef: undef both');
is(compare_undef(undef, 1), 1, 'compare_undef: undef first');
is(compare_undef(1, undef), 1, 'compare_undef: undef second');
is(compare_undef(1, 1), undef, 'compare_undef: undef none');

ok(!compare_integer(undef, undef), 'compare_integer: undef both');
ok( compare_integer(undef, 1), 'compare_integer: undef first');
ok( compare_integer(1, undef), 'compare_integer: undef second');
ok(!compare_integer(1,1), 'compare_integer: same');
ok( compare_integer(1, 2), 'compare_integer: diff');

ok(!compare_real_abs(undef, undef, 0.005), 'compare_real_abs: undef both');
ok( compare_real_abs(1.0, undef, 0.005), 'compare_real_abs: undef first');
ok( compare_real_abs(undef, 1.0, 0.005), 'compare_real_abs: undef second');
ok(!compare_real_abs(2.0, 2.0, 0.005), 'compare_real_abs: same');
ok(!compare_real_abs(2.0, 1.996, 0.005), 'compare_real_abs: same, threshold low');
ok(!compare_real_abs(2.0, 2.004, 0.005), 'compare_real_abs: same, threshold high');
ok(compare_real_abs(2.0, 50, 0.005), 'compare_real_abs: diff');
ok(!compare_real_abs(2.0, 50, 50), 'compare_real_abs: same, large threshold');

ok(!compare_real_rel(undef, undef, 1e-6), 'compare_real_rel: undef both');
ok( compare_real_rel(undef, 1.0, 1e-6), 'compare_real_rel: undef first');
ok( compare_real_rel(1.0, undef, 1e-6), 'compare_real_rel: undef second');
ok(!compare_real_rel(1e7, 1e7, 1e-6), 'compare_real_rel: same');
ok(!compare_real_rel(1e7, 1e7-1, 1e-6), 'compare_real_rel: same, threshold low');
ok(!compare_real_rel(1e7, 1e7+1, 1e-6), 'compare_real_rel: same, threshold high');
ok( compare_real_rel(1e7, 1e7+1e6, 1e-6), 'compare_real_rel: diff');
ok(!compare_real_rel(1e7, 1e7+1e6, 1e-1), 'compare_real_rel: same, large threshold');

ok(!compare_string(undef, undef), 'Compare_string: undef');
ok( compare_string(undef, 'cat'), 'compare_string: undef first');
ok( compare_string('cat', undef), 'compare_string: undef second');
ok(!compare_string('cat','cat'), 'compare_string: same');
ok( compare_string('cat', 'dog'), 'compare_string: diff');

ok(!compare_array(undef, undef, \&compare_integer), 'compare_array: undef');
ok(compare_array(undef, [], \&compare_integer), 'compare_array: undef first');
ok(compare_array([], undef, \&compare_integer), 'compare_array: undef second');
ok(!compare_array([], [], \&compare_integer), 'compare_array: empty arrays');
ok(compare_array([1,2,3], [1,2], \&compare_integer), 'compare_array: different lengths');
ok(!compare_array([1,2,3], [1,2,3], \&compare_integer), 'compare_array: same');
ok(compare_array([1,2,3], [1,2,4], \&compare_integer), 'compare_array: different');
ok(!compare_array([qw(apple banana cantelope)], [qw(apple banana cantelope)], \&compare_string), 'compare_array: same string');
