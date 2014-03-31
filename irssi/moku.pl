use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Mokuttaja',
 description => 'Kicks people off the channel when immigration is being criticized',
 license     => 'GPL',
 changed     => 'Sun Aug 30 19:36:06 EEST 2009'
);

# Changelog:
#
# 0.3 - Added even more channels due to popular demand
# 0.2 - Added more default channels
# 0.1 - Initial release


my $ok_chans = "#iltasanomat #vasemmistoliitto #rkp #wanhatstalinistit #vihreatnaiset #vino";
$ok_chans .= " #otaposse #vimpeli #otaniemi"; # debug
my $criticism_trigger = "maahanm..";

sub check_criticism_trigger
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];

    if(index(" " . lc($ok_chans) . " ", " " . lc($temp_channel) ." ") != -1 &&
       index(lc($temp_message), lc($criticism_trigger)) != -1)
    {
	($temp_server->window_find_item($temp_channel))->command("KICK $temp_nick tarpeetonta kritisointia");
	Irssi::signal_stop();
    }
}

Irssi::signal_add_last("message public", "check_criticism_trigger");
