#
# Dutch.pm
# Purpose:    Contain the data and accesses for a single dutch item
#
#  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
#  description text default NULL,
#  amount float DEFAULT 0
#

use Auction;
use DBI;

package Dutch;


# ctor
# Purpose:
#
#############################################################################
sub new
{
    my ($id) = @_;
    my $self = {};
    $self->{auction} = new Auction();

    if ($id && $id ne "")
    {
        $self->{id} = $id;
        Initialize($self, $id);
    }

    bless $self;
}


# Initialize
# Purpose:     Load with an existing item
#
#############################################################################
sub Initialize
{
    my ($self) = @_;

    my $sql = "SELECT * FROM dutch_items WHERE id=$self->{id}";
    my $sth = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();
    my $data = {};
    $data = $sth->fetchall_hashref("id");

    if (scalar keys %$data == 0)
    {
        $self->{id} = -1;
    }
    else
    {
        $self->{description} = $data->{$self->{id}}->{description};
        $self->{amount} = $data->{$self->{id}}->{amount};
    }
}


# Commit
# Purpose:    Update or create item record
#
#############################################################################
sub Commit
{
    my ($self) = @_;

    my $sql = "";
    if ($self->{id} && $self->{id} ne "" && $self->{id} != -1)
    {
        $sql = "UPDATE dutch_items SET " .
               "description=\"$self->{description}\", " .
               "amount=\"$self->{amount}\" " .
               "WHERE id=$self->{id}";
    }
    else
    {
        $sql = "INSERT INTO dutch_items (\"description\", \"amount\") " .
               "VALUES(\"$self->{description}\", \"$self->{amount}\")";
    }

    my $rows_affected = $self->{auction}->{dbh}->do($sql);

    return $rows_affected;
}

# IncrementBuyer
# Purpose:    
#
#############################################################################
sub IncrementBuyer
{
    my ($self, $buyer_id) = @_;

    my $sql = "SELECT * FROM dutch_buyers WHERE buyer_id = $buyer_id AND dutch_items_id = $self->{id}";
    my $sth = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();
    my $data = {};
    $data = $sth->fetchall_hashref("id");

    if ((scalar keys %$data) == 0)
    {
        $sql = "INSERT INTO dutch_buyers (\"buyer_id\", \"dutch_items_id\", \"quantity\") " .
               "VALUES(\"$buyer_id\", \"$self->{id}\", \"1\")";
    }
    else
    {
        $sql = "UPDATE dutch_buyers SET quantity = quantity + 1 " .
               "WHERE dutch_items_id=$self->{id} AND buyer_id = $buyer_id";
    }

    my $rows_affected = $self->{auction}->{dbh}->do($sql);
    return $rows_affected;
}


# GetTotal
# Purpose:    
#
#############################################################################
sub GetTotal
{
    my ($self) = @_;

    my $sql = "SELECT * FROM dutch_buyers WHERE dutch_items_id = $self->{id}";
    my $sth = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();
    my $data = {};
    $data = $sth->fetchall_hashref("id");

    my $total = 0;
    foreach my $id (keys %$data)
    {
        $total += $data->{$id}->{quantity} * $self->{amount};
    }
    return $total;
}

1;
