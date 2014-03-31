use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'Horationer',
 description => 'Messages CSI-like one-liner effects for known keywords',
 license     => 'GPL',
 changed     => 'Wed Dec 29 04:04:06 EET 2010'
);


# Plan
#
# Scenario 1 (trivial):
# *trigger*
# response
# Scenario 2 (hard):
# I think that *trigger*
# foo is bar
# response
#
# Strategy for scenario 2:
#
# Chatnet/Channel/Nick/Trigger status must be kept in memory.
# For every line not containing one of triggers try to shift the data
# structure for info. If something is received, print appropriate
# result.

my %trigger_list = ();
$trigger_list{"*lasit*"} = "YEAAAAH!";
$trigger_list{"*akulasit*"} = "yeees";

my %event_list = ();

sub add_trigger_event
{
    my ($network, $channel, $nick, $trigger) = @_;

    if (! $event_list{lc($network)})
    {
	$event_list{lc($network)} = ();
    }
    if (! $event_list{lc($network)}{lc($channel)})
    {
	$event_list{lc($network)}{lc($channel)} = ();
    }
    # Not in list. Add.
    $event_list{lc($network)}{lc($channel)}{lc($nick)} = $trigger;
}


sub print_event_list
{
    print("Pending trigger events:");

    for my $network ( keys %event_list)
    {
        print("Network: " . $network);

        for my $channel ( keys %{$event_list{$network}})
        {
            print(" Channel: " . $channel);

            for my $nick ( keys %{$event_list{$network}{$channel}})
	    {
		print("  Nick: " . $nick . " >" . $event_list{$network}{$channel}{$nick});
	    }
        }
    }
}

sub shift_event_list
{
    my ($network, $channel, $nick) = @_;

    if (! $event_list{lc($network)})
    {
	return;
    }
    if (! $event_list{lc($network)}{lc($channel)})
    {
	return;
    }
    if (! $event_list{lc($network)}{lc($channel)}{lc($nick)})
    {
	return;
    }
    # Try to return the trigger if specified on input.

    my $active_trigger = $event_list{lc($network)}{lc($channel)}{lc($nick)};

    # Now traverse backwards, delete empty stuff if necessary.
    # Delete because we dont want to clash different trigger returns.
    delete($event_list{lc($network)}{lc($channel)}{lc($nick)});

    if (scalar(keys(%{$event_list{lc($network)}{lc($channel)}})) == 0)
    {
	delete($event_list{lc($network)}{lc($channel)});
    }
    if (scalar(keys(%{$event_list{lc($network)}})) == 0)
    {
	delete($event_list{lc($network)});
    }
    return $active_trigger;
}


sub check_input
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];
    my $temp_network = $temp_server->{tag};

    # Check for trigger stuff first.
    
    for my $temp_trigger ( keys %trigger_list)
    {
	if (index($temp_message, $temp_trigger) > -1)
	{
	    # Match found. Update hierarchy last trigger.
	    add_trigger_event($temp_network, $temp_channel, $temp_nick, $temp_trigger);

	    if (($temp_message cmp $temp_trigger) == 0)
	    {
		# Direct match found. Purge last trigger from hierarchy. Also send the message.
		shift_event_list($temp_network, $temp_channel, $temp_nick);
		($temp_server->window_find_item($temp_channel))->command("MSG " . $temp_channel . " " . $trigger_list{$temp_trigger});
		Irssi::signal_stop();
	    }
	    return;
	}
    }
    my $active_trigger = shift_event_list($temp_network, $temp_channel, $temp_nick);

    if ($active_trigger)
    {
	($temp_server->window_find_item($temp_channel))->command("MSG " . $temp_channel . " " . $trigger_list{$active_trigger});
	Irssi::signal_stop();
	return;
    }
}

Irssi::command_bind("horatiolist", "print_event_list");
Irssi::signal_add_last("message public", "check_input");
