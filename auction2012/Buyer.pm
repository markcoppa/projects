#
# Buyer.pm
# Purpose:    Contain the data and accesses for a single buyer
#

use Auction;
use Dutch;
use Dutchs;
use Item;
use Items;
use DBI;

package Buyer;


# ctor
# Purpose:
#
#############################################################################
sub new
{
    my ($id, $lean_load) = @_;

    my $self = {};
    $self->{lean_load} = $lean_load;

    $self->{auction} = new Auction();

    if ($id && $id ne "")
    {
        $self->{id} = $id;
        Initialize($self, $id);
    }

    bless $self;
}


# Initialize
# Purpose:     Load with an existing buyer
#
#############################################################################
sub Initialize
{
    my ($self) = @_;

    my $sql = "SELECT * FROM buyers WHERE id=$self->{id}";
    my $sth = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();
    my $buyer = {};
    $buyer = $sth->fetchall_hashref("id");

    if (scalar keys %$buyer == 0)
    {
        $self->{id} = -1;
    }
    else
    {
        $self->{first_name} = $buyer->{$self->{id}}->{first_name};
        $self->{last_name} = $buyer->{$self->{id}}->{last_name};
        $self->{street} = $buyer->{$self->{id}}->{street};
        $self->{city} = $buyer->{$self->{id}}->{city};
        $self->{state} = $buyer->{$self->{id}}->{state};
        $self->{zip} = $buyer->{$self->{id}}->{zip};
        $self->{phone} = $buyer->{$self->{id}}->{phone};
        $self->{email} = $buyer->{$self->{id}}->{email};
        $self->{paddle} = $buyer->{$self->{id}}->{paddle};
        $self->{paid_auction} = $buyer->{$self->{id}}->{paid_auction};

        if (!$self->{lean_load})
        {
            my $items = Items::new();
            $items->LoadForBuyer($self->{id});
            $self->{items} = $items->{items};
            foreach my $item_id (keys %{$self->{items}})
            {
                $self->{items_total} += $self->{items}->{$item_id}->{final_price};
            }


            my $dutchs = Dutchs::new();
            $dutchs->LoadForBuyer($self->{id});
            $self->{dutchs} = $dutchs->{dutchs};
            foreach my $dutch_id (keys %{$self->{dutchs}})
            {
                $self->{dutch_total} += ($self->{dutchs}->{$dutch_id}->{amount} * $self->{dutchs}->{$dutch_id}->{quantity});
            }
        }
    }
}


# Commit
# Purpose:    Update or create buyer record
#
#############################################################################
sub Commit
{
    my ($self) = @_;

    my $sql = "";
    if ($self->{id} && $self->{id} ne "" && $self->{id} != -1)
    {
        $sql = "UPDATE buyers SET " .
               "first_name=\"$self->{first_name}\", " .
               "last_name=\"$self->{last_name}\", " .
               "street=\"$self->{street}\", " .
               "city=\"$self->{city}\", " .
               "state=\"$self->{state}\", " .
               "zip=\"$self->{zip}\", " .
               "phone=\"$self->{phone}\", " .
               "email=\"$self->{email}\", " .
               "paddle=\"$self->{paddle}\", " .
               "paid_auction=\"$self->{paid_auction}\" " .
               "WHERE id=$self->{id}";
    }
    else
    {
        $sql = "INSERT INTO buyers (\"first_name\", \"last_name\", \"street\", \"city\", " .
               "\"state\", \"zip\", \"phone\", \"email\", \"paddle\", \"paid_auction\") " .
               "VALUES(\"$self->{first_name}\", \"$self->{last_name}\", \"$self->{street}\"," .
               "\"$self->{city}\", \"$self->{state}\"," .
               "\"$self->{zip}\", \"$self->{phone}\", \"$self->{email}\"," .
               "\"$self->{paddle}\", \"$self->{paid_auction}\")";
    }

    my $rows_affected = $self->{auction}->{dbh}->do($sql);

    return $rows_affected;
}


1;
