package Workman::Queue::Qudo;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use parent qw/Workman::Queue/;
use Class::Accessor::Lite ro => [qw/qudo/];

use Workman::Job;
use Workman::Request;
use Qudo::Driver::Workman;

sub can_wait_job { 0 }

sub register_tasks {
    my ($self, $task_set) = @_;
    my @abilities = $task_set->get_all_task_names;
    $self->qudo->{manager_abilities} = \@abilities;
    $self->qudo->manager->register_abilities(@abilities);
    for my $db ($self->qudo->shuffled_databases) {
        my $driver  = $self->qudo->get_connection($db);
        my $wrapper = Qudo::Driver::Workman->new($driver, $task_set);
        $self->qudo->set_connection($db, $wrapper);
    }
    delete $self->qudo->manager->{_func_cache}; # XXX: reset func cache
}

sub enqueue {
    my ($self, $name, $args, $opt) = @_;
    $self->qudo->enqueue($name => {
        arg => $args,
        exists $opt->{uniqkey}      ? (uniqkey      => $opt->{uniqkey})      : (),
        exists $opt->{run_after}    ? (run_after    => $opt->{run_after})    : (),
        exists $opt->{priority}     ? (priority     => $opt->{priority})     : (),
        exists $opt->{suppress_job} ? (suppress_job => $opt->{suppress_job}) : (),
    });
    return Workman::Request->new(
        on_wait => sub {
            warn "[$$] Qudo hasn't support to wait result.";
            return;
        },
    );
}

sub dequeue {
    my $self = shift;

    my $job = $self->qudo->manager->find_job;
    return unless $job;

    $self->qudo->manager->call_hook('deserialize', $job);
    $self->qudo->manager->call_hook('pre_work',    $job);

    if ($job->funcname->set_job_status) {
        $job->job_start_time = time;
    }

    return Workman::Job->new(
        name    => $job->funcname,
        args    => $job->arg,
        on_done => sub {
            my $result = shift;
            warn "[$$] Qudo hasn't support to send result." if defined $result;

            if ($job->is_aborted) {
                $job->dequeue;
            }
            else {
                $job->completed;
            }

            $self->qudo->manager->call_hook('post_work', $job);
        },
        on_fail => sub {
            my $e = shift;

            if ($job->retry_cnt < $job->funcname->max_retries) {
                $job->reenqueue({
                    grabbed_until => 0,
                    retry_cnt     => $job->retry_cnt + 1,
                    retry_delay   => $job->funcname->retry_delay,
                });
            }
            else {
                $job->dequeue;
            }

            $job->failed(defined $e ? "$e" : 'Job did not explicitly complete or fail');
            $self->qudo->manager->call_hook('post_work', $job);
        },
        on_abort => sub {
            $job->abort;
            $job->dequeue;
            $self->qudo->manager->call_hook('post_work', $job);
        },
    );
}

sub dequeue_abort {} # nothing to do

package # hide from PAUSE
    Workman::Task;

use Qudo::Worker ();

# XXX: define required methods for Qudo
sub max_retries    { Qudo::Worker->max_retries    }
sub retry_delay    { Qudo::Worker->retry_delay    }
sub grab_for       { Qudo::Worker->grab_for       }
sub set_job_status { Qudo::Worker->set_job_status }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Workman::Queue::Qudo - Qudo's queue manager for Workman

=head1 SYNOPSIS

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


=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
