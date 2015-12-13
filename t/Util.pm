package t::Util;
use strict;
use warnings;

use parent qw/Test::Builder::Module/;

use Qudo;
use Qudo::Test;

my $SCHEMA = Qudo::Test::load_schema();

sub setup {
    my $qudo = eval {
        Qudo->new(
            databases => [
                {
                    dsn      => 'dbi:SQLite:dbname=:memory:',
                    username => '',
                    password => '',
                }
            ],
            default_hooks => [qw/Qudo::Hook::Serialize::JSON/],
        );
    };
    if ($@) {
        __PACKAGE__->builder->diag($@);
        __PACKAGE__->builder->plan(skip_all => 'Could not setup sqlite');
    }

    my $dbh = $qudo->get_connection('dbi:SQLite:dbname=:memory:')->dbh;
    for my $sql (@{ $SCHEMA->{SQLite} }) {
        $dbh->do($sql);
    }

    return $qudo;
}

1;
__END__
