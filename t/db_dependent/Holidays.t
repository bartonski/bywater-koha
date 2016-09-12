#!/usr/bin/perl

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use DateTime;
use DateTime::TimeZone;

use t::lib::TestBuilder;
use C4::Context;
use C4::Calendar;

use Test::More tests => 6;

BEGIN { use_ok('Koha::Calendar'); }

my $dbh = C4::Context->dbh();

my $sundays = { open_hour    => 0,
                    open_minute  => 0,
                    close_hour   => 0,
                    close_minute => 0,
                    title        => 'Closed on Sundays',
                    description  => 'This is an example holiday used for testing' };

# Make Sunday a closed day
ModRepeatingEvent( 'OAK', 0, undef, undef, $sundays );

my $branchcode = 'OAK';

my $koha_calendar = Koha::Calendar->new( branchcode => $branchcode );

isa_ok( $koha_calendar, 'Koha::Calendar', 'Koha::Calendar class returned' );

my $sunday = DateTime->new(
    year  => 2011,
    month => 6,
    day   => 26,
);
my $monday = DateTime->new(
    year  => 2011,
    month => 6,
    day   => 27,
);
my $christmas = DateTime->new(
    year  => 2032,
    month => 12,
    day   => 25,
);
my $newyear = DateTime->new(
    year  => 2035,
    month => 1,
    day   => 1,
);

is( $koha_calendar->is_holiday($sunday),    1, 'Sunday is a closed day' );
is( $koha_calendar->is_holiday($monday),    0, 'Monday is not a closed day' );
is( $koha_calendar->is_holiday($christmas), 1, 'Christmas is a closed day' );
is( $koha_calendar->is_holiday($newyear), 1, 'New Years day is a closed day' );
