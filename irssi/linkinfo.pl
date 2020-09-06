use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use LWP::UserAgent;
use HTML::Entities;
use utf8;
use Encode;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->max_size(500000);
#2019-08-17: Commented out so LWP does not try to load too fancy stuff
#$ua->agent("Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0 SeaMonkey/2.26.1");
#2019-08-18: Added new agent to pass Cloudflare anti-ddos measures.
#$ua->agent("Wget/1.17.1 (linux-gnu)");
$ua->agent("Omaropotti/1.0 (linux-gnu)");
#2020-06-30: Stupid twitter fixes
#2020-07-05: Fallback title tag parsing if built-in fails
#2020-07-05: Stupid youtube fixes. Please, stop being dicks, ok?
#2020-07-06: Youtube engineers, why the fuck do you do this? Yet another fix.
#2020-07-27: Adding soft hyphen remover.
#2020-09-05: Another invidious host
#2020-09-06: Disabled invidious, instead set maximum size of response to 500kb => problem solved for YT

$VERSION = '0.5.6';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'Link info printer',
 description => 'This script prints link info from channels URLs',
 license     => 'GPL',
 changed     => 'Sun 06 Sep 2020 03:49:52 PM EEST'
);

my $no_chans .= " #piraattipuolue/IRCnet #sivusto/PirateIRC #keski-suomi/PirateIRC #helsinki/PirateIRC #toiminta/PirateIRC #uusimaa/PirateIRC #piraattinuoret/PirateIRC #piraattipuolue/PirateIRC ";

sub get_title
{
    my $url = $_[0];
    my $extra = 0;
    
    if (index($url, "https://twitter.com") == 0)
    {
	$url = substr($url, length("https://twitter.com"));
	$url = "https://nitter.net" . $url;
	$extra = 1;
    }
    my $response = $ua->head($url,
			     'Accept' => 'text/html');
    
    if($response->is_success() && !($response->content_type() eq "text/html"))
    {
	return "";
    }
    $response = $ua->get($url);
    
    if(!($response->is_success()))
    {
	return "";
    }
    my $title = $response->title();
    $title = decode_entities($title);
    $title =~ s/\s+/ /g;
    $title =~ s/^\s+|\s+$//g;

    if (length($title) == 0)
    {
	my $html = $response->content();

	($title) = $html =~ m/<\s*title[^>]*>(.+)<\s*\/\s*title/gi;
	$title = decode_entities($title);
	$title =~ s/\s+/ /g;
	$title =~ s/^\s+|\s+$//g;
    }
    if ((length($title) > 0))
    {
	$title =~ s/\xC2?\xAD//g;
    }
    
    if ((length($title) > 0) and (length($title) < ($extra ? 550 : 350)))
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
