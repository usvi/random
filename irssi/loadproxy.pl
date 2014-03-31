use strict;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind active_win);

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Load proxy',
 description => 'Loads the proxy module for irssi',
 license     => 'GPL',
 changed     => 'Sat Nov 15 13:12:21 EET 2008'
 );

use Irssi;

active_win->command("LOAD proxy");
