use Net::DNS;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.2";
%IRSSI = (
    authors     => 'Janne Paalijarvi',
    name        => 'wcresolv',
    description => 'A script for resolving hex to/from masks',
    license     => 'GPL',
    changed     => 'Sat Feb 20 23:33:54 EET 2010'
);

my $res   = Net::DNS::Resolver->new;
my $max_queries = 2;

sub resolve_wc
{
    my $error = 0;
    my $input_identifier = lc(shift);
    my $ip_addr = "";
    my $dns_name = "";
    my $wc_pref = "";

    if($input_identifier =~ /.*?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2}).*?/ &&
       length($input_identifier) == 8)
    {
	$wc_pref = $input_identifier;
	$ip_addr .= hex($1) . "." . hex($2) . "." . hex($3) . "." . hex($4);
    }
    elsif($input_identifier =~ /.*?([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3}).*?/)
    {
	if($1 >= 0 && $1 <= 255 &&
	   $2 >= 0 && $2 <= 255 &&
	   $3 >= 0 && $3 <= 255 &&
	   $4 >= 0 && $4 <= 255)
	{
	    $ip_addr = $1 . "." . $2 . "." . $3 . "." . $4;
	    $wc_pref = sprintf("%02x%02x%02x%02x", $1, $2, $3, $4);
	}
	else
	{
	    $error = 1;
	}
    }
    if($error != 1)
    {
	if(length($ip_addr) == 0 || length($wc_pref) == 0) # No info yet; trying lookup
	{
	    my $query = $res->search($input_identifier);

	    if($query)
	    {
		foreach my $rr ($query->answer)
		{
		    next unless $rr->type eq "A";
		    $ip_addr = $rr->address;
		    $ip_addr =~ /.*?([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3}).*?/;
		    $wc_pref = sprintf("%02x%02x%02x%02x", $1, $2, $3, $4);
		    $dns_name = $input_identifier;
		}
	    }
	    else
	    {
		$error = 1;
	    }
	}
	else
	{
	    my $query = $res->search($ip_addr);

	    if($query)
	    {
		foreach my $rr ($query->answer)
		{
		    next unless $rr->type eq "PTR";
		    $dns_name = $rr->ptrdname;
		}
	    }
	    else
	    {
		$dns_name = $ip_addr
	    }
	}
    }

    my @ret_arr = ( $error, $wc_pref, $ip_addr, $dns_name );
    return @ret_arr;
}


sub check_for_requests
{
    
    my ($server, $msg, $nick, $mask, $channel) = @_;
    my @cmd_data = split(/ +/, $msg);
    my @old_idents;

    if(!(lc($cmd_data[0]) eq "!wc"))
    {
	return;
    }
    Irssi::signal_stop();

    for(my $i = 1; $i <= @cmd_data && $i <= $max_queries; $i++)
    {
	if(length($cmd_data[$i]) >= 1)
	{
	    my @data_arr = resolve_wc($cmd_data[$i]);

	    if($data_arr[0] == 0) # No errors
	    {
		if(0 == grep(/$data_arr[1]/, @old_idents)) # No dupes
		{
		    my $ret_string = $data_arr[1] . " resolves to " . $data_arr[3] . " = " . $data_arr[2];
		    $server->command("MSG " . ($channel ? $channel : $nick) . " " . $ret_string);
		    unshift(@old_idents, ($data_arr[1]));
		}
	    }
	}
    }
}

Irssi::signal_add_last("message private", "check_for_requests");
Irssi::signal_add_last("message public", "check_for_requests");
