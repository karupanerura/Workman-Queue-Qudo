package Qudo::Driver::Workman;
use strict;
use warnings;

sub new {
    my ($class, $super, $task_set) = @_;
    return bless [$super, $task_set] => $class;
}

sub func_from_name {
    my ($self, $funcname) = @_;
    my $row = $self->[0]->func_from_name($funcname);
    $row->{name} = $self->[1]->get_task($row->{name});
    return $row;
}

sub func_from_id {
    my ($self, $funcid) = @_;
    my $row = $self->[0]->func_from_id($funcid);
    $row->{name} = $self->[1]->get_task($row->{name});
    return $row;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    (my $method = $AUTOLOAD) =~ s/^.+://;
    return $self->[0]->$method(@_);
}

1;
__END__
