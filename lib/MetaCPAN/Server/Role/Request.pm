package MetaCPAN::Server::Role::Request;

use Moose::Role;

around header => sub {
    my ($orig, $self) = (shift,shift);
    my $header = $self->$orig(@_);
    return unless($header);
    return $header eq 'application/x-www-form-urlencoded' ? 'application/json' : $header;
};

1;