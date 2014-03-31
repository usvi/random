use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.1.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Start log',
 description => '/lastlogs data from windows to file and starts logging to same file',
 license     => 'GPL',
 changed     => 'Mon Feb 25 17:51:52 EET 2008'
);

use Irssi;
use POSIX;
use File::Path;
#use Irssi::TextUI;
my $irssi_levels = "CRAP MSGS PUBLIC NOTICES SNOTES CTCPS ACTIONS JOINS PARTS QUITS KICKS MODES TOPICS WALLOPS INVITES NICKS DCC DCCMSGS CLIENTNOTICES CLIENTERRORS CLIENTCRAP";

sub cmd_startlog
{
    my ($args, $server, $witem) = @_;
    my @arg_array = split(/ +/, $args);
#    my $win = ref $witem ? $witem->window() : Irssi::active_win();

# we must first get necessarily targets and server

    my $noopen = 0;
    my $autoopen = 0;
    my $window = 0;
    my $colors = 0;
    my $log_server_tag = "";
    my @message_levels;
    my @targets;
    my $log_file_mask = "";
    my $continue = 1;

    for(my $i = @arg_array - 1; $i >= 0 && $continue; $i--)
    {
	if(index(" " . lc($irssi_levels) . " ", " " . lc($arg_array[$i]) . " ") != -1)
	{
	    push(@message_levels, $arg_array[$i]);
	    $arg_array[$i] = "";
	}
	else
	{
	    $log_file_mask = $arg_array[$i];
	    $arg_array[$i] = "";
	    $continue = 0;
	}
    }
    @arg_array = split(/ +/, join(" ", @arg_array));
    $continue = 1;

    for(my $i = 0; $i < @arg_array && $continue; $i++)
    {
	if(lc($arg_array[$i]) eq "-targets")
	{
	    $arg_array[$i] = "";

	    for(my $j = $i + 1; $j < @arg_array; $j++)
	    {
		if(!(substr($arg_array[$j], 0, 1) eq "-"))
		{
		    push(@targets, lc($arg_array[$j]));
		    $arg_array[$j] = "";
		}
		else
		{
		    $continue = 0;
		}
	    }
	}
    }
    @arg_array = split(/ +/, join(" ", @arg_array));

    for(my $i = 0; $i < @arg_array  && $continue; $i++)
    {
	if(lc($arg_array[$i]) eq "-noopen")
	{
	    $arg_array[$i] = "";
	    $noopen = 1;
	}
	elsif(lc($arg_array[$i]) eq "-autoopen")
	{
	    $arg_array[$i] = "";
	    $autoopen = 1;
	}
	elsif(lc($arg_array[$i]) eq "-window")
	{
	    $arg_array[$i] = "";
	    $window = 1;
	}
	elsif(lc($arg_array[$i]) eq "-colors")
	{
	    $arg_array[$i] = "";
	    $colors = 1;
	}
    }
    @arg_array = split(/ +/, join(" ", @arg_array));

    if(@arg_array >= 2)
    {
	print("malformed parameters");
	return;
    }
    elsif(substr($arg_array[0], 0, 1) eq "-")
    {
	$log_server_tag = $arg_array[0];
	$log_server_tag =~ s/^\-//;
    }
    else
    {
	;
    }
    my $server;

    if($log_server_tag eq "")
    {
	# TODO: this and following stuff might need fixing.
	# if server is not specified, should we try to
	# find out all windows of some name?
	$server = Irssi::active_server();
    }
    elsif($server = Irssi::server_find_tag($log_server_tag))
    {
	;
    }
    else
    {
	print("no such server:" . $log_server_tag);
	return;
    }
    my $initial_log_file = strftime($log_file_mask, localtime(time()));
    my $initial_log_dir = $initial_log_file;
    $initial_log_dir =~ s/\/[^\/]*$//;
 
    # TODO: check errors
    mkpath(glob($initial_log_dir), 0, 0777);

    Irssi::active_win()->change_server($server);

    foreach(@targets)
    {
	# TODO: maybe check, if channel already logged, if so, dont lastlog to it
	$server->command("LASTLOG - -file " . $initial_log_file  . " -window " . $_ . " " .
			 (@message_levels == 0 ? "" : " -" . join(" -", @message_levels)) . " ");
    }

    $server->command("LOG OPEN " . "-autoopen " .
		     ($log_server_tag eq "" ? "" : "-" . $log_server_tag . " ") .
		     " -targets \'" . join(" ", @targets) . "\' " .
		     ($colors == 0 ? "" : "-colors ") .
		     $log_file_mask . join(" ", @message_levels));
    
}

Irssi::command_bind('startlog', 'cmd_startlog');
