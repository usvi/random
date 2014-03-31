use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi. Google me.',
 contact     => 'usvi@IRCnet',
 name        => 'Simple relay',
 description => 'Relays messages to/from different networks and channels.',
 license     => 'GPL',
 changed     => 'Wed Mar 28 01:30:50 CST 2012'
);

my $srelay_conf_file = Irssi::get_irssi_dir . "/srelay.dat";
my %relays = ();

# Conf file format:
#
# relayname1 = {
#  network1 / channel1
#  network2 / channel1
# }
# relayname2 = {
#  network1 / channel2
#  network2 / channel2
# }

sub load_relays
{
    open(relay_file_handle, "<", $srelay_conf_file);
    my $level = 0;
    my $relay = "";
    my $net_chan = "";
    my $temp_line = "";

    while($temp_line = readline(*relay_file_handle))
    {
	if($temp_line =~ /[ ]*\}[ ]*/)
	{
	    $level--;
	}
	elsif($level == 0)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$relay = $1;
		$level++;
		$relays{$relay} = [];
	    }
	}
	elsif($level == 1)
	{
	    if($temp_line =~ /[ ]*([^ \/]+)[ ]*\/[ ]*([^ ]+)[ ]*\n/)
	    {
		$net_chan = "$1 / $2";
		push (@{$relays{$relay}}, $net_chan);
	    }
	}
    }
    close(invite_file_handle);
}

sub save_relays
{
    open(relay_file_handle, ">", $srelay_conf_file);
    
    for my $relay ( keys %relays )
    {
        print(relay_file_handle $relay . " = {\n");

        for my $net_chan (@{$relays{$relay}})
        {
            print(relay_file_handle " " . $net_chan . "\n");
        }
        print(relay_file_handle "}\n");
    }
    close(relay_file_handle);
}

sub list_relays
{
    my $i = 1;

    for my $relay ( keys %relays )
    {
	print("Relay: " . $relay);

	foreach(@{$relays{$relay}})
	{
	    print("  $i: " . $_);
	    $i++;
	}
    }
}

sub add_relay
{
    my ($args, $server, $witem) = @_;
    my @arg_array = split(/ +/, $args);
    
    if(@arg_array != 3)
    {
        print("Parameter error. Use arguments: relayname network #channel");
        return;
    }
    my $add_relay = "";

    for my $relay ( keys %relays )
    {
        if(lc($relay) eq lc($arg_array[0]) && $add_relay eq "")
        {
            $add_relay = $relay;
        }
    }
    if($add_relay eq "")
    {
        $add_relay = $arg_array[0];
        $relays{$add_relay} = [];
    }
    my $add_net_chan = $arg_array[1] . " / " . $arg_array[2];
    # make duplicate check here!
    push (@{$relays{$add_relay}}, $add_net_chan);
    #save_relays();
    print("Added $add_net_chan for relay $add_relay");
    save_relays();
}

sub remove_relay
{
    my ($args, $server, $witem) = @_;
    my $i = 1;
    my @arg_array = split(/ +/, $args);
    
    if(@arg_array != 1)
    {
        print("Parameter error. Use index number as argument.");
        return;
    }
    my $remove_index = $arg_array[0];

    for my $relay ( keys %relays )
    {
	my $j = 0;

	for($j = 0; $j < @{$relays{$relay}}; $j++)
	{
	    if ($i == $remove_index)
	    {
		print("Removing " . ${$relays{$relay}}[$j] . " from relay " . $relay);
		splice(@{$relays{$relay}}, $j, 1);
		
		# Might have empty collections now
		
		if(@{$relays{$relay}} == 0)
		{
		    delete($relays{$relay});
		}
		return;
	    }
	    $i++;
	}
    }
    save_relays();
}

sub check_for_relayables
{
    my ($server, $msg, $nick, $address, $channel) = @_;

    for my $relay ( keys %relays )
    {
	foreach(@{$relays{$relay}})
	{
	    my $received_net_chan = lc($server->{tag}) . " / " . lc($channel);

	    if(lc($_) eq $received_net_chan)
	    {
		foreach(@{$relays{$relay}})
		{
		    # Message found. Send to all channels but the originating one.

		    if(lc($_) ne $received_net_chan)
		    {
			my ($relay_net, $relay_chan) = split(/ \/ /, $_);
			my $relay_server = Irssi::server_find_tag($relay_net);
			my $relay_nick = "<" . $nick . ">";
			my $relay_msg = $msg;

			if($relay_server)
			{
			    $relay_server->command("MSG " . $relay_chan . " " . $relay_nick . " " . $relay_msg);
			}
		    }
		}
	    }
	}
    }
}

Irssi::signal_add_last("message public", "check_for_relayables");

Irssi::command_bind("srload", "load_relays");
Irssi::command_bind("srsave", "save_relays");
Irssi::command_bind("srlist", "list_relays");
Irssi::command_bind("sradd", "add_relay");
Irssi::command_bind("srdel", "remove_relay");

load_relays();
