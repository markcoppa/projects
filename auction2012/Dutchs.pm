#
# Dutchs.pm
# Purpose:    Contain the data and accesses for all dutch items
#

use Auction;
use Dutch;
use DBI;

package Dutchs;


# ctor
# Purpose:
#
#############################################################################
sub new
{
    my $self = {};
    $self->{auction} = new Auction();
    my $items = {};     # key = id, value = Dutchf object instance

    my $sql = "SELECT id FROM dutch_items";
    my $sth  = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();

    $self->{dutchs} = {};
    my $item_ids = $sth->fetchall_hashref("id");
    foreach my $key (keys %$item_ids)
    {
        $self->{dutchs}->{$key} = Dutch::new($key);
    }

    bless $self;
}

# LoadForBuyer
# Purpose:
#
#############################################################################
sub LoadForBuyer
{
    my ($self, $buyer_id) = @_;

    my $sql = "SELECT dutch_items.id as id, " .
              "       dutch_items.description as description, " .
              "       dutch_items.amount as amount, " .
              "       dutch_buyers.quantity as quantity " .
              "FROM dutch_items, dutch_buyers " .
              "WHERE dutch_buyers.buyer_id = $buyer_id AND " .
                     "dutch_buyers.dutch_items_id = dutch_items.id";
    my $sth  = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();

    $self->{dutchs} = {};
    my $item_ids = $sth->fetchall_hashref("id");
    foreach my $key (keys %$item_ids)
    {
        $self->{dutchs}->{$key} = Dutch::new($key);
        $self->{dutchs}->{$key}->{quantity} = $item_ids->{$key}->{quantity};
    }
}


1;
