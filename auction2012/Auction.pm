
use DBI;
package Auction;


my $dbfile = "c:\\dev\\auction2012\\2012dev.db";

sub new
{
    my $self;
    $self->{dbh} = DBI->connect("DBI:SQLite:dbname=$dbfile", "", "");

    bless $self;
}
