use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'New grep',
 description => 'This script is a better (IMHO :) implementation of the old grep script',
 license     => 'GPL',
 other       => 'Parts from http://irssi.org/scripts/html/crapbuster.pl.html',
 changed     => 'Thu Jun 14 23:41:55 EEST 2007'
);

use Irssi;
use Irssi::TextUI;

my $LEVEL_LASTLOG_LOCAL = 134217728; # lastlog level
my $GREP_SEPARATOR = "---------";

# Instructions:
#
# Command:
# /ngrep [<switches>] <pattern>
#
# <switches>:
# -b <num>  Print a maximum of <num> lines before match
# -a <num>  Print a maximum of <num> lines after match
# -i        Ignore case
# -n        Don't highlight the match
#
# <pattern>:
# Normal perl regexp pattern. No need to use quotes. Spaces should be ok.
#
# Clear:
# Output of the grep script can be cleared with /lastlog -clear
#
# Bugs:
# must be guarded in case of there are messages arriving in the middle of grep
# FIXED: must escape url-escapes of form %something to %%something in prints
# FIXED: must sanitize input from causing infinite loops
# FIXED: remove system commands and plog sub

sub cmd_ngrep
{
    my ($args, $server, $witem) = @_;
    my @arg_array = split(/ +/, $args);
    my $win = ref $witem ? $witem->window() : Irssi::active_win();

    # getting settings

    my $hilight = 1;
    my $after = 0;
    my $before = 0;
    my $ignore_case  = 1;
    my $pattern_beginning = 0;

    for(my $i = 0; $i <= @arg_array - 1; $i++)
    {
	if(($arg_array[$i] cmp "-a") == 0)
	{
	    if(defined($arg_array[$i + 1]) &&
	       $arg_array[$i + 1] =~ m/[0-9]+/)
	    {
		$after = $arg_array[$i + 1];
		$pattern_beginning += 2;
		$after = $after < 0 ? 0 : $after;
		$i++;
	    }
	    else
	    {
		Irssi::print("param error", $LEVEL_LASTLOG_LOCAL);
		return;
	    }
	}
	elsif(($arg_array[$i] cmp "-b") == 0)
	{
	    if(defined($arg_array[$i + 1]) &&
	       $arg_array[$i + 1] =~ m/[0-9]+/)
            {
		$before = $arg_array[$i + 1];
		$pattern_beginning += 2;
		$before = $before < 0 ? 0 : $before;
		$i++;
	    }
	    else
	    {
		Irssi::print("param error", $LEVEL_LASTLOG_LOCAL);
		return;
	    }
	}
	elsif(($arg_array[$i] cmp "-n") == 0)
	{
	    $hilight = 0;
	    $pattern_beginning++;
	}
	elsif(($arg_array[$i] cmp "-i") == 0)
	{
	    $ignore_case = 1;
	    $pattern_beginning++;
	}
	elsif($arg_array[$i] =~ m/^\-.*/)
	{
	    Irssi::print("param error", $LEVEL_LASTLOG_LOCAL);
	    return;
	}
    }
    if(!defined($arg_array[$pattern_beginning]))
    {
	Irssi::print("param error", $LEVEL_LASTLOG_LOCAL);
	return;
    }
    my $pattern = "";

    for(my $i = $pattern_beginning; $i <= @arg_array - 1; $i++)
    {
	$pattern .= $arg_array[$i] . " ";
    }
    $pattern =~ s/\ $//;

    my $NOT_FOUND = 100000; # Identifier for not found match.
    my @grep_buffer;
    my @print_buffer;
    my $last_found = $NOT_FOUND;
    my $line = $win->view()->get_lines();

    while(defined($line))
    {
	if($line->{info}{level} == $LEVEL_LASTLOG_LOCAL) # Ignoring our lastlog lines.
	{
	    $line = $line->next;
	    next;
	}
	$last_found++;

	if(($ignore_case == 1 && $line->get_text(0) =~ m/$pattern/i) ||
	    ($ignore_case != 1 && $line->get_text(0) =~ m/$pattern/))
	{
	    # Grep pattern found. Add.

	    $last_found = 0;
	    my $text = $line->get_text(0);
	    $text =~ s/%/%%/; # Fix for unwanted hilights.

	    if($hilight == 1)
	    {
		$text =~ s/($pattern)/%9\1%9/;
	    }
	    push(@grep_buffer, $text);
	}
	else
	{
	    # No hilight, add to grep buffer.
	    my $text = $line->get_text(0);
	    $text =~ s/%/%%/; # Fix for unwanted hilights.
	    push(@grep_buffer, $text);
	}
	# Check to see if we can decrease the grep buffer from up.
	# Decreasing takes place when a value has not yet been found
	# and the length of the buffer is bigger than $before.

	if($last_found >= $NOT_FOUND && @grep_buffer > $before)
	{
	    shift(@grep_buffer);
	}

	# Check to see if there is enough stuff after the last found occurence.
	# If there is, merge.

	if($last_found < $NOT_FOUND &&
	   ($last_found >= $after  || !defined($line->next())))
	{
	    # Testing the case for further findings that match pattern.
	    # If ones are found close enough, the grep buffer isn't merged just yet.

	    my $ok_to_merge = 1;
	    my $temp_line = $line;

	    for(my $j = 1; $j <= $before + 1 && defined($temp_line->next()) ; $j++)
	    {
		$temp_line = $temp_line->next();

		if(($ignore_case == 1 && $temp_line->get_text(0) =~ m/$pattern/i) ||
		   ($ignore_case != 1 && $temp_line->get_text(0) =~ m/$pattern/))
		{
		    # Can't merge, found next match too near.

		    $ok_to_merge = 0;
		}
	    }
	    if($ok_to_merge == 1)
	    {
		$last_found = $NOT_FOUND;
		push(@print_buffer, [ @grep_buffer ] );
		@grep_buffer = ();
	    }
	}
	$line = $line->next();
    }
    # Printing buffers.

    Irssi::print("%9grep:%9", $LEVEL_LASTLOG_LOCAL);

    for(my $i = 0; $i <= @print_buffer - 1; $i++)
    {
	if($i >= 1 && $i < @print_buffer &&
	   ($after > 0 || $before > 0))
	{
	    # Printing separator only if there are lines before or after match
	    # and if there are more than 1 buffer to print, of course :)

	    Irssi::print($GREP_SEPARATOR, $LEVEL_LASTLOG_LOCAL);
	}
	for(my $j = 0; $j <= $#{$print_buffer[$i]} - 0; $j++)
	{
	    Irssi::print($print_buffer[$i][$j], $LEVEL_LASTLOG_LOCAL);
	}
    }
    Irssi::print("%9end grep%9", $LEVEL_LASTLOG_LOCAL);
}

Irssi::command_bind('ngrep', 'cmd_ngrep');
