use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi. Google me.',
 contact     => 'usvi@IRCnet',
 name        => 'Aaltotilat',
 description => 'Search engine for location codes in Aalto University..',
 license     => 'GPL',
 changed     => 'Thu Oct 25 13:57:22 EEST 2012'
);

my $trigger = "!tila";
my $location_file = Irssi::get_irssi_dir . "/aaltotilat.csv";
my @location_array;


# File format:
# Actual building;;
# ;search_code;building_code
# ;search_code;building_code
# Actual building;;
# ;search_code;building_code
# ;search_code;building_code


sub load_codes
{
    print("Loading " . $location_file);
    my $active_building;
    my $temp_line = "";

    open(location_file_handle, "<", $location_file);

    while($temp_line = readline(*location_file_handle))
    {
	my @temp_fields = split(/;/, $temp_line);

	for(my $i = 0; $i < 3; $i++)
	{
	    $temp_fields[$i] =~ s/^\s+//;
	    $temp_fields[$i] =~ s/\s+$//;
	}
	if(length($temp_fields[0]) > 3)
	{
	    # New building found
	    $active_building = $temp_fields[0];
	}
	$location_array[@location_array] = [$active_building, $temp_fields[1], $temp_fields[2]];
    }
    close(location_file_handle);

}

sub search_code
{
    my $search_code = shift();
    my @dym_array;

    for(my $i = 0; $i < @location_array; $i++)
    {
	if(lc($search_code) eq lc($location_array[$i][1]))
	{
	    return $location_array[$i][1] . " = " . $location_array[$i][0] . ", " . $location_array[$i][2];
	}
    }
    for(my $i = 0; $i < @location_array && @dym_array < 7; $i++)
    {
	if(index(lc($location_array[$i][1]), lc($search_code)) >= 0 || index(lc($location_array[$i][2]), lc($search_code)) >= 0)
	{
	    $dym_array[@dym_array] = lc($location_array[$i][1]);
	}
    }
    if(@dym_array == 1)
    {
	my $new_search_code = $dym_array[0];

	for(my $i = 0; $i < @location_array; $i++)
	{
	    if(lc($new_search_code) eq lc($location_array[$i][1]))
	    {
		return $location_array[$i][1] . " = " . $location_array[$i][0] . ", " . $location_array[$i][2];
	    }
	}
    }
    elsif(@dym_array > 1)
    {
	return "Possible matches: " . join(" ; ", @dym_array);
    }
    return $search_code . ": Can't see shit, captain";
}

sub check_input
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];
    my $temp_network = $temp_server->{tag};

    my @search_array = split(/ +/, $temp_message);
    my $search_code = $search_array[1];
    $search_code =~ s/^\s+//;
    $search_code =~ s/\s+$//;
    $search_code = lc($search_code);

    if (index($temp_message, $trigger) == 0 && length($search_code) > 0)
    {
	my $search_result = search_code($search_code);
        $temp_server->command("MSG " . ($temp_channel ? $temp_channel : $temp_nick) . " " . $search_result);
	Irssi::signal_stop();
        return;
    }
}

load_codes();

Irssi::signal_add_last("message public", "check_input");
Irssi::signal_add_last("message private", "check_input");
