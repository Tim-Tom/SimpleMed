use strict;
use warnings;

use Test::More tests => 38;

use SimpleMed::Logger;
use SimpleMed::Observer;

use subs qw(cu ci cra crr cs ca);

*cu = \&SimpleMed::Observer::compare_undef;
*ci = \&SimpleMed::Observer::compare_integer;
*cra = \&SimpleMed::Observer::compare_real_abs;
*crr = \&SimpleMed::Observer::compare_real_rel;
*cs  = \&SimpleMed::Observer::compare_string;
*ca = \&SimpleMed::Observer::compare_array;

is(cu(undef, undef), 0, 'compare_undef: undef both');
is(cu(undef, 1), 1, 'compare_undef: undef first');
is(cu(1, undef), 1, 'compare_undef: undef second');
is(cu(1, 1), undef, 'compare_undef: undef none');

ok(!ci(undef, undef), 'compare_integer: undef both');
ok( ci(undef, 1), 'compare_integer: undef first');
ok( ci(1, undef), 'compare_integer: undef second');
ok(!ci(1,1), 'compare_integer: same');
ok( ci(1, 2), 'compare_integer: diff');

ok(!cra(undef, undef, 0.005), 'compare_real_abs: undef both');
ok( cra(1.0, undef, 0.005), 'compare_real_abs: undef first');
ok( cra(undef, 1.0, 0.005), 'compare_real_abs: undef second');
ok(!cra(2.0, 2.0, 0.005), 'compare_real_abs: same');
ok(!cra(2.0, 1.996, 0.005), 'compare_real_abs: same, threshold low');
ok(!cra(2.0, 2.004, 0.005), 'compare_real_abs: same, threshold high');
ok(cra(2.0, 50, 0.005), 'compare_real_abs: diff');
ok(!cra(2.0, 50, 50), 'compare_real_abs: same, large threshold');

ok(!crr(undef, undef, 1e-6), 'compare_real_rel: undef both');
ok( crr(undef, 1.0, 1e-6), 'compare_real_rel: undef first');
ok( crr(1.0, undef, 1e-6), 'compare_real_rel: undef second');
ok(!crr(1e7, 1e7, 1e-6), 'compare_real_rel: same');
ok(!crr(1e7, 1e7-1, 1e-6), 'compare_real_rel: same, threshold low');
ok(!crr(1e7, 1e7+1, 1e-6), 'compare_real_rel: same, threshold high');
ok( crr(1e7, 1e7+1e6, 1e-6), 'compare_real_rel: diff');
ok(!crr(1e7, 1e7+1e6, 1e-1), 'compare_real_rel: same, large threshold');

ok(!cs(undef, undef), 'Compare_string: undef');
ok( cs(undef, 'cat'), 'compare_string: undef first');
ok( cs('cat', undef), 'compare_string: undef second');
ok(!cs('cat','cat'), 'compare_string: same');
ok( cs('cat', 'dog'), 'compare_string: diff');

ok(!ca(undef, undef, \&ci), 'compare_array: undef');
ok(ca(undef, [], \&ci), 'compare_array: undef first');
ok(ca([], undef, \&ci), 'compare_array: undef second');
ok(!ca([], [], \&ci), 'compare_array: empty arrays');
ok(ca([1,2,3], [1,2], \&ci), 'compare_array: different lengths');
ok(!ca([1,2,3], [1,2,3], \&ci), 'compare_array: same');
ok(ca([1,2,3], [1,2,4], \&ci), 'compare_array: different');
ok(!ca([qw(apple banana cantelope)], [qw(apple banana cantelope)], \&cs), 'compare_array: same string');
