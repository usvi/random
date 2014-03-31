use strict;
use XML::Simple;
use Data::Dumper;
use LWP::Simple;
use vars qw($VERSION %IRSSI);

$VERSION = "0.1";
%IRSSI = (
    authors     => 'Janne Paalijarvi',
    name        => 'piraattikalenteri',
    description => 'Piraattikalenteri',
    license     => 'BSD',
    changed     => 'Sat May 11 22:56:57 EEST 2013'
);

my $xml_address = "https://www.google.com/calendar/feeds/piraattikalenteri%40gmail.com/public/basic";
my $xml = new XML::Simple;


sub get_next_event
{
    my $event_data = $_[0];
    print $event_data;
}

sub parse_xml
{
    my $cal_page = get($xml_address);
    my $data = $xml->XMLin($cal_page);

    foreach my $key (keys %{$data->{entry}})
    {
        print $data->{entry}->{$key}->{'title'}->{'content'};
	get_next_event($data->{entry}->{$key}->{'summary'}->{'content'});
        print "\n";
    }

}

Irssi::command_bind("parse", "parse_xml");
