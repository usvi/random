use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Pilalla',
 description => 'Tells everything is pilalla',
 license     => 'GPL',
 changed     => 'Tue Mar 10 09:44:33 EET 2020'
);

# Changelog:
#
# 0.1 - Initial release based on old stuff


my $ok_chans = "#otaniemi #spring.fi";
my $pilalla_trigger = "on pilalla";
my $pilalla_message = "pelkkää paskaa tilalla";

sub check_pilalla_trigger
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];

    if(index(" " . lc($ok_chans) . " ", " " . lc($temp_channel) ." ") != -1 &&
       index(lc($temp_message), lc($pilalla_trigger)) != -1)
    {
	($temp_server->window_find_item($temp_channel))->command("SAY " . $pilalla_message);
	Irssi::signal_stop();
    }
}

Irssi::signal_add_last("message public", "check_pilalla_trigger");
