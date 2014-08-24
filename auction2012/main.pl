
use strict;

use Buyer;
use Buyers;
use CGI;
use Dutch;
use Dutchs;
use Item;
use Items;


###########
# globals #
###########

my $ts = "<table border=\"1\" align=\"left\" cellpadding=\"5\">\n";
my $te = "</table>\n";
my $rs = "<tr>";
my $re = "</tr>\n";
my $hs = "<th>";
my $he = "</th>";
my $cs = "<td>";
my $ce = "</td>";

my $title = "2012 MVA Auction";
my $header = "";
my @contents;


########
# main #
########

my $q = CGI->new();
my $action = $q->param('action');

if (!$action)
{
    DisplayMain();
}
# Buyers
elsif ($action eq "view_all_buyers")
{
    ViewAllBuyers();
}
elsif ($action eq "view_buyer")
{
    ViewBuyer();
}
elsif ($action eq "edit_buyer")
{
    EditBuyer();
}
elsif ($action eq "add_new_buyer")
{
    AddNewBuyer();
}
elsif ($action eq "submit_buyer")
{
    SubmitBuyer();
}
# Items
elsif ($action eq "view_all_items")
{
    ViewAllItems();
}
elsif ($action eq "view_item")
{
    ViewItem();
}
elsif ($action eq "edit_item")
{
    EditItem();
}
elsif ($action eq "add_new_item")
{
    AddNewItem();
}
elsif ($action eq "submit_item")
{
    SubmitItem();
}
elsif ($action eq "bulk_update_items")
{
    BulkUpdateItems();
}
elsif ($action eq "submit_bulk_update_items")
{
    SubmitBulkUpdateItems();
}
# Dutch Items
elsif ($action eq "view_all_dutch")
{
    ViewAllDutch();
}
elsif ($action eq "buyer_dutch")
{
    BuyerDutch();
}
elsif ($action eq "edit_dutch")
{
    EditDutch();
}
elsif ($action eq "add_new_dutch")
{
    AddNewDutch();
}
elsif ($action eq "submit_buyer_dutch")
{
    SubmitBuyerDutch();
}
elsif ($action eq "submit_dutch")
{
    SubmitDutch();
}
# Reports
elsif ($action eq "auction_summary_report")
{
    AuctionSummaryReport();
}
elsif ($action eq "buyers_report")
{
    BuyersReport();
}
elsif ($action eq "items_report")
{
    ItemsReport();
}
else
{

}


#
# We have title, header, contents now so print it
#
print "Content-type: text/html\r\n\r\n";
print "<Title>$title</Title>\n";
print "<H1>$header</H1>\n";
print "<HR>\n"; 
foreach (@contents)
{
    print $_;
}
if ($action)
{
    print "<P>Return to <A HREF=\"\\test\\main.pl\">Main Menu</A>\n";
}
print "</HTML>\n";


########
# subs #
########

# DisplayMain
# Purpose:
#
#############################################################################
sub DisplayMain
{
    $header = "2012 MVA Auction";

    my $html = <<EOL;
<A HREF="\\test\\main.pl?action=view_all_buyers">Buyers</A></BR>
<A HREF="\\test\\main.pl?action=view_all_items">Items</A></BR>
<A HREF="\\test\\main.pl?action=view_all_dutch">Dutch Items</A></BR>
<P><HR>
<H3>Reports</H3>
<A HREF="\\test\\main.pl?action=auction_summary_report">Auction summary</A></BR>
<A HREF="\\test\\main.pl?action=buyers_report">Buyers report (warning: slow)</A></BR>
<A HREF="\\test\\main.pl?action=items_report">Items report</A></BR>
EOL

    push @contents, $html;
}

#
# Items subs
#

# ViewAllBuyers
# Purpose:
#
#############################################################################
sub ViewAllBuyers
{
    $title .= " - Buyers";
    $header = "Buyers";

    push @contents, "<HR><A HREF=\"\\test\\main.pl?action=edit_buyer\">Add a new buyer</A><HR>\n";

    push @contents, $ts;
    push @contents, "$rs${hs}ID$he${hs}Paddle$he${hs}Name$he$hs$he$hs$he$re";
    my $buyers = Buyers::new();
    my $list = $buyers->{buyers};
    foreach my $id (sort {$a <=> $b} keys %$list)
    {
        my $paddle = $list->{$id}->{paddle};
        $paddle ||= "unassigned";
        my $name = $list->{$id}->{first_name} . " " . $list->{$id}->{last_name};
        push @contents, "$rs$cs$id$ce$cs$paddle$ce$cs$name$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=view_buyer;id=$id\">View Details</A>$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=edit_buyer;id=$id\">Edit Details</A>$ce";

        push @contents, $re;
    }
    push @contents, $te;

}

# ViewBuyer
# Purpose:
#
#############################################################################
sub ViewBuyer
{
    my $id = $q->param('id');
    $title .= " - View Buyer ($id)";
    $header = "View Buyer";

    my $buyer = Buyer::new($id);
    if ($buyer->{id} == -1)
    {
        push @contents, "No record found for ID = $id!\n";
        return;
    }

    my $paddle = $buyer->{paddle} ? $buyer->{paddle} : "unassigned";
    my $detail = "$buyer->{first_name} $buyer->{last_name}<BR>$buyer->{street} $buyer->{city} $buyer->{state}" .
                 "<BR>$buyer->{zip}<BR>$buyer->{phone} $buyer->{email}<BR>Paddle: $paddle";
    push @contents, "$ts";
    push @contents, "$rs$cs$detail$ce$cs$ce$re";
    push @contents, GetBuyerDetailRows($buyer);
    push @contents, $te;

    push @contents, "<P>Return to <A HREF=\"\\test\\main.pl?action=view_all_buyers\">View All Buyers</A>\n";
}

# EditBuyer
# Purpose:
#
#############################################################################
sub EditBuyer
{
    my $id = $q->param('id');
    if ($id)
    {
        $title .= " - Edit Buyer ($id)";
        $header = "Edit Buyer";
    }
    else
    {
        $title .=  " - Add Buyer";
        $header = "Add Buyer";
    }

    my $buyer = Buyer::new($id);

    $id = $buyer->{id};
    my $first_name = "";
    my $last_name = "";
    my $street = "";
    my $city = "";
    my $state = "";
    my $zip = "";
    my $phone = "";
    my $email = "";
    my $paddle = "unassigned";
    my $paid_auction = "false";

    if ($id != -1)
    {
        $first_name = $buyer->{first_name};
        $last_name = $buyer->{last_name};
        $street = $buyer->{street};
        $city = $buyer->{city};
        $state = $buyer->{state};
        $zip = $buyer->{zip};
        $phone = $buyer->{phone};
        $email = $buyer->{email};
        $paddle = $buyer->{paddle} ? $buyer->{paddle} : "unassigned";
        $paid_auction = ($buyer->{paid_auction} eq "true") ? "checked=\"checked\"" : "";
    }

    push @contents, "<form action=\"\\test\\main.pl\" method=\"get\">\n";
    push @contents, "<input type=\"hidden\" name=\"action\" value=\"submit_buyer\"/>\n";
    push @contents, "<input type=\"hidden\" name=\"id\" value=\"$id\"/>\n";
    push @contents, $ts;
    push @contents, "$rs${cs}First name$ce$cs<input type=\"text\" name=\"first_name\" value=\"$first_name\"/>$ce$re";
    push @contents, "$rs${cs}Last name$ce$cs<input type=\"text\" name=\"last_name\" value=\"$last_name\"/>$ce$re";
    push @contents, "$rs${cs}Street$ce$cs<input type=\"text\" name=\"street\" value=\"$street\"/>$ce$re";
    push @contents, "$rs${cs}City$ce$cs<input type=\"text\" name=\"city\" value=\"$city\"/>$ce$re";
    push @contents, "$rs${cs}State$ce$cs<input type=\"text\" name=\"state\" value=\"$state\"/>$ce$re";
    push @contents, "$rs${cs}Zip$ce$cs<input type=\"text\" name=\"zip\" value=\"$zip\"/>$ce$re";
    push @contents, "$rs${cs}Phone$ce$cs<input type=\"text\" name=\"phone\" value=\"$phone\"/>$ce$re";
    push @contents, "$rs${cs}Email$ce$cs<input type=\"text\" name=\"email\" value=\"$email\"/>$ce$re";
    push @contents, "$rs${cs}Paddle$ce$cs<input type=\"text\" name=\"paddle\" value=\"$paddle\"/>$ce$re";
    push @contents, "$rs${cs}Paid auction$ce$cs<input type=\"checkbox\" name=\"paid_auction\" $paid_auction/>$ce$re";
    push @contents, "$rs$cs$ce$cs<input type=\"submit\" value=\"Submit\"/>$ce$re";

    push @contents, "$te</form>\n";
}

# SubmitBuyer
# Purpose:
#
#############################################################################
sub SubmitBuyer
{
    my $id = $q->param('id');
    if ($id != -1)
    {
        $title .= " - Submitting Buyer Changes ($id)";
        $header = "Submitting Buyer Changes";
    }
    else
    {
        $title .=  " - Submitting New Buyer";
        $header = "Submitting New Buyer";
    }

    my $buyer = Buyer::new($id);
    $buyer->{first_name} = $q->param('first_name');
    $buyer->{last_name} = $q->param('last_name');
    $buyer->{street} = $q->param('street');
    $buyer->{city} = $q->param('city');
    $buyer->{state} = $q->param('state');
    $buyer->{zip} = $q->param('zip');
    $buyer->{phone} = $q->param('phone');
    $buyer->{email} = $q->param('email');
    $buyer->{paddle} = $q->param('paddle');
    $buyer->{paid_auction} = ($q->param('paid_auction') eq "on" ? "true" : "false");

    my $rows = $buyer->Commit();

    if ($rows == 0)
    {
        push @contents, "Something bad happened\n";
    }
    else
    {
        push @contents, "Success!\n";
    }

    push @contents, "<P>Return to <A HREF=\"\\test\\main.pl?action=view_all_buyers\">View All Buyers</A>\n";
}

#
# Items subs
#

# ViewAllItems
# Purpose:
#
#############################################################################
sub ViewAllItems
{
    $title .= " - Items";
    $header = "Items";

    push @contents, "<HR><A HREF=\"\\test\\main.pl?action=edit_item\">Add a new item</A><HR>\n";
    push @contents, "<BR><A HREF=\"\\test\\main.pl?action=bulk_update_items\">Bulk update items</A><HR>\n";

    push @contents, $ts;
    push @contents, "$rs${hs}ID$he${hs}Description$he$hs$he$hs$he$re";
    my $items = Items::new();
    my $list = $items->{items};
    foreach my $id (sort {$a <=> $b} keys %$list)
    {
        push @contents, "$rs$cs$id$ce$cs$list->{$id}->{description}$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=view_item;id=$id\">View Details</A>$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=edit_item;id=$id\">Edit Details</A>$ce";

        push @contents, $re;
    }
    push @contents, $te;
}

# ViewItem
# Purpose:
#
#############################################################################
sub ViewItem
{
    my $id = $q->param('id');
    $title .= " - View Item ($id)";
    $header = "View Item";

    my $item = Item::new($id);

    if ($item->{id} == -1)
    {
        push @contents, "No record found for ID = $id!\n";
        return;
    }

    push @contents, "$ts";
    push @contents, "$rs${hs}Donor$he${hs}Website$he${hs}Description$he" .
                    "${hs}Value$he${hs}Auction type$he${hs}Buyer$he${hs}Final price$he" .
                    "${hs}Paid$he$re";
    push @contents, "$rs$cs$item->{donor}$ce" .
                    "$cs$item->{website}$ce" .
                    "$cs$item->{description}$ce" .
                    "$cs$item->{value}$ce" .
                    "$cs$item->{auction_type}$ce" .
                    "$cs$item->{buyers_id}$ce" .    # TODO link to name or edit buyer page
                    "$cs$item->{final_price}$ce" .
                    "$cs$item->{paid}$ce$re";
    push @contents, $te;
}

# EditItem
# Purpose:
#
#############################################################################
sub EditItem
{
    my $id = $q->param('id');
    if ($id)
    {
        $title .= " - Edit Item ($id)";
        $header = "Edit Item";
    }
    else
    {
        $title .=  " - Add Item";
        $header = "Add Item";
    }

    my $item = Item::new($id);

    $id = $item->{id};
    my $donor = "";
    my $website = "";
    my $description = "";
    my $value = "";
    my $auction_type = "";
    my $buyers_id = "";
    my $final_price = "";
    my $paid = "false";

    if ($id != -1)
    {
        $donor = $item->{donor};
        $website = $item->{website};
        $description = $item->{description};
        $value = $item->{value};
        $auction_type = $item->{auction_type};
        $buyers_id = $item->{buyers_id};
        $final_price = $item->{final_price};
        $paid = ($item->{paid} eq "true") ? "checked=\"checked\"" : "";
    }

    push @contents, "<form action=\"\\test\\main.pl\" method=\"get\">\n";
    push @contents, "<input type=\"hidden\" name=\"action\" value=\"submit_item\"/>\n";
    push @contents, "<input type=\"hidden\" name=\"id\" value=\"$id\"/>\n";
    push @contents, $ts;
    push @contents, "$rs${cs}Donor$ce$cs<input type=\"text\" name=\"donor\" value=\"$donor\"/>$ce$re";
    push @contents, "$rs${cs}Website$ce$cs<input type=\"text\" name=\"website\" value=\"$website\"/>$ce$re";
    push @contents, "$rs${cs}Description$ce$cs<input type=\"text\" name=\"description\" value=\"$description\"/>$ce$re";
    push @contents, "$rs${cs}Value$ce$cs<input type=\"text\" name=\"value\" value=\"$value\"/>$ce$re";
    push @contents, "$rs${cs}Auction type$ce$cs<input type=\"text\" name=\"auction_type\" value=\"$auction_type\"/>$ce$re";
    push @contents, "$rs${cs}Buyers ID$ce$cs<input type=\"text\" name=\"buyers_id\" value=\"$buyers_id\"/>$ce$re";
    push @contents, "$rs${cs}Final price$ce$cs<input type=\"text\" name=\"final_price\" value=\"$final_price\"/>$ce$re";
    push @contents, "$rs${cs}Paid$ce$cs<input type=\"checkbox\" name=\"paid\" $paid/>$ce$re";
    push @contents, "$rs$cs$ce$cs<input type=\"submit\" value=\"Submit\"/>$ce$re";

    push @contents, "$te</form>\n";
}

# BulkUpdateItems
# Purpose:
#
#############################################################################
sub BulkUpdateItems
{
    $title .= " - Bulk Update Items";
    $header = "Bulk Update Items";

    push @contents, "<form action=\"\\test\\main.pl\" method=\"POST\">\n";
    push @contents, "<input type=\"hidden\" name=\"action\" value=\"submit_bulk_update_items\"/>\n";
    push @contents, $ts;
    push @contents, "$rs${hs}ID$he${hs}Description$he${hs}Final Price$he${hs}Winning Paddle$he$re";
    my $items = Items::new();
    my $list = $items->{items};

    my $buyers = Buyers::new();

    foreach my $id (sort {$a <=> $b} keys %$list)
    {
        my $final_price_name = "final_price_$id";
        my $final_price_value = $list->{$id}->{final_price};
        my $final_price_input = "<input type=\"text\" name=\"$final_price_name\" value=\"$final_price_value\"/>";

        my $paddle_name = "paddle_$id";
        my $paddle_value = $buyers->GetPaddleFromId($list->{$id}->{buyers_id});
        $paddle_value = $paddle_value == -1 ? "" : $paddle_value;
        my $paddle_input = "<input type=\"text\" name=\"$paddle_name\" value=\"$paddle_value\"/>";

        push @contents, "$rs$cs$id$ce$cs$list->{$id}->{description}$ce$cs$final_price_input$ce$cs$paddle_input$ce";
        push @contents, $re;
    }

    push @contents, "$rs$cs$ce$cs<input type=\"submit\" value=\"Submit\"/>$ce$re";
    push @contents, "$te</form>\n";
}

# SubmitBulkUpdateItems
# Purpose:
#
#############################################################################
sub SubmitBulkUpdateItems
{
    $title .= " - Submit Bulk Update Items";
    $header = "Submit Bulk Update Items";

    my $buyers = Buyers::new();
    my @succeeded;
    my @failed;
    my $items = Items::new();

    my @submitted_names = $q->param;
    foreach my $name (@submitted_names)
    {
        next unless ($name =~ /final_price_(.+)/);
        my $id = $1;
        my $final_price = $q->param($name);
        my $paddle = $q->param("paddle_$id");
        next if ($final_price eq "" || $paddle eq "");

        my $buyers_id = $buyers->GetIdFromPaddle($paddle);
        if ($buyers_id == -1)
        {
            push @failed, "Submit of Item ID $id failed; unknown buyer for paddle $paddle";
            next;
        }

        my $item = $items->{items}->{$id};
        if (!$item)
        {
            push @failed, "Submit of Item ID $id failed; no known item with this id";
            next;
        }

        if ($item->{final_price} eq $final_price &&
            $item->{buyers_id} eq $buyers_id)
        {
            # Nothing to do
            next;
        }

        $item->{final_price} = $final_price;
        $item->{buyers_id} = $buyers_id;
        my $ret = $item->Commit();

        if ($ret == 1)
        {
            push @succeeded, "<BR>Item $id ($items->{items}->{$id}->{description}) updated.  Final price: $final_price  Buyer ID: $buyers_id  " .
                            "Buyer: $buyers->{buyers}->{$buyers_id}->{first_name} $buyers->{buyers}->{$buyers_id}->{last_name}\n";
        }
        else
        {
            push @failed, "Unknown failure when updating Item ID $id\n";
        }
    }

    push @contents, "Summary: " . (scalar @succeeded + scalar @failed) . " updates were required\n";
    if (scalar @succeeded > 0)
    {
        push @contents, "<BR>Succeeded (" . (scalar @succeeded) . "):\n";
        push @contents, @succeeded;
    }

    if (scalar @failed > 0)
    {
        push @contents, "<BR>Failed (" . (scalar @failed) . "):\n";
        push @contents, @failed;
    }
}

# SubmitItem
# Purpose:
#
#############################################################################
sub SubmitItem
{
    my $id = $q->param('id');
    if ($id != -1)
    {
        $title .= " - Submitting Item Changes ($id)";
        $header = "Submitting Item Changes";
    }
    else
    {
        $title .=  " - Submitting New Item";
        $header = "Submitting New Item";
    }

    my $item = Item::new($id);
    $item->{donor} = $q->param('donor');
    $item->{website} = $q->param('website');
    $item->{description} = $q->param('description');
    $item->{value} = $q->param('value');
    $item->{auction_type} = $q->param('auction_type');
    $item->{buyers_id} = $q->param('buyers_id');
    $item->{final_price} = $q->param('final_price');
    $item->{paid} = ($q->param('paid') eq "on" ? "true" : "false");

    my $rows = $item->Commit();

    if ($rows == 0)
    {
        push @contents, "Something bad happened\n";
    }
    else
    {
        push @contents, "Success!\n";
    }

    push @contents, "<P>Return to <A HREF=\"\\test\\main.pl?action=view_all_items\">View All Items</A>\n";
}

#
# Dutch subs
#

# ViewAllDutch
# Purpose:
#
#############################################################################
sub ViewAllDutch
{
    $title .= " - Dutch Items";
    $header = "Dutch Items";

    push @contents, "<HR><A HREF=\"\\test\\main.pl?action=edit_dutch\">Add a new dutch item</A><HR>\n";

    push @contents, $ts;
    push @contents, "$rs${hs}ID$he${hs}Description$he${hs}Amount$he$hs$he$hs$he$re";
    my $dutchs = Dutchs::new();
    my $list = $dutchs->{dutchs};
    foreach my $id (sort {$a <=> $b} keys %$list)
    {
        push @contents, "$rs$cs$id$ce$cs$list->{$id}->{description}$ce$cs$list->{$id}->{amount}$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=buyer_dutch;id=$id\">Bulk Add Buyers</A>$ce";
        push @contents, "$cs<A HREF=\"\\test\\main.pl?action=edit_dutch;id=$id\">Edit Details</A>$ce";

        push @contents, $re;
    }
    push @contents, $te;

}

# BuyerDutch
# Purpose:
#
#############################################################################
sub BuyerDutch
{
    my $id = $q->param('id');
    $title .= " - Bulk Add Buyers for Dutch Auction ($id)";
    $header = "Bulk Add Buyers for Dutch Auction";

    if (!$id)
    {
        push @contents, "Dutch item ID is not recognized\n";
        return;
    }

    my $dutch = Dutch::new($id);
    push @contents, "$dutch->{description} (\$$dutch->{amount})\n";
    push @contents, "<P>\n";

    push @contents, "<form action=\"\\test\\main.pl\" method=\"POST\">\n";
    push @contents, "<input type=\"hidden\" name=\"action\" value=\"submit_buyer_dutch\"/>\n";
    push @contents, "<input type=\"hidden\" name=\"id\" value=\"$id\"/>\n";
    push @contents, $ts;
    push @contents, "$rs${cs}Buyer IDs$ce$cs<input type=\"text\" name=\"paddles\" value=\"\"/>$ce$re";
    push @contents, "$rs$cs$ce$cs<input type=\"submit\" value=\"Submit\"/>$ce$re";
    push @contents, "$te</form>\n";

    push @contents, "<P>Notes:<BR>List buyer paddles, separated by commas." .
                    "<BR>This form will increment each paddle with one win of this dutch auction.\n";

}

# EditDutch
# Purpose:
#
#############################################################################
sub EditDutch
{
    my $id = $q->param('id');
    if ($id)
    {
        $title .= " - Edit Dutch Item ($id)";
        $header = "Edit Dutch Item";
    }
    else
    {
        $title .=  " - Add Dutch Item";
        $header = "Add Dutch Item";
    }

    my $dutch = Dutch::new($id);

    $id = $dutch->{id};
    my $description = "";
    my $amount = "";

    if ($id != -1)
    {
        $description = $dutch->{description};
        $amount = $dutch->{amount};
    }

    push @contents, "<form action=\"\\test\\main.pl\" method=\"get\">\n";
    push @contents, "<input type=\"hidden\" name=\"action\" value=\"submit_dutch\"/>\n";
    push @contents, "<input type=\"hidden\" name=\"id\" value=\"$id\"/>\n";
    push @contents, $ts;
    push @contents, "$rs${cs}Description$ce$cs<input type=\"text\" name=\"description\" value=\"$description\"/>$ce$re";
    push @contents, "$rs${cs}Amount$ce$cs<input type=\"text\" name=\"amount\" value=\"$amount\"/>$ce$re";
    push @contents, "$rs$cs$ce$cs<input type=\"submit\" value=\"Submit\"/>$ce$re";
    push @contents, "$te</form>\n";
}

# SubmitBuyerDutch
# Purpose:
#
#############################################################################
sub SubmitBuyerDutch
{
    my $id = $q->param('id');
    $title .= "Submitting Buyers for Dutch Item ($id)";
    $header = "Submitting Buyers for Dutch Item";

    if ($id == -1 || !$id)
    {
        push @contents, "Dutch Item not found\n";
        return;
    }

    my @paddles = split /,/, $q->param('paddles');
    if (scalar @paddles == 0)
    {
        push @contents, "No buyer paddles have been specified\n";
        return;
    }

    my $dutch = Dutch::new($id);

    my @failed;
    my @succeeded;

    my $buyers = Buyers::new();
    foreach my $paddle (@paddles)
    {
        my $buyer_id = $buyers->GetIdFromPaddle($paddle);
        if (!$buyer_id || $buyer_id == -1)
        {
            push @failed, "<BR>Unknown buyer for paddle $paddle";
            next;
        }

        if ($dutch->IncrementBuyer($buyer_id))
        {
            push @succeeded, "<BR>Buyer $buyer_id added for this dutch item\n";
        }
        else
        {
            push @failed, "<BR>Unknown failure adding buyer $buyer_id for this dutch item\n";
        }
    } 

    push @contents, "Summary: " . (scalar @succeeded + scalar @failed) . " updates were required\n";
    if (scalar @succeeded > 0)
    {
        push @contents, "<BR>Succeeded (" . (scalar @succeeded) . "):\n";
        push @contents, @succeeded;
    }

    if (scalar @failed > 0)
    {
        push @contents, "<BR>Failed (" . (scalar @failed) . "):\n";
        push @contents, @failed;
    }

    push @contents, "<P>Return to <A HREF=\"\\test\\main.pl?action=view_all_dutch\">View All Dutch Items</A>\n";

}

# SubmitDutch
# Purpose:
#
#############################################################################
sub SubmitDutch
{
    my $id = $q->param('id');
    if ($id != -1)
    {
        $title .= " - Submitting Dutch Changes ($id)";
        $header = "Submitting Dutch Changes";
    }
    else
    {
        $title .=  " - Submitting New Dutch";
        $header = "Submitting New Dutch";
    }

    my $dutch = Dutch::new($id);
    $dutch->{description} = $q->param('description');
    $dutch->{amount} = $q->param('amount');

    my $rows = $dutch->Commit();

    if ($rows == 0)
    {
        push @contents, "Something bad happened\n";
    }
    else
    {
        push @contents, "Success!\n";
    }

    push @contents, "<P>Return to <A HREF=\"\\test\\main.pl?action=view_all_dutch\">View All Dutch Items</A>\n";
}

# AuctionSummaryReport
# Purpose:
#
#############################################################################
sub AuctionSummaryReport
{
    $title .= " - Auction Summary Report";
    $header = "Auction Summary Report";

    my $buyers = Buyers::new();
    my $dutchs = Dutchs::new();
    my $items = Items::new();

    my $items_total = 0;
    my $items_count = 0;
    my $num_non_bid_items = 0;
    foreach my $id (keys %{$items->{items}})
    {
        my $item = $items->{items}->{$id};
        ++$items_count;

        my $final_price = $item->{final_price};
        if (!$final_price or $final_price == 0)
        {
            ++$num_non_bid_items;
        }
        else
        {
            $items_total += $final_price;
        }
    }

    my $dutch_detail = "";
    my $dutch_total = 0;
    foreach my $id (keys %{$dutchs->{dutchs}})
    {
        my $dutch = $dutchs->{dutchs}->{$id};

        my $total = $dutch->GetTotal();
        $dutch_total += $total;
        $total = MakeDollar($total);
        $dutch_detail .= "<BR><LI>$dutch->{description} ($dutch->{amount}): $total</LI>\n";
    }

    $dutch_total = MakeDollar($dutch_total);
    $items_total = MakeDollar($items_total);
    my $grand_total = MakeDollar($dutch_total + $items_total);

    my $content = <<EOL;
<BR>Items count: $items_count
<BR>Non-bid items count: $num_non_bid_items
<BR>Dutch auction detail: $dutch_detail
<BR>Dutch total: $dutch_total
<BR>Items total: $items_total
<BR>Grand total: $grand_total
<P>
EOL

    push @contents, $content;
}

# ItemsReport
# Purpose:
#
#############################################################################
sub ItemsReport
{
    $title .= " - Items Report";
    $header = "Items Report";

    my $items = Items::new();

    $items = $items->{items};
    push @contents, $ts;
    push @contents, "$rs${hs}Description$he${hs}Final price$he" .
                    "${hs}Winning bidder$he$re";
    foreach my $id (sort {$a <=> $b} keys %$items)
    {
        my $final_price = MakeDollar($items->{$id}->{final_price});
        my $buyer = Buyer::new($items->{$id}->{buyers_id});
        my $name = "$buyer->{first_name} $buyer->{last_name}";
        push @contents, "$rs$cs$items->{$id}->{description}$ce" .
                        "$cs$final_price$ce" .
                        "$cs$name$ce$re";
    }
    push @contents, $te;
}

# BuyersReport
# Purpose:
#
#############################################################################
sub BuyersReport
{
    $title .= " - Buyers Report";
    $header = "Buyers Report";

    my $buyers = Buyers::new();

    push @contents, $ts;
    foreach my $id (sort {$a <=> $b} keys %{$buyers->{buyers}})
    {
        my $buyer = Buyer::new($id);
        my $dutchs = $buyer->{dutchs};
        my $items = $buyer->{items};

        # Only print buyers that have won something
        next if ((scalar keys %$dutchs) ==  0 && (scalar keys %$items) == 0);

        my $paddle = $buyer->{paddle} ? $buyer->{paddle} : "unassigned";
        my $detail = "$buyer->{first_name} $buyer->{last_name}<BR>$buyer->{street} $buyer->{city} $buyer->{state}" .
                     "<BR>$buyer->{zip}<BR>$buyer->{phone} $buyer->{email}<BR>Paddle: $paddle";
        push @contents, "$rs$cs$detail$ce$cs$ce$re";
        push @contents, GetBuyerDetailRows($buyer);
        push @contents, "$rs$cs-$ce$cs-$ce$re";
    }

    push @contents, $te;
}

# GetBuyerDetailRows
# Purpose:      Used by both 'buyer_detail' and 'buyers_report'
#
#############################################################################
sub GetBuyerDetailRows
{
    my ($buyer) = @_;
    my $content = "";

    my $dutchs = $buyer->{dutchs};
    my $items = $buyer->{items};

    # Only print buyers that have won something
    return if ((scalar keys %$dutchs) ==  0 && (scalar keys %$items) == 0);

    # Print dutch
    if (scalar keys %$dutchs > 0)
    {
        $content .= "$rs${cs}<I><B>Dutch items</B></I>$ce$cs$ce$re";
        foreach my $dutch_id (sort {$a <=> $b} keys %$dutchs)
        {
            my $dutch = $dutchs->{$dutch_id};
            my $dutch_amount = MakeDollar($dutch->{amount});
            my $dutch_total = MakeDollar($dutch->{amount} * $dutch->{quantity});
            $content .= "$rs$cs$dutch->{description} $dutch_amount ($dutch->{quantity})$ce" .
                        "$cs$dutch_total$ce$re";
        }
        $content .= "$rs${cs}Dutch total$ce$cs" . MakeDollar($buyer->{dutch_total}) . "$ce$re";
    }

    # Print items
    if (scalar keys %$items > 0)
    {
        $content .= "$rs${cs}<I><B>Auction items</B></I>$ce$cs$ce$re";
        foreach my $item_id (sort {$a <=> $b} keys %$items)
        {
            my $item = $items->{$item_id};
            $content .= "$rs$cs$item->{description}$ce" .
                        "$cs" . MakeDollar($item->{final_price}) . "$ce$re";
        }
        $content .= "$rs${cs}Auction items total$ce$cs" . MakeDollar($buyer->{items_total}) . "$ce$re";
    }

    # Print grand total
    $content .= "$rs${cs}Grand total$ce$cs" .
                MakeDollar($buyer->{dutch_total} + $buyer->{items_total}) .
                "$ce$re";

    return $content;
}

# MakeDollar
# Purpose:
#
#############################################################################
sub MakeDollar
{
    my ($a) = @_;

    $a = reverse $a;
    my $dollar;
    my $ta;
    foreach my $number (split //, $a)
    {
        $dollar .= "," if ($ta && length($ta)%3 == 0);
        $dollar .= "$number";
        $ta .= $number;
    }

    return ("\$" . reverse $dollar);
}

# _
# Purpose:
#
#############################################################################
sub _
{


}


1;
