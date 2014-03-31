use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Kyrvättäjä',
 description => 'Makes the funny *BATANG* sound',
 license     => 'GPL',
 changed     => 'Fri May 14 23:01:58 EEST 2010'
);

# Changelog:
#
# 0.2: a is now not necessary in trigger. More channels.


my $ok_chans .= " #otaposse #vimpeli #otaniemi #piraattipuolue #piraattinuoret #lapsiporno "; # debug
my $kyrpa_trigger = ".*pakastettu[a]{0,1}[ ]*kyrp.*";
my $kyrpa_effect = "*BATANG*";

sub check_kyrpa_trigger
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];

    if(index(" " . lc($ok_chans) . " ", " " . lc($temp_channel) ." ") != -1 &&
       $temp_message =~ /$kyrpa_trigger/i)
    {
	($temp_server->window_find_item($temp_channel))->command("SAY " . $kyrpa_effect);
	Irssi::signal_stop();
    }
}

Irssi::signal_add_last("message public", "check_kyrpa_trigger");
