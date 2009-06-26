#!/usr/bin/perl -w

use strict;

use Prophet::Test tests => 6;
use App::SD::Test;
use Prophet::Util;
use File::Temp qw/tempdir/;
use Term::ANSIColor;

no warnings 'once';

BEGIN {
    require File::Temp;
    $ENV{'PROPHET_REPO'} = $ENV{'SD_REPO'} = File::Temp::tempdir( CLEANUP => 1 ) . '/_svb';
    diag "export SD_REPO=".$ENV{'PROPHET_REPO'} ."\n";
}

run_script( 'sd', [ 'init']);

my $replica_uuid = replica_uuid;

# create from sd
my ($ticket_id, $ticket_uuid) = create_ticket_ok( '--summary', 'YATTA');

sub check_output_with_history {
    my @extra_args = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

TODO: {
    local $TODO = "Sometimes, the ordering doesn't work right on sqlite";
    run_output_matches( 'sd', [ 'ticket', 'show', $ticket_id, @extra_args ],
        [
            '',
            '= METADATA',
            '',
            qr/^id:\s+$ticket_id \($ticket_uuid\)$/,
            qr/summary:\s+YATTA/,
            qr/status:\s+new/,
            qr/milestone:\s+alpha/,
            qr/component:\s+core/,
            qr/^created:\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
            qr/^creator:\s+$ENV{PROPHET_EMAIL}$/,
            qr/reporter:\s+$ENV{PROPHET_EMAIL}$/,
            qr/original_replica:\s+$replica_uuid$/,
            '',
            '= HISTORY',
            '',
            qr/^ $ENV{PROPHET_EMAIL} at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\s+\(\d+\@$replica_uuid\)$/,
            "  + \"original_replica\" set to \"$replica_uuid\"",
            "  + \"creator\" set to \"$ENV{PROPHET_EMAIL}\"",
            '  + "status" set to "new"',
            "  + \"reporter\" set to \"$ENV{PROPHET_EMAIL}\"",
            qr/^  \+ "created" set to "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"$/,
            '  + "component" set to "core"',
            '  + "summary" set to "YATTA"',
            '  + "milestone" set to "alpha"',
            '',
        ]
    );
}
}


sub check_output_without_history {
    my @extra_args = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    run_output_matches( 'sd', [ 'ticket', 'show', $ticket_id, @_],
        [
            '',
            '= METADATA',
            '',
            qr/^id:\s+$ticket_id \($ticket_uuid\)$/,
            qr'summary:\s+YATTA',
            qr'status:\s+new', 
            qr'milestone:\s+alpha',
            qr'component:\s+core',
            qr/^created:\s+\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/,
            qr/^creator:\s+$ENV{PROPHET_EMAIL}$/,
            qr/reporter:\s+$ENV{PROPHET_EMAIL}$/,
            qr/original_replica:\s+$replica_uuid$/,
        ]
    );
}

diag('default (shows history)');

check_output_with_history();

diag("passing --skip history (doesn't show history)");

check_output_without_history('--skip-history');

my $config_filename = $ENV{'SD_REPO'} . '/config';
Prophet::Util->write_file(
    file => $config_filename, content => '
[ticket "show"]
    disable-history = true
');
$ENV{'SD_CONFIG'} = $config_filename;

diag("config option ticket.show.disable-history set");
diag("(shouldn't show history)");

check_output_without_history();

diag("config option ticket.show.disable-history set");
diag("and --skip-history passed (shouldn't show history)");

check_output_without_history('--skip-history');

# config option set and --with-history passed (should show history)
diag('config option ticket.show.disable-history set');
diag('and --with-history passed (should show history)');

check_output_with_history('--with-history');
