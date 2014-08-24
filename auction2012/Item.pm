#
# Item.pm
# Purpose:    Contain the data and accesses for a single item
#
#  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
#  donor varchar(255) DEFAULT NULL, 
#  website varchar(255) DEFAULT NULL, 
#  description text DEFAULT NULL, 
#  value float DEFAULT NULL, 
#  auction_type varchar(255) DEFAULT NULL, 
#  buyers_id integer DEFAULT NULL, 
#  final_price float DEFAULT NULL,
#  paid boolean default false
#

use Auction;
use DBI;

package Item;


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

    my $sql = "SELECT * FROM items WHERE id=$self->{id}";
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
        $self->{donor} = $data->{$self->{id}}->{donor};
        $self->{website} = $data->{$self->{id}}->{website};
        $self->{description} = $data->{$self->{id}}->{description};
        $self->{value} = $data->{$self->{id}}->{value};
        $self->{auction_type} = $data->{$self->{id}}->{auction_type};
        $self->{buyers_id} = $data->{$self->{id}}->{buyers_id};
        $self->{final_price} = $data->{$self->{id}}->{final_price};
        $self->{paid} = $data->{$self->{id}}->{paid};
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
        $sql = "UPDATE items SET " .
               "donor=\"$self->{donor}\", " .
               "website=\"$self->{website}\", " .
               "description=\"$self->{description}\", " .
               "value=\"$self->{value}\", " .
               "auction_type=\"$self->{auction_type}\", " .
               "buyers_id=\"$self->{buyers_id}\", " .
               "final_price=\"$self->{final_price}\", " .
               "paid=\"$self->{paid}\" " .
               "WHERE id=$self->{id}";
    }
    else
    {
        $sql = "INSERT INTO items (\"donor\", \"website\", \"description\", \"value\", " .
               "\"auction_type\", \"buyers_id\", \"final_price\", \"paid\") " .
               "VALUES(\"$self->{donor}\", \"$self->{website}\", \"$self->{description}\"," .
               "\"$self->{value}\", \"$self->{auction_type}\"," .
               "\"$self->{buyers_id}\", \"$self->{final_price}\", \"$self->{paid}\")";
    }

    my $rows_affected = $self->{auction}->{dbh}->do($sql);

    return $rows_affected;
}


1;
