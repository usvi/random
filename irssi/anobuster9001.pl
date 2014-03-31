#use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi. Google me.',
 contact     => 'usv@IRCnet',
 name        => 'Ano Buster 9001',
 description => 'Busts anonymous from channels marked as anonymous. Yes, that means you also.',
 license     => 'GPL',
 changed     => 'Tue Jan 12 21:03:20 EET 2010'
);


my @scan_busted_nicks;
my @scan_remaining_nicks;
my $scan_bust_channel;
my $scan_lurk_channel;
my $scan_timer;
my $scan_test_interval = 10;
my $scan_last_nick;

sub cmd_bust_chan
{
    my ($data, $server, $witem) = @_;
    my $bust_channel;
    my $lurk_channel;
    my @test_nicks;


    $data =~ s/^\s+//;
    $data =~ s/\s+$//;

    if(!$server)
    {
	Irssi::print("No server");
	return;
    }
    if(!$data || !($bust_channel = $server->channel_find($data)) || !($bust_channel = Irssi::channel_find($data)))
    {
	Irssi::print("No valid channel name");
	return;
    }
    # Get current channel

    if(!$witem || !($witem->{type} eq "CHANNEL"))
    {
	Irssi::print("Current (lurk) channel is not valid");
	return;
    }
    $lurk_channel = $witem;
    # Get nicks for current channel
    @test_nicks = $bust_channel->nicks();


    # Check for previous stuff now that we might have a chance of survival


    if($scan_timer)
    {
	Irssi::timeout_remove($scan_timer);
	my $busted_nicks_string = "";

	foreach(@scan_busted_nicks)
	{
	    $busted_nicks_string .= $_ . " ";
	}
	Irssi::print("Aborting previous scan. So far, the following people from " . $scan_bust_channel->{name} .
		     " were also found to be lurking in " . $scan_lurk_channel->{name} . " : " .
		     $busted_nicks_string);
    }

    Irssi::print("Busting a maximum of " . @test_nicks . " " . $bust_channel->{name} . " nicks lurking in " .
		 $lurk_channel->{name} . " using test interval of " . $scan_test_interval . " seconds");
    # Load necessary stuff and set timer
    
    @scan_busted_nicks = ();
    @scan_remaining_nicks = @test_nicks;
    $scan_bust_channel = $bust_channel;
    $scan_lurk_channel = $lurk_channel;
    $scan_timer = Irssi::timeout_add($scan_test_interval * 1000, 'scan_timer_interrupt', 0);
}

sub scan_timer_interrupt
{
    if(@scan_remaining_nicks == 0)
    {
	Irssi::timeout_remove($scan_timer);
	my $busted_nicks_string = "";
	
	foreach(@scan_busted_nicks)
	{
	    $busted_nicks_string .= $_ . " ";
	}
	Irssi::print("Scan complete! The following people from " . $scan_bust_channel->{name} .
	    " are also lurking in " . $scan_lurk_channel->{name} . " : " . $busted_nicks_string);
	return;
    }
    my $temp_nick = pop(@scan_remaining_nicks);
    $scan_last_nick = $temp_nick->{nick};
    $scan_lurk_channel->command("deop " . $temp_nick->{nick});
}

sub check_return_msg
{
    my ($server, $data) = @_;
    my $action_no_op = 482;
    my $action_not_on_chan = 441;
    my $no_match_identifier = ":They aren't on that channel";
    my $channel;
    my $nick;
   
    # case in channel:
    # :irc.nebula.fi 482 jpaalija #opetuslapseni :You're not channel operator
    # case not in channel:
    # :irc.nebula.fi 441 jpaalija nick #opetuslapseni :They aren't on that channel
    my ($sender, $action, $target, $rest) = split(/ /, $data, 4);

    #Irssi::print("data $data");

    if($action == $action_not_on_chan)
    {
	($nick, $channel, $rest) = split(/ /, $rest, 3);
	
	if($channel eq $scan_lurk_channel->{name})
	{
	    Irssi::signal_stop();
	    #Irssi::print("nick $nick not lurking");
	}
    }
    elsif($action == $action_no_op)
    {
	($channel, $rest) = split(/ /, $rest, 2);

	if($channel eq $scan_lurk_channel->{name})
	{
	    Irssi::signal_stop();
	    Irssi::print("nick $scan_last_nick is lurking in " . $scan_lurk_channel->{name} . " !");
	    $scan_busted_nicks[@scan_busted_nicks] = $scan_last_nick;
	}
    }
    return;
}

Irssi::signal_add_first('server incoming', 'check_return_msg');
Irssi::command_bind('bustchan', \&cmd_bust_chan);
