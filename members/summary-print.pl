#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use CGI;

use C4::Auth;
use C4::Output;
use C4::Members;
use C4::Koha qw( getitemtypeinfo );
use C4::Circulation qw( GetIssuingCharges );
use Koha::Database;

my $schema = Koha::Database->new()->schema();

my $input          = CGI->new;
my $borrowernumber = $input->param('borrowernumber');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "members/moremember-print.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { circulate => "circulate_remaining_permissions" },
        debug           => 1,
    }
);

my $data = GetMember( 'borrowernumber' => $borrowernumber );

our $totalprice = 0;

$template->param(
    %$data,

    borrowernumber => $borrowernumber,

    account_balance => $data->{account_balance},
    account_debits => $schema->resultset('AccountDebit')->search({ borrowernumber => $borrowernumber }),
    account_credits => $schema->resultset('AccountDebit')->search({ borrowernumber => $borrowernumber }),

    issues     => build_issue_data( GetPendingIssues($borrowernumber) ),
    totalprice => $totalprice,
);

output_html_with_http_headers $input, $cookie, $template->output;

sub build_issue_data {
    my $issues = shift;

    my $return = [];

    my $today = DateTime->now( time_zone => C4::Context->tz );
    $today->truncate( to => 'day' );

    foreach my $issue ( @{$issues} ) {

        my %row = %{$issue};
        $totalprice += $issue->{replacementprice}
            if ( $issue->{replacementprice} );

        #find the charge for an item
        my ( $charge, $itemtype ) =
          GetIssuingCharges( $issue->{itemnumber}, $borrowernumber );

        my $itemtypeinfo = getitemtypeinfo($itemtype);
        $row{'itemtype_description'} = $itemtypeinfo->{description};

        $row{'charge'} = sprintf( "%.2f", $charge );

        $row{date_due} = $row{date_due_sql};

        push( @{$return}, \%row );
    }

    @{$return} = sort { $a->{date_due} eq $b->{date_due} } @{$return};

    return $return;
}
