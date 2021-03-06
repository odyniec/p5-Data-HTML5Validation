package Data::HTML5Validation;

use strict;
use warnings;

# ABSTRACT: Validate (and sanitize) data like HTML5 does

# VERSION

BEGIN {
    our @EXPORT_OK = qw(validate);

    require Exporter;
    *import = \&Exporter::import;
}

=head1 SYNOPSIS

    use Data::HTML5Validation qw(validate);

    my $constraints = {
        email        => { type => 'email',    required => 1 },
        name         => { type => 'text'                    },
        accept_terms => { type => 'checkbox', required => 1 }
    };

    $result = validate({
        email        => '   somebody@example.com',
        name         => '',
    }, $constraints);

    # $result: {
    #     email => {
    #         valid     => 1,
    #         sanitized => 'somebody@example.com'
    #     },
    #     name => {
    #         valid => 1
    #     },
    #     accept_terms => {
    #         valid         => 0,
    #         value_missing => 1
    #     }
    # }

    $result = validate('I am not an email', { type => 'email' });

    # $result: {
    #     valid         => 0,
    #     sanitized     => 'I am not an email',
    #     type_mismatch => 1
    # }

=cut

my $handlers;

=func validate

Validates the provided value or data structure and returns the results.

    $result = validate($value, $constraints);

=cut

sub validate {
    my ($data, $constraints, $result) = @_;

    if (!ref($data)) {
        # A single scalar value
        my $value = $data;

        $result = { valid => 1 };

        # Is a type constraint present, and do we know how to handle it?
        if (exists $constraints->{type} &&
            exists $handlers->{'type:' . $constraints->{type}})
        {
            # Do type-specific validation
            my $handler = $handlers->{'type:' . $constraints->{type}};
            $handler->($data, $constraints, $result);

            # Use the sanitized value in subsequent checks
            $value = $result->{sanitized};
        }

        for my $constraint (keys %$constraints) {
            if (exists $handlers->{$constraint}) {
                $result = $handlers->{$constraint}->($value, $constraints,
                    $result);

                # Use the sanitized value in subsequent checks
                $value = $result->{sanitized};
            }
        }

        # In list context, return the result structure and a boolean value;
        # in scalar context, return the result structure
        return wantarray ? ($result, $result->{valid}) : $result;
    }
    elsif (ref($data) eq 'ARRAY') {
        # TODO: Validate an array of values, return an array of results
    }
    elsif (ref($data) eq 'HASH') {
        # A hashref of data -- validate one by one
        $result = {};

        for my $name (keys %$constraints) {
            $result->{$name} = validate($data->{$name}, $constraints->{$name});
        }

        # In list context, return the result structure and a boolean value;
        # in scalar context, return the result structure
        return wantarray ?
            ($result, 0 + !grep { $_->{valid} == 0 } values %$result) :
            $result;
    }
}

$handlers = {
    'type:email' => sub {
        my ($value, $constraints, $result) = @_;
        
        my $email_re = qr/
            ^[a-zA-Z0-9.!\#$%&'*+\/=?^_`{|}~-]+
            @[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?
            (?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$
        /x;

        if ($constraints->{multiple}) {
            # Multiple email addresses
            
            # TODO
        }
        else {
            # A single email address

            # Sanitize
            $value =~ y/\r\n//d;        # Strip line breaks
            $value =~ s/^\s*|\s*$//g;   # Strip leading and trailing whitespace

            # Validate
            if ($value ne '' && $value !~ m/$email_re/) {
                $result->{valid} = 0;
                $result->{type_mismatch} = 1;
            }
        }

        $result->{sanitized} = $value;

        return $result;
    },
    'type:number' => sub {
        my ($value, $constraints, $result) = @_;

        my $number_re = qr{^
            - ?                         # Optional minus sign
            [0-9]*                      # A series of ASCII digits 
            (?: \. [0-9]+ )?            # "." and a series of ASCII digits
            (?: [eE] [-+]? [0-9]+ )?    # "e" or "E", optional +/-, ASCII digits
        $}x;

        # Validate
        if ($value ne '' && $value !~ m/$number_re/) {
            $result->{valid} = 0;
            $result->{bad_input} = 1;
        }

        $result->{sanitized} = $value;

        return $result;
    },
    'required' => sub {
        my ($value, $constraints, $result) = @_;

        if ($value eq '') {
            $result->{valid} = 0;
            $result->{value_missing} = 1;
        }

        $result->{sanitized} = $value;

        return $result;
    }
};

1;
