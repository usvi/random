use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.4';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Simple joke script',
 description => 'This script tells jokes from a file',
 license     => 'GPL',
 changed     => 'Tue Aug 26 21:39:53 EEST 2008',
 certified   => 'Works On My Machine Certification, http://jcooney.net/archive/2007/02/01/42999.aspx'
);

my $joke_file = Irssi::get_irssi_dir . "/jokes.txt";
my @joke_array ;
my @pointer_array ;
my $ok_chans = "#vuorimieskilta";
my $ok_adders = "minppu usv usvi usv_ vauhditin justifier pxt minbo Tiikeri";
my $joke_trigger = "!pxtvitsi";
my $add_trigger = "!pxtlisaa";
my $joke_time_interval = 300;
my $last_joke_time = time() - $joke_time_interval;

sub load_jokes
{
    undef(@joke_array);
    open(joke_file_handle, "<", $joke_file);
    my $collect_jokes = 1;
    
    for(;$collect_jokes == 1;)
    {
	my $temp_joke = readline(*joke_file_handle);
	$temp_joke =~ s/\n//;

	if(length($temp_joke) > 2)
	{
	    push(@joke_array, $temp_joke);
	}
	else
	{
	    $collect_jokes = 0;
	}
    }
    close(joke_file_handle);
    randomize_jokes();
    print "pxtvitsi.pl loaded " . @joke_array . " jokes from file";
}

sub randomize_jokes
{
    undef(@pointer_array);

    my $i = 0;

    for($i = 0; $i < @joke_array; $i++)
    {
	push(@pointer_array, $i);
    }
}

sub save_jokes
{
    open(joke_file_handle, ">", $joke_file);
    my $i;

    for($i = 0; $i < @joke_array ; $i++)
    {
	print(joke_file_handle $joke_array[$i] . "\n");
    }
    close(joke_file_handle);
}

sub add_joke
{
    my ($data, $server, $witem) = @_;
    my $temp_joke = $data;
    $temp_joke =~ s/\n//;

    if(length($temp_joke) > 2)
    {
	push(@joke_array, $temp_joke);
    }
    save_jokes();
    push(@pointer_array, scalar(@joke_array));
}

sub get_joke
{
    if(shift() == 1)
    {
	if(@pointer_array == 0)
	{
	    randomize_jokes();
	}
	my $return_joke_position = int(rand(@pointer_array));
	my $return_joke_id = $pointer_array[$return_joke_position];
	splice(@pointer_array, $return_joke_position, 1);

	return $joke_array[$return_joke_id];
    }
    return $joke_array[int(rand(@joke_array))];
}

sub pxt_status
{
    print("remaining joke positions: " . join(" >", @pointer_array));
}

sub check_requests
{
    my $temp_channel = $_[4];
    my $temp_message = $_[1];
    my $temp_nick = $_[2];

    if(index(" " . lc($ok_chans) . " ", " " . lc($temp_channel) ." ") != -1 &&
       lc($temp_message) eq lc($joke_trigger) &&
       $last_joke_time + $joke_time_interval <= time())
    {
	$last_joke_time = time();
	Irssi::active_win->command("MSG " . $temp_channel . " " . get_joke(1));
    }
    elsif(index(lc($temp_message), lc($add_trigger) . " ") == 0 &&
	 index(" " . lc($ok_adders) . " ", " " . lc($temp_nick) . " ") != -1)
    {
	$temp_message = substr($temp_message, length($add_trigger));
	$temp_message =~ s/ //;
	push(@joke_array, $temp_message);
	save_jokes();
	Irssi::active_win->command("MSG " . $temp_nick . " added joke: " . $temp_message);
    }
    elsif(!$temp_channel && lc($temp_message) eq lc($joke_trigger))
    {
	Irssi::active_win->command("MSG " . $temp_nick . " " . get_joke(0));
    }
}

load_jokes();
Irssi::command_bind("pxtlisaa", "add_joke");
Irssi::command_bind("pxtlataa", "load_jokes");
Irssi::command_bind("pxttallenna", "save_jokes");
Irssi::command_bind("pxtstatus", "pxt_status");
Irssi::signal_add_last("message public", "check_requests");
Irssi::signal_add_last("message private", "check_requests");
