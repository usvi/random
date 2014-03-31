use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Laurantai',
 description => 'Checks, whether it it already Laurantai',
 license     => 'GPL',
 changed     => 'Sun Mar  7 00:59:42 EET 2010'
);

my $laura_trigger = "!laurantai";
my $laura_yes = "Onko tänään Laurantai? " . chr(3) . "3On!" . chr(15);
my $laura_no = "Onko tänään Laurantai? " . chr(3) . "5Ei :(" . chr(15);

sub laura_info
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

    if($wday == 6)
    {
	return $laura_yes;
    }
    else
    {
	return $laura_no;
    }
}

sub check_laura_requests
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];

    if(lc($temp_message) eq lc($laura_trigger))
    {
	$temp_server->command("MSG " . ($temp_channel ? $temp_channel : $temp_nick) . " " . laura_info());
	Irssi::signal_stop();
    }
}

Irssi::signal_add_last("message public", "check_laura_requests");
Irssi::signal_add_last("message private", "check_laura_requests");
