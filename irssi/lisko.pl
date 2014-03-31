use strict;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind active_win);

#use Irssi;
$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Lisko say',
 description => 'Displays SuSE Geeko ascii art',
 license     => 'GPL',
 changed     => 'Mon Nov 19 09:43:36 EET 2007'
);

use Irssi;

sub lisko_say_command
{
    my @lisko_ascii;
    $lisko_ascii[0] = "        ____/~~~~~~~~~\\_/^_.";
    $lisko_ascii[1] = "   .___/                 ©  \\";
    $lisko_ascii[2] = "  / ______   ____      \\____/===============O";
    $lisko_ascii[3] = "  |/\\     \\ /    \\ /~~~~~~~'";
    $lisko_ascii[4] = "  \\@/      \\\\     \\\\";

    my ($data, $server, $witem) = @_;
    my @cmd_data = split(/ +/, $data);
    my $dataRequester = $cmd_data[0];
    
    active_win->command("SAY " . $lisko_ascii[0]);
    active_win->command("SAY " . $lisko_ascii[1]);
    active_win->command("SAY " . $lisko_ascii[2] . " " . $data);
    active_win->command("SAY " . $lisko_ascii[3]);
    active_win->command("SAY " . $lisko_ascii[4]);
}

Irssi::command_bind("lisko", "lisko_say_command");
