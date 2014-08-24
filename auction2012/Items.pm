#
# Items.pm
# Purpose:    Contain the data and accesses for all items
#

use Auction;
use Item;
use DBI;

package Items;


# ctor
# Purpose:
#
#############################################################################
sub new
{
    my $self = {};
    $self->{auction} = new Auction();
    my $items = {};     # key = id, value = Item object instance

    my $sql = "SELECT id FROM items";
    my $sth  = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();

    $self->{items} = {};
    my $item_ids = $sth->fetchall_hashref("id");
    foreach my $key (keys %$item_ids)
    {
        $self->{items}->{$key} = Item::new($key);
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

    my $sql = "SELECT id FROM items WHERE buyers_id=$buyer_id";
    my $sth  = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();

    $self->{items} = {};
    my $item_ids = $sth->fetchall_hashref("id");
    foreach my $key (keys %$item_ids)
    {
        $self->{items}->{$key} = Item::new($key);
    }
}


1;
