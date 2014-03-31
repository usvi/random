use strict;
use vars qw($VERSION %IRSSI);
use Irssi;

$VERSION = '1.0';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi. Google me.',
 contact     => 'usv@IRCnet',
 name        => 'Simple invite script',
 description => 'Invites people to channel when requested, if they match a mask.',
 license     => 'GPL',
 changed     => 'Tue Feb 16 00:02:59 EET 2010'
);

my $invitelist_file = Irssi::get_irssi_dir . "/otainvitelist.dat";
my %invite_masks = ();

# Invitelist datafile format:
#
# NetWork = {
#  #channel1 = {
#   mask1
#   mask2
#   mask3
#  }
#  #channel2 = {
#   mask4
#   mask5
#   mask5
#  }
# }
# NetWork2 = {
#  #channel3 = {
#   mask6
#   mask7
#  }
# }

sub load_masks
{
    open(invite_file_handle, "<", $invitelist_file);
    my $level = 0;
    my $network = "";
    my $channel = "";
    my $temp_line = "";

    while($temp_line = readline(*invite_file_handle))
    {
	if($temp_line =~ /[ ]*\}[ ]*/)
	{
	    $level--;
	}
	elsif($level == 0)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$network = $1;
		$level++;
		$invite_masks{$network} = ();
	    }
	}
	elsif($level == 1)
	{
	    if($temp_line =~ /[ ]*([^ \=]+)[ ]*\=[ ]*\{[ ]*\n/)
	    {
		$channel = $1;
		$level++;
		$invite_masks{$network}{$channel} = [];
	    }
	}
	elsif($level == 2)
	{
	    if($temp_line =~ /[ ]*([^ ]+)[ ]*\n/)
	    {
		push (@{$invite_masks{$network}{$channel}}, $1);
	    }
	}
    }
    close(invite_file_handle);
}

sub list_masks
{
    my $i = 1;

    for my $network ( keys %invite_masks )
    {
	print("Network: " . $network);

	for my $channel ( keys %{$invite_masks{$network}})
	{
	    print(" Channel: " . $channel);

	    foreach(@{$invite_masks{$network}{$channel}})
	    {
		print("  $i: " . $_);
		$i++;
	    }
	}
    }
}

sub save_masks
{
    open(invite_file_handle, ">", $invitelist_file);
    
    for my $network ( keys %invite_masks )
    {
	print(invite_file_handle $network . " = {\n");

	for my $channel ( keys %{$invite_masks{$network}})
	{
	    print(invite_file_handle " " . $channel . " = {\n");

	    foreach(@{$invite_masks{$network}{$channel}})
	    {
		print(invite_file_handle "  " . $_ . "\n")
	    }
	    print(invite_file_handle " }\n");
	}
	print(invite_file_handle "}\n");
    }
    close(invite_file_handle);
}

sub add_mask
{
    my ($args, $server, $witem) = @_;
    my @arg_array = split(/ +/, $args);
    
    if(@arg_array != 3)
    {
	print("Parameter error. Use arguments: mask #channel network");
	return;
    }
    my $add_network = "";

    for my $network ( keys %invite_masks )
    {
	if(lc($network) eq lc($arg_array[2]) && $add_network eq "")
	{
	    $add_network = $network;
	}
    }
    if($add_network eq "")
    {
	$add_network = $arg_array[2];
	$invite_masks{$add_network} = ();
    }
    my $add_channel = "";

    for my $channel ( keys %{$invite_masks{$add_network}})
    {
	if(lc($channel) eq lc($arg_array[1]) && $add_channel eq "")
	{
	    $add_channel = $channel;
	}
    }
    if($add_channel eq "")
    {
	$add_channel = $arg_array[1];
	$invite_masks{$add_network}{$add_channel} = [];
    }
    push (@{$invite_masks{$add_network}{$add_channel}}, $arg_array[0]);
    save_masks();
    print("Added " . $arg_array[0] . " $add_channel $add_network");
}

sub remove_mask
{
    my ($args, $server, $witem) = @_;
    my $i = 1;
    my @arg_array = split(/ +/, $args);
    
    if(@arg_array != 1)
    {
	print("Parameter error. Use index number as argument.");
	return;
    }
    my $remove_index = $arg_array[0];

    for my $network ( keys %invite_masks )
    {
	for my $channel ( keys %{$invite_masks{$network}})
	{
	    my $j = 0;

	    for($j = 0; $j < @{$invite_masks{$network}{$channel}}; $j++)
	    {
		if ($i == $remove_index)
		{
		    print("Removing " . ${$invite_masks{$network}{$channel}}[$j] . " from " . $channel. " (" . $network . ")");
		    splice(@{$invite_masks{$network}{$channel}}, $j, 1);

		    # Might have empty collections now
		    
		    if(@{$invite_masks{$network}{$channel}} == 0)
		    {
			delete($invite_masks{$network}{$channel});
		    }
		    if(scalar(keys(%{$invite_masks{$network}})) == 0)
		    {
			delete($invite_masks{$network});
		    }
		    return;
		}
		$i++;
	    }
	}
    }
    save_masks();
}

sub check_for_invites
{
    # If a private message on same network contains something like invite #channel, invite to the channel if possible

    my ($server, $msg, $nick, $address, $channel) = @_;
    my ($trigger, $channel) = split(/ +/, $msg);

    if($trigger =~ /invite/)
    {
	for my $check_network ( keys %invite_masks )
	{
	    if(lc($check_network) eq lc($server->{tag}))
	    {
		for my $check_channel ( keys %{$invite_masks{$check_network}})
		{
		    if(lc($check_channel) eq lc($channel))
		    {
			foreach(@{$invite_masks{$check_network}{$check_channel}})
			{
			    if($server->mask_match_address($_, $nick, $address))
			    {
				print("Inviting $nick to $channel (" . $server->{tag} . ")");
				$server->command("INVITE $nick $channel");
			    }
			}
		    }
		}
	    }
	}
    }

}

Irssi::signal_add_last("message private", "check_for_invites");

Irssi::command_bind("oiload", "load_masks");
Irssi::command_bind("oisave", "save_masks");
Irssi::command_bind("oilist", "list_masks");
Irssi::command_bind("oiadd", "add_mask");
Irssi::command_bind("oidel" , "remove_mask");


load_masks();
