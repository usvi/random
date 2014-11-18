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

my $ok_chans .= " #otaniemi #vimpeli #test3 ";

sub get_title
{
	my $url = $_[0];
	my $response = $ua->head($url);

	if($response->is_success() && ($response->content_type() eq "text/html"))
	{
		my $html = $ua->get($url)->content();
		my ($title) = $html =~ m/<title>([a-zA-Z\/\s][^>]+)<\/title>/gsi;
		$title =~ s/\s+/ /g;

		return "Title: " . $title;
	}
}

sub check_for_urls
{
	my $temp_server = $_[0];
	my $temp_message = $_[1];
	my $temp_nick = $_[2];
	my $temp_channel = lc($_[4]);

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
				$return_string .= get_title($_)
			}
		}
		if(length($return_string) > 0)
		{
			($temp_server->window_find_item($temp_channel))->command("SAY " . $return_string);
		}
    }
}
Irssi::signal_add('message public', 'check_for_urls');
