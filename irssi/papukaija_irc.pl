use Irssi;
use Irssi::TextUI;

use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Papukaija',
 description => 'This script acts as channel history and population accountant',
 license     => 'GPL',
 changed     => 'Tue Mar 18 01:10:20 EET 2008'
);

my $operation_channel = "#papukaijayhdistys";
my $temp_log_file = "/home/jpaalija/public_html/papukaijayhdistys.dat.txt";
my $num_lines = 10;
my $data_writing_interwall_secs = 60;

sub write_data
{
    my $channel;

    if(!($channel = Irssi::channel_find($operation_channel)))
    {
	die("channel not found: " . $operation_channel);
    }
    my @nicks = $channel->nicks(); 
    my @ops;
    my @voiced;
    my @normals;

    foreach(@nicks)
    {
	if($_->{op} == 1)
	{
	    push(@ops, "@" . $_->{nick});
	}
	elsif($_->{voice} == 1)
	{
	    push(@voiced, "+" . $_->{nick});
	}
	else
	{
	    push(@normals, $_->{nick});
	}
    }
    open(CHANNEL_STAT_FILE, '>', $temp_log_file);
    print(CHANNEL_STAT_FILE "Kanavalla tällä hetkellä:\n");
    print(CHANNEL_STAT_FILE join(", ", @ops, @voiced, @normals) . "\n\n");
    print(CHANNEL_STAT_FILE "Viimeisimmät puheet:\n");
    close(CHANNEL_STAT_FILE);

    my $server = $channel->{server};
    $server->command("LASTLOG -file " . $temp_log_file . " -window " . $channel->window()->{refnum} . " -public -action " . $num_lines);
}
Irssi::timeout_add($data_writing_interwall_secs * 1000, 'write_data', "");
