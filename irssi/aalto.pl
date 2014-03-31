use strict;
use vars qw($VERSION %IRSSI %channels);
use Irssi;
use List::Util 'shuffle';

$VERSION = '0.4.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Aaltofy!',
 description => 'Aaltofies your messages',
 license     => 'G?PL',
 changed     => 'Thu May  7 08:47:52 EEST 2009'
);


#
# The command /aaltofy aaltofies your text and sends it to query/channel.
# If you want to automagically aaltofy all your messages, use /set auto_aaltofy ON
# Auto-aaltofying can be disabled by issuing /set auto_aaltofy OFF
#

#
# Toggle color mode by /set aaltofy_colors ON|OFF
#

# Changelog:
#
# 0.4.1 - Typofix
# 0.4   - Aaltofying now off by default. Added command /aaltofy and 
#         changed the setting names
# 0.3   - Added option for disabling aaltofying
# 0.2   - Randomization. Color support (thanks Kuukunen, Gridle)
# 0.1.1 - Corrected licence
# 0.1   - Initial release

sub aaltofy_string
{
    my $input_string = shift();

    if (utf8::valid($input_string))
    {
	utf8::decode($input_string);
    }
    my $use_colors = Irssi::settings_get_bool('aaltofy_colors');

    
    my @innovation_chars;
    my $char_pos = 0;
    $innovation_chars[@innovation_chars] = "\"";
    $innovation_chars[@innovation_chars] = "!";
    $innovation_chars[@innovation_chars] = "?";

    my @innovation_colors;
    my $color_pos = 0;
    $innovation_colors[@innovation_colors] = 4;
    $innovation_colors[@innovation_colors] = 8;
    $innovation_colors[@innovation_colors] = 12;
 
    my @tokens = split(/(\s+)/, $input_string);

    my $output_string = "";

    foreach my $token (@tokens)
    {
	if ($color_pos == 0)
	{
	    @innovation_colors = shuffle(@innovation_colors);
	}
	if ($char_pos == 0)
	{
	    @innovation_chars = shuffle(@innovation_chars);
	}
	my $temp_token = $token;
	$temp_token =~ s/^\s+//;
	
	if (length($temp_token) > 2)
	{
	    my $splitpos = int(1 + rand(length($temp_token) - 1));
	    $token = substr($token, 0, $splitpos) . ($use_colors ? chr(3). $innovation_colors[$color_pos] : "") .
		$innovation_chars[$char_pos] . ($use_colors ? chr(15) : "") . substr($token, $splitpos);
	    $char_pos = ($char_pos + 1) % @innovation_chars;
	    $color_pos = ($color_pos + 1) % @innovation_colors;
	}
	$output_string .= $token;
    }
    return $output_string;
}

sub event_send_text ($$$)
{
    my ($line, $server, $witem) = @_;
    return unless ($witem && 
		   ($witem->{type} eq "CHANNEL" || $witem->{type} eq "QUERY") &&
		   Irssi::settings_get_bool('auto_aaltofy'));
    my $aaltofied_line = aaltofy_string($line);

    if (length($aaltofied_line) > 0)
    {
	Irssi::signal_stop();
	$server->command("/MSG -$server->{tag} $witem->{name} " . $aaltofied_line);
    }
}

sub command_aaltofy ($$$)
{
    my ($line, $server, $witem) = @_;
    return unless ($witem && 
		   ($witem->{type} eq "CHANNEL" || $witem->{type} eq "QUERY"));

    my $aaltofied_line = aaltofy_string($line);

    if (length($aaltofied_line) > 0)
    {
	Irssi::signal_stop();
	$server->command("/MSG -$server->{tag} $witem->{name} " . $aaltofied_line);
    }
}

Irssi::settings_add_bool('innovation', 'aaltofy_colors', 0);
Irssi::settings_add_bool('innovation', 'auto_aaltofy', 0);
Irssi::signal_add('send text', \&event_send_text);
Irssi::command_bind('aaltofy', \&command_aaltofy);
