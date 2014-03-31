use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Simple opper script',
 description => 'This script ops people and such',
 license     => 'GPL',
 changed     => 'Wed Dec  5 15:19:17 EET 2007'
);

my $op_file = Irssi::get_irssi_dir . "/opper_data.dat";
my @mask_array ;
my $channel_name = "#papukaijayhdistys";

sub load_masks
{
#    my @temp_array;
#    @mask_array = @temp_array;
#    undef(@mask_array);

    open(op_file_handle, "<", $op_file);
    my $collect_masks = 1;
    
    for(;$collect_masks == 1;)
    {
	my $temp_mask = readline(*op_file_handle);
	$temp_mask =~ s/\n//;

	if(length($temp_mask) > 2)
	{
	    push(@mask_array, $temp_mask);
	}
	else
	{
	    $collect_masks = 0;
	}
    }
    close(op_file_handle);
    print "opper.pl loaded " . @mask_array . " masks from file";

}

sub save_masks
{
    open(op_file_handle, ">", $op_file);
    my $i;

    for($i = 0; $i < @mask_array ; $i++)
    {
	print(op_file_handle $mask_array[$i] . "\n");
    }
    close(op_file_handle);
}

# "message join", SERVER_REC, char *channel, char *nick, char *address
sub handle_join
{
    my $server = $_[0];
    my $channel = $_[1];
    my $nick = $_[2];
    my $address = $_[3];
    my $i;
	
    for($i = 0; $i < @mask_array; $i++)
    {
	if($server->mask_match_address($mask_array[$i], $nick, $address))
	{
	    $server->command("MODE $channel +o " . $nick);
	}
    }
}

sub catch_commands
{
    my $server = $_[0];
    my $message = $_[1];
    my $nick = $_[2];
    my $address = $_[3];
    my $authed = 0;
    my $i;

    for($i = 0; $i < @mask_array && ! $authed; $i++)
    {
	if($server->mask_match_address($mask_array[$i], $nick, $address))
	{
	    $authed = 1;
	}
    }
    if(("!list show" cmp $message) == 0)
    {
	$server->command("MSG $nick " . "masks in auto-op list:");
	my $i;

	for($i = 0; $i < @mask_array; $i++)
	{
	    $server->command("MSG $nick " . ($i + 1) . ": " . $mask_array[$i]);
	}
	$server->command("MSG $nick " . "end");
    }
    if($message =~ /^\!list del ([0-9]+)$/)
    {
	if($authed == 0)
	{
	    $server->command("MSG $nick you are not authorized to modify auto-op list");
	    return;
	}
	my $remove_id = $1;
	my $old_length = @mask_array; # hax, but only way to make this work
	my $removed_mask = splice(@mask_array, $remove_id - 1, 1);

	if($old_length == @mask_array)
	{
	    $server->command("MSG $nick unable to remove mask with index $remove_id from auto-op list");
	}
	else
	{
	    save_masks();
	    $server->command("MSG $nick " . "removed $removed_mask from auto-op list");
	}
    }
    if($message =~ /^!list add/)
    {
	if($authed == 0)
	{
	    $server->command("MSG $nick you are not authorized to modify auto-op list");
	    return;
	}
	my $add_mask = $message;
	$add_mask =~ s/\!list add//;
	$add_mask =~ s/ //;
	push(@mask_array, $add_mask);
	save_masks();
	$server->command("MSG $nick " . "added $add_mask to auto-op list");
    }
}
load_masks();
Irssi::signal_add_last('message private', 'catch_commands');
Irssi::signal_add_last('message join', 'handle_join');
