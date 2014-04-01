use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use Time::Local;

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi. Google me.',
 contact     => 'usvi@IRCnet',
 name        => 'Timer script with disk backup',
 description => 'Add notification timers for tasks and important things. Adding multiple timers are possible.',
 license     => 'BSD',
 changed     => 'Sun Mar 30 21:19:12 EEST 2014'
);

my $timer_file = Irssi::get_irssi_dir . "/supertimer.dat";
my %timer_list = ();
my $timer_reference = 0;
my $msg_timer_set = "Ajastus asetettu";
my $msg_timeout_occurred = "Aika on kulunut";
my $msg_timer_deleted = "Viimeisin ajastus poistettu";
my $msg_timers_nuked = "Kaikki ajastukset poistettu";
my $timer_threshold_msecs = 2144505010;
my $housekeeping_period_msecs = 1000 * 3600 * 24;

sub load_timers
{
    open(timer_file_handle, "<", $timer_file);
    my $level = 0;
    my $network = "";
    my $channel = "";
    my $nick = "";
    my $temp_line = "";

    while($temp_line = readline(*timer_file_handle))
    {
	if($temp_line =~ /[ ]*\}[ ]*/)
	{
	    $level--;
	}
	elsif($level == 0)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$network = $1;
		$level++;
		$timer_list{$network} = ();
	    }
	}
	elsif($level == 1)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$channel = $1;
		$level++;
		$timer_list{$network}{$channel} = ();
	    }
	}
	elsif($level == 2)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$nick = $1;
		$level++;
		$timer_list{$network}{$channel}{$nick} = ();
	    }
	}
	elsif($level == 3)
	{
	    if($temp_line =~ /[ ]*([0-9]+)\:([0-9]+)\:(.*)\n/)
	    {
		if(($2 + 0) > time())
		{
		    $timer_list{$network}{$channel}{$nick}{$1} = "$2:$3";
		}
	    }
	}
    }
    close(timer_file_handle);
    sanitize_timers();
}


sub save_timers
{
    open(timer_file_handle, ">", $timer_file);

    for my $network ( keys %timer_list )
    {
	print(timer_file_handle $network . " = {\n");

        for my $channel ( keys %{$timer_list{$network}})
        {
	    print(timer_file_handle " " . $channel . " = {\n");

	    for my $nick ( keys %{$timer_list{$network}{$channel}})
	    {
		print(timer_file_handle "  " . $nick . " = {\n");

		foreach(sort(keys(%{$timer_list{$network}{$channel}{$nick}})))
		{
		    print(timer_file_handle "   " . $_ . ":" . $timer_list{$network}{$channel}{$nick}{$_} . "\n");
		}
		print(timer_file_handle "  }\n");
	    }
	    print(timer_file_handle " }\n");
        }
	print(timer_file_handle "}\n");
    }
    close(timer_file_handle);
}


sub list_timers
{
    my $i = 1;

    for my $network ( keys %timer_list )
    {
        print("Network: " . $network);

        for my $channel ( keys %{$timer_list{$network}})
        {
            print(" Channel: " . $channel);

	    for my $nick ( keys %{$timer_list{$network}{$channel}})
	    {
		print("  Nick: " . $nick);

		foreach(sort(keys(%{$timer_list{$network}{$channel}{$nick}})))
		{
		    print("   $i: " . $_ . ":" . $timer_list{$network}{$channel}{$nick}{$_});
		    $i++;
		}
	    }
        }
    }
}


#If called with params "network, nick", searches the latest addition by the user
#If called without params, searches the next timer that will trigger
sub get_next_timeout
{
    my @input_params = @_;
    my $next_time = 0;
    my @timeout_params;

    for my $network ( keys %timer_list )
    {
        for my $channel ( keys %{$timer_list{$network}})
        {
	    for my $nick ( keys %{$timer_list{$network}{$channel}})
	    {
		foreach(sort(keys(%{$timer_list{$network}{$channel}{$nick}})))
		{
		    my $temp_line = $timer_list{$network}{$channel}{$nick}{$_};

		    if($temp_line =~ /([0-9]+)\:(.*)/)
		    {
			# Nick search, searching for latest addition time
			if(@input_params == 2 && lc($input_params[0]) eq lc($network) && lc($input_params[1]) eq lc($nick) )
			{
			    if($next_time == 0 || ($_ + 0) > $next_time)
			    {
				@timeout_params = ($network, $channel, $nick, $_, $1, $2);
				$next_time = ($_ + 0);
			    }
			}
			# Next search, searching for next trigger time
			else
			{
			    if($next_time == 0 || ($1 + 0) < $next_time)
			    {
				@timeout_params = ($network, $channel, $nick, $_, $1, $2);
				$next_time = ($1 + 0);
			    }
			}
		    }
		}
	    }
        }
    }
    return @timeout_params;
}


sub activate_next_timer
{
    if($timer_reference != 0)
    {
	Irssi::timeout_remove($timer_reference);
	$timer_reference = 0;
    }
    my @timeout_params = get_next_timeout("", "");
    my $wait_time_msecs = 10 + ($timeout_params[4] - time()) * 1000;

    if(@timeout_params > 0 && $wait_time_msecs < $timer_threshold_msecs)
    {
	$timer_reference = Irssi::timeout_add_once($wait_time_msecs, 'announce_timer', join(":", @timeout_params));
    }
}


sub announce_timer
{
    my ($network, $channel, $nick, $add_time, $trig_time, $reason) = split(/\:/, $_[0], 6);

    if(my $server = Irssi::server_find_tag($network))
    {
	$server->command("MSG " . ($channel ne "private" ? "$channel $nick: " : "$nick ") . "$msg_timeout_occurred: $reason");
    }
    
    remove_timer($network, $channel, $nick, $add_time);
    sanitize_timers();
    save_timers();
    activate_next_timer();
}


sub remove_timer
{
    my ($network, $channel, $nick, $add_time) = @_;
    delete($timer_list{$network}{$channel}{$nick}{$add_time});
}


sub add_timer
{
    my ($network, $channel, $nick, $add_time, $trig_time, $reason) = @_;

    if(!exists($timer_list{$network}))
    {
	$timer_list{$network} = ();
    }
    if(!exists($timer_list{$network}{$channel}))
    {
	$timer_list{$network}{$channel} = ();
    }
    if(!exists($timer_list{$network}{$channel}{$nick}))
    {
	$timer_list{$network}{$channel}{$nick} = ();
    }
    $timer_list{$network}{$channel}{$nick}{$add_time} = "$trig_time:$reason";
}


sub sanitize_timers
{
    for my $network ( keys %timer_list )
    {
        for my $channel ( keys %{$timer_list{$network}})
        {
	    for my $nick ( keys %{$timer_list{$network}{$channel}})
	    {
		if(scalar(keys(%{$timer_list{$network}{$channel}{$nick}})) == 0)
		{
		    delete($timer_list{$network}{$channel}{$nick})
		}
	    }
	    if(scalar(keys(%{$timer_list{$network}{$channel}})) == 0)
	    {
		delete($timer_list{$network}{$channel})
	    }
	}
	if(scalar(keys(%{$timer_list{$network}})) == 0)
	{
	    delete($timer_list{$network})
	}
    }
}


sub check_for_commands
{
    my ($server, $msg, $nick, $mask, $channel) = @_;

    #if($msg =~ /^\!mk[ ]+/ || $msg =~ /^\!ajastin[ ]+/ || $msg =~ /^\!ajastus[ ]+/)
    if($msg =~ /^\!st[ ]+/)
    {
        $msg =~ s/^\![a-zA-Z]+//;
        $msg =~s/^[ ]+//;
        my $timestamp = 0;
	my $reason = "";
	my $command = "";
	# Trying 2014-04-03 16:34:41 Reason
	#        2014-04-03 16.34.41 Reason
	if($msg =~ /([0-9]{4})\-([0-9]{1,2})\-([0-9]{1,2})[ ]+([0-9]{1,2})[\:\.]([0-9]{1,2})[\:\.]([0-9]{1,2})(.*)/)
	{
	    $timestamp = timelocal($6, $5, $4, $3, $2 - 1, $1);
	    $reason = $7;
	    $command = "add";
	}
	# Trying 2014-04-03 16:34 Reason
	#        2014-04-03 16.34 Reason
	elsif($msg =~ /([0-9]{4})\-([0-9]{1,2})\-([0-9]{1,2})[ ]+([0-9]{1,2})[\:\.]([0-9]{1,2})(.*)/)
	{
	    $timestamp = timelocal(0, $5, $4, $3, $2 - 1, $1);
	    $reason = $6;
	    $command = "add";
	}
	# Trying 2014-04-03 Reason
	elsif($msg =~ /([0-9]{4})\-([0-9]{1,2})\-([0-9]{1,2})(.*)/)
	{
	    $timestamp = timelocal(0, 0, 0, $3, $2 - 1, $1);
	    $reason = $4;
	    $command = "add";
	}
	# Trying 60 Reason
	elsif($msg =~ /([0-9]{1,4})(.*)/)
	{
	    $timestamp = time() + $1 * 60;
	    $reason = $2;
	    $command = "add";
	}
	elsif($msg =~ /del[ ]*/)
	{
	    $command = "del";
	}
	elsif($msg =~ /nuke[ ]*/)
	{
	    $command = "nuke";
	}
	$reason =~ s/^\s+|\s+$//g;

	if($command eq "add" && ($timestamp > time()))
	{
	    #my ($network, $channel, $nick, $add_time, $trig_time, $reason) = @_;
	    add_timer($server->{tag}, ($channel ? $channel : "private"), $nick, time(), $timestamp, $reason);
	    sanitize_timers();
	    save_timers();
	    activate_next_timer();
	    $server->command("MSG " . ($channel ? "$channel $nick: " : "$nick ") . $msg_timer_set);
	}
	elsif($command eq "del")
	{
	    my @del_params = get_next_timeout($server->{tag}, $nick);

	    if(@del_params > 3)
	    {
		remove_timer($del_params[0], $del_params[1], $del_params[2], $del_params[3]);
		sanitize_timers();
		save_timers();
		activate_next_timer();
		$server->command("MSG " . ($channel ? "$channel $nick: " : "$nick ") . "$msg_timer_deleted: " . $del_params[5]);
	    }
	}
	elsif($command eq "nuke")
	{
	    my @del_params;

	    while((@del_params = get_next_timeout($server->{tag}, $nick)) > 3)
	    {
		remove_timer($del_params[0], $del_params[1], $del_params[2], $del_params[3]);
	    }
	    sanitize_timers();
	    save_timers();
	    activate_next_timer();
	    $server->command("MSG " . ($channel ? "$channel $nick: " : "$nick ") . $msg_timers_nuked);
	}
    }
}

sub do_housekeeping
{
    activate_next_timer();
}

Irssi::timeout_add($housekeeping_period_msecs, "do_housekeeping", "");

Irssi::command_bind("stload", "load_timers");
Irssi::command_bind("stprint", "list_timers");

Irssi::signal_add_last("message public", "check_for_commands");
Irssi::signal_add_last("message private", "check_for_commands");

load_timers();
activate_next_timer();
