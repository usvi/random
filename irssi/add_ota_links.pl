
#otaniemi_linkit=# CREATE TABLE linkit (url TEXT, count BIGINT, nick_orig TEXT, time_orig BIGINT, nick_curr TEXT, time_curr BIGINT, karbaz BIGINT, scat BIGINT, loli BIGINT, japani BIGINT, anime BIGINT, tylsa BIGINT, wanha BIGINT, ok BIGINT, ero BIGINT, CONSTRAINT linkit_PK PRIMARY KEY (url));

use Irssi;
use strict;
use vars qw($VERSION %IRSSI);
use DBI;

$VERSION = '0.1';
%IRSSI =
(
 authors     => 'Mr. Janne Paalijarvi',
 contact     => 'usv@IRCnet',
 name        => 'Add otaniemi links',
 description => 'This script adds #otaniemi channel links to postgresql database',
 license     => 'GPL',
 changed     => 'Tue Aug  7 03:09:03 EEST 2007'
);

# DB definition:
#
# createuser -P otalink_add
# createuser -P otalink_www
# createdb otaniemi_links
# psql otaniemi_links
#
# CREATE TABLE links (
# url_id SERIAL PRIMARY KEY,
# url TEXT UNIQUE,
# count BIGINT,
# nick_orig TEXT,
# time_orig BIGINT,
# nick_curr TEXT,
# time_curr BIGINT,
# karbaz BIGINT,
# superior BIGINT,
# tylsa BIGINT,
# rasismi BIGINT,
# wanha BIGINT,
# tissit BIGINT);
# GRANT ALL ON links to otalink_add;
# ALTER TABLE links OWNER TO otalink_add;
# GRANT SELECT, UPDATE on links to otalink_www;



my $dbname = "otaniemi_links";
my $dbuser = "otalink_add";
my $passwd_file = Irssi::get_irssi_dir . "/otaniemi_passwd.txt";
open(PASSWD_FD, $passwd_file) or die("Could not open password file\n");
my @password_file_lines = <PASSWD_FD>;
close(PASSWD_FD);
my $dbpasswd = $password_file_lines[0];
$dbpasswd =~ s/^\s+//;
$dbpasswd =~ s/\s+$//;
my $valid_channel = "#otaniemi";

sub add_link
{
    # Add error reporting later

    my $nick = shift();
    my $link = shift();
    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $dbuser,  $dbpasswd);

    if(!$dbh)
    {
	print("Cannot connect to database:(");
	return;
    }
    my $sth = $dbh->prepare("SELECT * FROM links WHERE url LIKE '" . $link . "'");
    $sth->execute();
    my $query_result = $sth->fetchrow_hashref();
    $sth->finish();

    if(defined($query_result))
    {
	$link = $dbh->quote($link);
	$nick = $dbh->quote($nick);
	my $curr_time = time();
	$sth = $dbh->prepare("UPDATE links SET count = " . ($query_result->{count} + 1) . " , nick_curr = $nick, time_curr = $curr_time, " .
			     "wanha = " . ($query_result->{wanha} + 1) . " WHERE url_id = " . $query_result->{url_id});
	$sth->execute();
	$sth->finish();
    }
    else
    {
	my $init_karbaz = 0;
	my $init_rasismi = 0;

	if($link =~ "^khttp")
	{
	    $init_karbaz++;
	}
	if($link =~ m/hommaforum/i ||
	   $link =~ m/halla-aho\.com/i ||
	   $link =~ m/maahanm/i )
	{
	    $init_rasismi += 79262;
	}
	$link = $dbh->quote($link);
	$nick = $dbh->quote($nick);

	my $curr_time = time();
	$sth = $dbh->prepare("INSERT INTO links (url, count, nick_orig, time_orig, nick_curr, " .
			     "time_curr, karbaz, superior, tylsa, rasismi, wanha, tissit) VALUES " .
			     "($link, 1, $nick, $curr_time, $nick, $curr_time, $init_karbaz, 0, 0, $init_rasismi, 0, 0)");
	$sth->execute();
	$sth->finish();
    }
    $dbh->disconnect();
}

#sub add_link_cmd
#{
#    my ($data, $server, $witem) = @_;
#    my ($nick, $link) = split(/ /, $data);
#    $data =~ m/(http\:\/\/.*?[^( )\t]*)/;
#    $link = $1;
#
#    if($link)
#    {
#	add_link($nick, $link);
#    }
#}
#Irssi::command_bind('add_otaniemi_link','add_link_cmd');



sub check_for_urls
{
    my $temp_channel = lc($_[4]);
    my $temp_message = $_[1];
    my $temp_nick = $_[2];

    if($temp_channel eq $valid_channel)
    {
	my @url_tokens = ($temp_message =~ m/([k]{0,1}http[s]{0,1}\:\/\/.*?[^( )\t]*).*?/ig);

	foreach(@url_tokens)
	{
	    if(length($_) > 3)
	    {
		add_link($temp_nick, $_);
	    }
	}
    }
}
Irssi::signal_add('message public', 'check_for_urls');
