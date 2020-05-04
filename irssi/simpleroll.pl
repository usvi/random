use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '2.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'Simpleroll',
 description => 'Rolls simple digits to a channel or query according to a trigger',
 license     => 'GPL',
 changed     => 'Mon May  4 11:54:28 EEST 2020'
);

# Changelog
# 2.0 * Added possibility to define number count from 0-9
#     * Script make special notices about "if doubles" messages if matches
#
# 1.0 * Initial release

my $roll_trigger_default = "!roll";
my $digit_count_default = 6;

my $id_if_prefix = "jos ";
my @id_numbers = ("tuplat",
		  "triplat",
		  "guadrot",
		  "pentat",
		  "hexat");
my $id_matched_message_suffix = " tuli, paree olis!";


sub filter_for_doubles_n_friends
{
    my $roll_result = "" . $_[0]; # Just in case
    my $rest_of_message = $_[1];
    my $last_chars = "";

    for (my $i = 2; $i <= 6; $i++)
    {
	if ((index($rest_of_message, $id_if_prefix . $id_numbers[$i - 2]) >= 0) &&
	    (length($roll_result) >= $i))
	{
	    for (my $j = length($roll_result) - $i; $j < (length($roll_result) - 1); $j++)
	    {
		if (substr($roll_result, -1, 1) ne substr($roll_result, $j, 1))
		{
		    return "";
		}
	    }
	
	    return $id_numbers[$i - 2] . $id_matched_message_suffix;
	}
    }

    # Nothing found
    return "";
}

    
sub check_input
{
    my $temp_server = $_[0];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];
    my $temp_mask = $_[3];
    my $temp_channel = $_[4];
    my $temp_network = $temp_server->{tag};
    my $digit_count = $digit_count_default;
    
    if (index($temp_message, $roll_trigger_default) == 0)
    {
	# We might have:
	# "!roll"
	# "!roll4"
	# "!roll4 foo"
	# "!roll foo"

	my $real_trigger = "";
	my $rest_of_message = "";

	if ($temp_message =~ /.*\s+.*/)
	{
	    ($real_trigger, $rest_of_message) = split(/\s+/, $temp_message, 2);
	}
	# If no whitespace, real_trigger is empty. Fix it.
	else
	{
	    $real_trigger = $temp_message;
	}

	# Real trigger might have number
	if ($real_trigger ne $roll_trigger_default)
	{
	    if (substr($real_trigger, length($roll_trigger_default)) =~ /^\d$/)
	    {
		# Successful number
		$digit_count = "" . int(substr($real_trigger, length($roll_trigger_default)));
	    }
	    else
	    {
		# Was garbage
		return;
	    }
	}
	my $roll_result = "" . int(rand(10 ** $digit_count));

	while (length($roll_result) < $digit_count)
	{
	    $roll_result = "0" . $roll_result;
	}
	my $roll_additional_message = filter_for_doubles_n_friends($roll_result, $rest_of_message);

	if (length($roll_additional_message) > 0)
	{
	    $roll_additional_message = ", " . $roll_additional_message;
	}
	
	$temp_server->command("MSG " . ($temp_channel ?
					$temp_channel . " " . $temp_nick . " rolls " . $roll_result . $roll_additional_message:
					$temp_nick . " " . "you roll " . $roll_result . $roll_additional_message));

	return;
    }
}

Irssi::signal_add_last("message public", "check_input");
Irssi::signal_add_last("message private", "check_input");
