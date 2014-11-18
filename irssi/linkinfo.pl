use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);


$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Link info printer',
 description => 'This script prints link info from channels URLs',
 license     => 'GPL',
 changed     => 'Tue Nov 18 13:22:38 EET 2014'
);

my $ok_chans .= " #otaniemi #vimpeli ";

sub get_title
{
	my $title = "";
	my $url = shift();
	my $response = $ua->head($url);

	if($response->is_success() && ($response->content_type() eq "text/html"))
	{
		my $html = $ua->get($url)->content();
		$title = $html =~ m/<title>([a-zA-Z\/][^>]+)<\/title>/si;
		
		if(length($title) > 72)
		{
			$title = substr($title, 0, 72);
		}
	}
	return $title;
}

sub check_for_urls
{
    my $temp_channel = lc($_[4]);
    my $temp_message = $_[1];
    my $temp_nick = $_[2];

	if(index(" " . lc($ok_chans) . " ", " " . lc($temp_channel) ." ") != -1)
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
				$return_string .= get_title()
			}
		}
		if(length($return_string) > 0)
		{
			($temp_server->window_find_item($temp_channel))->command("SAY " . $return_string);
		}
    }
}
Irssi::signal_add('message public', 'check_for_urls');
