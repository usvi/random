$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Vkurlel',
 description => 'Forms verkkokauppa.com urls from ids',
 license     => 'GPL',
 changed     => 'Thu Dec 16 17:52:16 EET 2010'
);

use Irssi;
use strict;
use vars qw($VERSION %IRSSI);


my $base_url = "http://www.verkkokauppa.com/popups/prodinfo.php?id=";

sub check_for_urlid
{
    my ($server, $msg, $nick, $mask, $channel) = @_;
    my $url_msg = "";

    if($msg =~ /^\!vkurl[ ]+/)
    {
	$msg =~ s/^\!vkurl[ ]+//;

	my @id_candidates = split(/[ ]+/, $msg);

	foreach(@id_candidates)
	{
	    if($_ =~ /^[0-9]+$/)
	    {
		$url_msg .= $base_url . $_ . " ";
	    }
	}
	$url_msg =~ s/[ ]+$//;

        if($url_msg)
        {
            $server->command("MSG " . ($channel ? $channel . " " . $nick . ":" : $nick) . " " . $url_msg);
        }
    }
}

Irssi::signal_add_last("message public", "check_for_urlid");
Irssi::signal_add_last("message private", "check_for_urlid");
