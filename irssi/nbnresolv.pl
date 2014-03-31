use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = "0.3";
%IRSSI = (
    authors     => 'Janne Paalijarvi',
    name        => 'nbnresolv',
    description => 'A script for outputting netbios name fom file.',
    license     => 'GPL',
    changed	=> 'Sat Aug 14 15:31:16 EEST 2010'
);

my $nbnames_datafile = glob("~/netbiosnames.list");

sub lookup_nbname
{
    my $input_name = lc(shift);
    my $temp_line;
    my $temp_out;
    open(NBNAME_FILEHANDLE, $nbnames_datafile);

    while($temp_line = <NBNAME_FILEHANDLE>)
    {
	if($temp_line =~ /.*?([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\s+([^\s]+).*?/)
	{
	    if(lc($2) eq $input_name || lc($1) eq $input_name)
	    {
		if($temp_out)
		{
		    $temp_out .= " ; ";
		}
		$temp_out .=  $2 . " = " . $1;
	    }
	}
    }
    close(NBNAME_FILEHANDLE);

    if($temp_out)
    {
	return $temp_out;
    }
}

sub check_for_requests
{
    my ($server, $msg, $nick, $mask, $channel) = @_;

    if($msg =~ /^\!nbn[ ]+(.*)/ || $msg =~ /^\!nbnresolv[ ]+(.*)/)
    {
	my $nbname_result = lookup_nbname($1);

        if(length($nbname_result) > 3)
        {
            $server->command("MSG " . ($channel ? $channel . " " . $nick . ":" : $nick) . " " . $nbname_result);
        }
    }
}

Irssi::signal_add_last("message private", "check_for_requests");
Irssi::signal_add_last("message public", "check_for_requests");
