use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use LWP::UserAgent;
use HTML::Entities;
use utf8;
use Encode;
use URI;

my $ua = LWP::UserAgent->new;
$ua->timeout(15);
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
#2020-09-18: Modified blacklist
#2020-01-30: Added whitelist support for twitter, reversed order of chan and net.
#2020-02-05: Fuck you twitter. Now I'm getting your stupid title via Selenium.
#2023-08-23: Ditto for x.com


$VERSION = '0.7.4';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'Link info printer',
 description => 'This script prints link info from channels URLs',
 license     => 'GPL',
 changed     => 'Wed 23 Aug 2023 07:54:48 PM EEST'
);

my $blacklist_chans .= " IRCnet/#IRC-galleria IRCnet/#piraattipuolue PirateIRC/#sivusto PireteIRC/#keski-suomi PirateIRC/#helsinki PirateIRC/#toiminta PirateIRC/#uusimaa PirateIRC/#piraattinuoret PirateIRC/#piraattipuolue IRCnet/#otaniemi IRCnet/#scripta QuakeNet/#ylis.fi ";

my $whitelist_twitter_chans .= " IRCnet/#otaniemi IRCnet/#vimpeli IRCnet/#scripta QuakeNet/#ylis.fi ";

sub get_title
{
    my $url = $_[0];
    my $blacklisted = $_[1];
    my $net_channel = $_[2];

    my $use_selenium = 0;
    my $response;
    my $title = "";
    my $url_uri = URI->new($url);

    if (($url_uri->host eq "twitter.com") or ($url_uri->host =~ /\.twitter\.com$/) or
	($url_uri->host eq "x.com") or ($url_uri->host =~ /\.x\.com$/))
    {
	$use_selenium = 1;
	
	if ($blacklisted)
	{
	    # Check if in twitter whitelist still
	    if (index(" " . lc($whitelist_twitter_chans) . " ", " " . $net_channel . " ") != -1)
	    {
		$blacklisted = 0;
	    }
	}
	# Redirect url
	$url = "http://172.16.8.205:9001/" . $url;
	
	if ($blacklisted)
	{
	    # Check if in twitter happens to be in whitelist
	    if (index(" " . lc($whitelist_twitter_chans) . " ", " " . $net_channel . " ") != -1)
	    {
		$blacklisted = 0;
	    }
	}
    }
    # Still blacklisted? Don't return anything.
    if ($blacklisted)
    {
	return "";
    }
    if ($use_selenium)
    {

	$response = $ua->get($url);
	
	if(!($response->is_success()))
	{
	    return "";
	}
	$title = $response->decoded_content;
    }
    else
    {
	$response = $ua->head($url,
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
	$title = $response->title();
    }
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
    
    if ((length($title) > 0) and (length($title) < 1000 ))
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

    my $temp_blacklisted = 0;
    my $temp_net_channel = lc($temp_server->{tag}) . "/" . lc($temp_channel) . "";

    if (index(" " . lc($blacklist_chans) . " ", " " . $temp_net_channel . " ") != -1)
    {
	$temp_blacklisted = 1;
    }
    
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
		my $temp_title = get_title($_, $temp_blacklisted, $temp_net_channel);
		
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
