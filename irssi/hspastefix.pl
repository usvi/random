use strict;
use vars qw($VERSION %IRSSI %channels);
use Irssi;

$VERSION = '0.2';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usvi@IRCnet',
 name        => 'HS-pastefix',
 description => 'Fixes (Helsingin Sanomat) soft hyphens when pasting',
 license     => 'BSD',
 changed     => 'Wed Aug 29 10:33:32 EEST 2012'
);

# Helsingin Sanomat, among others, uses soft hyphens in their news articles.
# This is all hip and cool, but it breaks when you paste the texts to a terminal
# which isn't smart enough to handle them. This is very annoying in IRC.
# This script turns every outgoing query or channel message in irssi to
# a non-soft-hyphen version of the original.
#
# Version history:
# 0.2: Initial release

sub event_send_text ($$$)
{
    my ($line, $server, $witem) = @_;
    return unless ($witem && 
		   ($witem->{type} eq "CHANNEL" || $witem->{type} eq "QUERY"));
    my $corrected_line = $line;

    if ($corrected_line =~ tr/­//d)
    {
	Irssi::signal_stop();
	$server->command("/MSG -$server->{tag} $witem->{name} " . $corrected_line );
    }
}

Irssi::signal_add('send text', \&event_send_text);

