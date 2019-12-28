use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use LWP::UserAgent;
use HTML::Entities;
use utf8;
use Encode;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
#2019-08-17: Commented out so LWP does not try to load too fancy stuff
#$ua->agent("Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0 SeaMonkey/2.26.1");
#2019-08-18: Added new agent to pass Cloudflare anti-ddos measures.
#$ua->agent("Wget/1.17.1 (linux-gnu)");
$ua->agent("Omaropotti/1.0 (linux-gnu)");


$VERSION = '0.3';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Link info printer',
 description => 'This script prints link info from channels URLs',
 license     => 'GPL',
 changed     => 'Sun Aug 18 11:02:55 EEST 2019'
);

my $no_chans .= " #piraattipuolue/IRCnet #sivusto/PirateIRC #keski-suomi/PirateIRC #helsinki/PirateIRC #toiminta/PirateIRC #uusimaa/PirateIRC #piraattinuoret/PirateIRC #piraattipuolue/PirateIRC ";

sub get_title
{
	my $url = $_[0];
	my $response = $ua->head($url,
	    'Accept' => 'text/html');

	if($response->is_success() && !($response->content_type() eq "text/html"))
	{
		return "";
	}
	my $html = $ua->get($url)->content();
	#my ($title) = $html =~ m/<\s*title\s*>([^>]+)<\s*\/\s*title\s*>/gsi;
	my ($title) = $html =~ m/<\s*title[^>]*>(.+)<\s*\/\s*title/gsi;
	$title = decode_entities($title);
	$title =~ s/\s+/ /g;
	$title =~ s/^\s+|\s+$//g;
	
	if(length($title) > 0)
	{
		return "Title: " . $title;
	}
	else
	{
		return "";
	}
}

sub check_for_urls
{
	my $temp_server = $_[0];
	my $temp_message = $_[1];
	my $temp_nick = $_[2];
	my $temp_channel = lc($_[4]);

	if(!(index(" " . lc($no_chans) . " ", " " . lc($temp_channel) . "/" . lc($temp_server->{tag}) ." ") != -1))
	{
		#my @url_tokens = ($temp_message =~ m/([k]{0,1}http[s]{0,1}\:\/\/.*?[^( )\t]*).*?/ig);
		my @url_tokens = ($temp_message =~ m/(http[s]{0,1}\:\/\/.*?[^( )\t]*).*?/ig);
		my $return_string = "";

		foreach(@url_tokens)
		{
			if(length($_) > 3)
			{
				if(length($return_string) > 0)
				{
					$return_string .= " | ";
				}
				my $temp_title = get_title($_);

				if(utf8::is_utf8($temp_title))
				{
					#$return_string .= "UTF8";
					$temp_title =~ s/—/\-/g;
					$temp_title = encode("iso-8859-1", $temp_title);
				}

				$return_string .= $temp_title;
			}
		}
		if(length($return_string) > 0)
		{
			($temp_server->window_find_item($temp_channel))->command("SAY " . $return_string);
		}
    }
}
Irssi::signal_add('message public', 'check_for_urls');
