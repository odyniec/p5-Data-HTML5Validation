#!perl

use Test::Deep;
use Test::More;

BEGIN {
    use_ok('Data::HTML5Validation', qw(validate));
}

cmp_deeply(
    scalar validate('', { type => 'email' }),
    superhashof({ valid => 1 }),
    'Empty email is considered valid'
);

cmp_deeply(
    scalar validate('', { type => 'email', required => 1 }),
    superhashof({ valid => 0, value_missing => 1 }),
    'Empty required email is considered invalid'
);

done_testing;
