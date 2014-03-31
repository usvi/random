use strict;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind active_win);

use Irssi;
$VERSION = '0.3';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Valimatka',
 description => 'Shows distance between two finnish places',
 license     => 'GPL',
 changed     => 'Fri Apr 11 12:57:50 EEST 2008'
);

my $places_file = Irssi::get_irssi_dir . "/scripts/valimatka_places.txt";
my @places_data;
my $places_form_url = 'http://alk.tiehallinto.fi/cgi-bin/pq9.cgi';
my @param_identifiers = ("MIST\xC4", "MIHIN", "NOPEUS");

sub load_places
{
    open(PLACES_FD, $places_file);
    @places_data = <PLACES_FD>;
    close(PLACES_FD);

    for(my $i = @places_data - 1; $i >= 0; $i--)
    {
	$places_data[$i] =~ s/\n$//;

	if( $places_data[$i] eq "")
	{
	    pop(@places_data);
	}
    }
}

sub scand_lc
{
    my $lc_string = lc(pop(@_));
    $lc_string =~ s/Ä/ä/g;
    $lc_string =~ s/Ö/ö/g;
    $lc_string =~ s/Ö/ö/g;
    return $lc_string;
}

sub in_array
{
    my $needle = shift(@_);
    my $match_type = shift(@_);
    my @haystack = @_;

    for(my $i = 0; $i < @haystack; $i++)
    {
	if($match_type == 0)
	{
	    if(scand_lc($needle) eq scand_lc($haystack[$i]))
	    {
		return $haystack[$i];
	    }
	}
	elsif($match_type == 1)
	{
	    if(scand_lc($haystack[$i]) =~ ("^" . quotemeta(scand_lc($needle)) . ".*"))
	    {
		return $haystack[$i];
	    }
	}
	elsif($match_type == 2)
	{
	    if(scand_lc($haystack[$i]) =~ (quotemeta(scand_lc($needle)) . ".*"))
	    {
		return $haystack[$i];
	    }
	}
    }
    return 0;
}

sub calc_valimatka
{
    my @cmd_data = @_;
    my $last_place = 0;
    my $first_place = 0;
    my $continue = 1;
    my $match_type = 0;
    my $i = @cmd_data;

    while($i >= 2 && (!$first_place || !$last_place))
    {
	my $temp_last = "";
	my $temp_first = "";

	for(my $j = 0; $j < $i - 1; $j++)
	{
	    $temp_first .= $cmd_data[$j] . " ";
	}
	$temp_first =~ s/\ $//;

	for(my $j = $i - 1; $j < @cmd_data; $j++)
	{
	    $temp_last .= $cmd_data[$j] . " ";
	}
	$temp_last =~ s/\ $//;

	$first_place = ($first_place ? $first_place : in_array($temp_first, $match_type, @places_data));
	$last_place = ($last_place ? $last_place : in_array($temp_last, $match_type, @places_data));

	if($i == 2 && $match_type <= 1)
	{
	    $match_type++;
	    $i = @cmd_data + 1;
	}
	$i--;
    }
    if($first_place && $last_place)
    {
	my $first_place_orig = $first_place;
	my $last_place_orig = $last_place;

	$first_place =~ s/Ä/\xC4/g;
	$first_place =~ s/Ö/\×D6/g;
	$first_place =~ s/Å/\xC5/g;
	$first_place =~ s/ä/\xE4/g;
	$first_place =~ s/ö/\xF6/g;
	$first_place =~ s/å/\xE5/g;

	$last_place =~ s/Ä/\xC4/g;
	$last_place =~ s/Ö/\xD6/g;
	$last_place =~ s/Å/\xC5/g;
	$last_place =~ s/ä/\xE4/g;
	$last_place =~ s/ö/\xF6/g;
	$last_place =~ s/å/\xE5/g;

	use HTTP::Request::Common qw(POST);
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new;

	my $req = (POST $places_form_url,
		   [$param_identifiers[0] => $first_place,
		   $param_identifiers[1] => $last_place,
		   $param_identifiers[2] => '80']);

	my $response = $ua->simple_request($req);

	if($response->is_success)
	{
	    if($response->as_string =~ /limatka\ on\ ([0-9]+)\ km/)
	    {
		return "Välimatka $first_place_orig - $last_place_orig : $1 km";
	    }
	    else
	    {
		;
	    }
	}
    }
}

sub check_for_valimatka
{
    my ($server, $msg, $nick, $mask, $channel) = @_;

    if($msg =~ /^\!vm /)
    {
	$msg =~ s/\xc4/Ä/g;
	$msg =~ s/\xd6/Ö/g;
	$msg =~ s/\xc5/Å/g;
	$msg =~ s/\xe4/ä/g;
	$msg =~ s/\xf6/ö/g;
	$msg =~ s/\xe5/å/g;

	my @cmd_args = split(/ +/, $msg);
	shift(@cmd_args);
	my $calc_result = calc_valimatka(@cmd_args);

	if($calc_result)
	{
	    $server->command("MSG " . ($channel ? $channel : $nick) . " " . $calc_result);
	    Irssi::signal_stop();
	}
    }
}

Irssi::signal_add_last("message public", "check_for_valimatka");
Irssi::signal_add_last("message private", "check_for_valimatka");

load_places();
