#
# Buyers.pm
# Purpose:    Contain the data and accesses for all buyers
#

use Auction;
use Buyer;
use DBI;
package Buyers;


# ctor
# Purpose:
#
#############################################################################
sub new
{
    my $self = {};
    $self->{auction} = new Auction();
    my $buyers = {};     # key = id, value = Buyer object instance

    my $sql = "SELECT id FROM buyers";
    my $sth  = $self->{auction}->{dbh}->prepare($sql);
    $sth->execute();

    $self->{buyers} = {};
    my $buyer_ids = $sth->fetchall_hashref("id");
    foreach my $key (keys %$buyer_ids)
    {
        $self->{buyers}->{$key} = Buyer::new($key, 1);
    }

    bless $self;
}

# GetIdFromPaddle
# Purpose:
#
#############################################################################
sub GetIdFromPaddle
{
    my ($self, $paddle) = @_;

    my $id = -1;
    foreach my $buyer (%{$self->{buyers}})
    {
        if ($buyer->{paddle} eq $paddle)
        {
            $id = $buyer->{id};
            last;
        }
    }

    return $id;
}

# GetPaddleFromId
# Purpose:
#
#############################################################################
sub GetPaddleFromId
{
    my ($self, $id) = @_;

    my $paddle = $self->{buyers}->{$id}->{paddle};
    $paddle ||= -1;

    return $paddle;
}

1;
