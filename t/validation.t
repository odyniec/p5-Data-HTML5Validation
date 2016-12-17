#!perl

use Test::Deep;
use Test::More;

BEGIN {
    use_ok('Data::HTML5Validation', qw(validate));
}

sub check_value {
    my ($value, $constraints, $expected, $name) = @_;

    return cmp_deeply(scalar validate($value, $constraints), superhashof($expected),
        $name);
}

check_value '',
    { type => 'number' },
    { valid => 1 },
    'Empty number is considered valid';

check_value '',
    { type => 'number', required => 1 },
    { valid => 0, value_missing => 1 },
    'Empty required number is considered invalid';

check_value '123',
    { type => 'number' },
    { valid => 1 },
    'Positive integer is considered valid';

check_value '-123',
    { type => 'number' },
    { valid => 1 },
    'Negative integer is considered valid';

check_value '123.456',
    { type => 'number' },
    { valid => 1 },
    'Positive floating-point number is considered valid';

check_value '-123.456',
    { type => 'number' },
    { valid => 1 },
    'Negative floating-point number is considered valid';

check_value '12e3',
    { type => 'number' },
    { valid => 1 },
    'Scientific notation number is considered valid';

check_value '-12e-3',
    { type => 'number' },
    { valid => 1 },
    'Negative scientific notation number with negative exponent is ' .
        'considered valid';

check_value '',
    { type => 'email' },
    { valid => 1 },
    'Empty email is considered valid';

check_value '',
    { type => 'email', required => 1 },
    { valid => 0, value_missing => 1 },
    'Empty required email is considered invalid';

check_value 'foo',
    { type => 'email' },
    { valid => 0, type_mismatch => 1 },
    'An invalid email is considered, well, invalid';

check_value 'example@example.com',
    { type => 'email' },
    { valid => 1 },
    'A valid email is recognized as valid';

check_value "   \r\n   ",
    { type => 'email' },
    { valid => 1, sanitized => '' },
    'Whitespace is correctly sanitized for non-required email';

check_value "  example\r\n\@example.com   ",
    { type => 'email' },
    { valid => 1, sanitized => 'example@example.com' },
    'Email with whitespace is correctly validated and sanitized';

check_value undef,
    { type => 'checkbox' },
    { valid => 1 },
    'Undefined checkbox is considered valid';

check_value undef,
    { type => 'checkbox', required => 1 },
    { valid => 0, value_missing => 1 },
    'Undefined required checkbox is considered invalid';

done_testing;
