use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'Simpleroll',
 description => 'Rolls simple digits to a channel or query according to a trigger',
 license     => 'GPL',
 changed     => 'Mon Apr 25 21:30:42 EEST 2011'
);


my $roll_trigger = "!roll";
my $digit_count = 6;

sub check_input
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];
    my $temp_network = $temp_server->{tag};

    if (index($temp_message, $roll_trigger) == 0)
    {
	my $roll_result = 1 + int(rand(10 ** 6));
	$temp_server->command("MSG " . ($temp_channel ? $temp_channel . " " . $temp_nick . " rolls " . $roll_result : $temp_nick . " " . "you roll " . $roll_result));
	return;
    }
}

Irssi::signal_add_last("message public", "check_input");
Irssi::signal_add_last("message private", "check_input");
