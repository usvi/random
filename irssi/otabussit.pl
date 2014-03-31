#
#
#
use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use LWP::Simple;

$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Otabussit',
 description => 'Checks for busses to/from Otaniemi',
 license     => 'GPL',
 changed     => 'Sat Feb 13 20:15:34 EET 2010'
);

sub get_bus_info
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
    $year += 1900;
    $mon += 1;
    my $fromNiemiUrl = "http://aikataulut.ytv.fi/reittiopas-pda/fi/?test=1&keya=teekkarikyl%%E4&keyb=kampin+keskus&hour=%d&min=%d&vm=1&day=%d&month=%d&year=%d&adv=&proxypassrandom=" . time();
    $fromNiemiUrl = sprintf($fromNiemiUrl, $hour, $min, $mday, $mon, $year);
    my $fromNiemiPage = LWP::Simple::get($fromNiemiUrl);
    my $fromNiemiRegexp = "Bussi 102.*?" . quotemeta("</TD><TR><TD") . "";
    my @fromNiemiArray;

    for($fromNiemiPage =~ m/$fromNiemiRegexp/g)
    {
	my $busId = $_;
	my $busTime = $_;
	$busId =~ m/102[T]{0,1}/;
	$busId = $&;
	$busTime =~ m/[0-9]{2}\:[0-9]{2}m{0,1}/;
	$busTime = $&;
	$fromNiemiArray[@fromNiemiArray] = $busId . " @ " . $busTime . ";  ";
    }
    my $toNiemiUrl = "http://aikataulut.ytv.fi/reittiopas-pda/fi/?test=1&keyb=teekkarikyl%%E4&keya=kampin+keskus&hour=%d&min=%d&vm=1&day=%d&month=%d&year=%d&adv=&proxypassrandom=" . time();
    $toNiemiUrl = sprintf($toNiemiUrl, $hour, $min, $mday, $mon, $year);
    my $toNiemiPage = LWP::Simple::get($toNiemiUrl);
    my @toNiemiArray;
    my $toNiemiRegexp = "Bussi 102.*?" . quotemeta("</TD><TD width='25%' nowrap>Kamppi, laituri") . ".*?" . quotemeta("</TD><TR><TD") . "";

    for($toNiemiPage =~ m/$toNiemiRegexp/g)
    {
	my $busId = $_;
	my $busTime = $_;
	$busId =~ m/102[T]{0,1}/;
	$busId = $&;
	$busTime =~ m/[0-9]{2}\:[0-9]{2}m{0,1}/;
	$busTime = $&;
	$toNiemiArray[@toNiemiArray] = $busId . " @ " . $busTime . ";  ";
    }
    my $fromNiemiText = "";
    my $toNiemiText = "102:t Kampista: ";

    if(@fromNiemiArray >= 1)
    {
	$fromNiemiText = "102:t Otaniemestä: " . join("", @fromNiemiArray);
	$fromNiemiText =~ s/;  $//;
    }
    else
    {
	$fromNiemiText = "Ei Otaniemestä lähteviä 102:sia";
    }

    if(@toNiemiArray >= 1)
    {
	$toNiemiText = "102:t Kampista: " . join("", @toNiemiArray);
	$toNiemiText =~ s/;  $//;
    }
    else
    {
	$toNiemiText = "Ei Kampista lähteviä 102:sia";
    }
#    print($fromNiemiText);
#    print($toNiemiText);

    my @returnArray;
    $returnArray[0] = $fromNiemiText;
    $returnArray[1] = $toNiemiText;
    return @returnArray;
}

sub check_for_bus
{
    my ($server, $msg, $nick, $mask, $channel) = @_;

    if($msg =~ /^\!b[ ]*/ || $msg =~ /^\!bus[ ]*/)
    {
	my @busInfoArray = get_bus_info();

	if(@busInfoArray)
	{
	    $server->command("MSG " . ($channel ? $channel : $nick) . " " . $busInfoArray[0]);
	    $server->command("MSG " . ($channel ? $channel : $nick) . " " . $busInfoArray[1]);
	}    
    }
}

Irssi::signal_add_last("message public", "check_for_bus");
Irssi::signal_add_last("message private", "check_for_bus");
