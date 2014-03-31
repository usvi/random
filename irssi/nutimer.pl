use strict;

use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind active_win);

use Irssi;
$VERSION = '0.1.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Nutimer',
 description => 'Lets people set timers',
 license     => 'GPL',
 changed     => 'Thu May 27 00:14:03 EEST 2010'
);

# nick, server, channel, message, timer_tag, minutes
my @timer_data;
my $timer_max_time_secs = 100000;

sub timer_timeout
{
    my $timer_nick = shift(@_);

    for(my $i = 0; $i < @timer_data; $i++)
    {
	if($timer_data[$i][0] eq $timer_nick)
	{
	    $timer_data[$i][1]->command("MSG " . ($timer_data[$i][2] eq 0 ? $timer_data[$i][0] . " " : $timer_data[$i][2] . " " . $timer_data[$i][0] . ": ") .
					$timer_data[$i][5] . " minuuttia on kulunut: " . $timer_data[$i][3]);
	    splice(@timer_data, $i, 1);
	    return;
	}
    }
}

sub handle_timer_command
{
    my ($nick, $server, $channel, $msg) = @_;

    if($msg =~ /^poista/ || $msg =~ /^del/)
    {
	for(my $i = 0; $i < @timer_data; $i++)
	{
	    if($timer_data[$i][0] eq $nick)
	    {
		Irssi::timeout_remove($timer_data[$i][4]);
		splice(@timer_data, $i, 1);
		return "ajastus poistettiin";
	    }
	}
    }
    elsif($msg =~ /^(-{0}[0-9]+)/)
    {
	my $minutes = $1;
	$minutes =~ /^([0-9]+)/;
	$minutes = $1;

	if($minutes > $timer_max_time_secs || $minutes < 0)
	{
	    return;
	}
	$msg =~ s/^[0-9 ]+//;

	for(my $i = 0; $i < @timer_data; $i++)
	{
	    if($timer_data[$i][0] eq $nick)
	    {
		Irssi::timeout_remove($timer_data[$i][4]);
		splice(@timer_data, $i, 1);
		my @new_item = ($nick, $server, $channel, $msg , Irssi::timeout_add_once(10 + 1000 * 60 * $minutes, 'timer_timeout', $nick), $minutes);
		$timer_data[@timer_data] = \@new_item;
		return "ajastus muutettiin";
	    }
	}
	my @new_item = ($nick, $server, $channel, $msg , Irssi::timeout_add_once(10 + 1000 * 60 * $minutes, 'timer_timeout', $nick), $minutes);
	$timer_data[@timer_data] = \@new_item;
	return "ajastus asetettu";
    }
}


sub check_for_timer
{
    my ($server, $msg, $nick, $mask, $channel) = @_;

    if($msg =~ /^\!mk[ ]+/ || $msg =~ /^\!ajastin[ ]+/ || $msg =~ /^\!ajastus[ ]+/)
    {
	$msg =~ s/^\![a-zA-Z]+//;
	$msg =~s/^[ ]+//;
	my @cmd_args = ($nick, $server, ($channel ? $channel : 0), $msg);
	my $timer_result = handle_timer_command(@cmd_args);

	if($timer_result)
	{
	    $server->command("MSG " . ($channel ? $channel . " " . $nick . ":" : $nick) . " " . $timer_result);
	}
    }
}

Irssi::signal_add_last("message public", "check_for_timer");
Irssi::signal_add_last("message private", "check_for_timer");
