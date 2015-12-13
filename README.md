# NAME

Workman::Queue::Qudo - Qudo's queue manager for Workman

# SYNOPSIS

    use Workman::Queue::Qudo;
    my $qudo = Qudo->new(
        databases => [
            {
                dsn      => 'dbi:SQLite:dbname=:memory:',
                username => '',
                password => '',
            }
        ],
        default_hooks => [qw/Qudo::Hook::Serialize::JSON/],
    );
    my $queue = Workman::Queue::Qudo->new(qudo => $qudo);
    my $profile = Workman::Server::Profile->new(max_workers => 10, queue => $queue);
    $profile->set_task_loader(sub {
        my $set = shift;

        warn "[$$] register tasks...";
        my $task = Workman::Task->new(Echo => sub {
            my $args = shift;

            ...;

            return;
        });
        $set->add($task);
    });

    # start
    Workman::Server->new(profile => $profile)->run();

# DESCRIPTION

TODO

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
