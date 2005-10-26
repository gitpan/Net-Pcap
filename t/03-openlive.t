#!/usr/bin/perl -T
use strict;
use Test::More;
use lib 't';
use Utils;
BEGIN {
    if(is_allowed_to_use_pcap()) {
        plan tests => 14
    } else {
        plan skip_all => "must be run as root"
    }
}
use Net::Pcap;

eval "use Test::Exception"; my $has_test_exception = !$@;

my($dev,$pcap,$err) = ('','','');


# Testing error messages
SKIP: {
    skip "Test::Exception not available", 4 unless $has_test_exception;

    # open_live() errors
    throws_ok(sub {
        Net::Pcap::open_live()
    }, '/^Usage: Net::Pcap::open_live\(device, snaplen, promisc, to_ms, err\)/', 
       "calling open_live() with no argument");

    throws_ok(sub {
        Net::Pcap::open_live(0, 0, 0, 0, 0)
    }, '/^arg5 not a reference/', 
       "calling open_live() with no reference for arg5");

    # close() errors
    throws_ok(sub {
        Net::Pcap::close()
    }, '/^Usage: Net::Pcap::close\(p\)/', 
       "calling close() with no argument");

    throws_ok(sub {
        Net::Pcap::close(0)
    }, '/^p is not of type pcap_tPtr/', 
       "calling close() with incorrect argument type");

}

# Find a device
$dev = Net::Pcap::lookupdev(\$err);

# Testing open_live()
eval { $pcap = Net::Pcap::open_live($dev, 1024, 1, 0, \$err) };
is(   $@,   '', "open_live()" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';
ok( defined $pcap, " - \$pcap is defined" );
isa_ok( $pcap, 'SCALAR', " - \$pcap" );
isa_ok( $pcap, 'pcap_tPtr', " - \$pcap" );

# Testing close()
eval { Net::Pcap::close($pcap) };
is(   $@,   '', "close()" );
is(   $err, '', " - \$err must be null: $err" ); $err = '';

# Testing open_live() with fake device name
my $fakedev = 'this is not a device';
eval { $pcap = Net::Pcap::open_live($fakedev, 1024, 1, 0, \$err) };
is(   $@,   '', "open_live()" );
if($^O eq 'MSWin32' or $^O eq 'cygwin') {
    like( $err, '/^Error opening adapter:/', " - \$err must be set: $err" );
} elsif($^O eq 'darwin') {
    like( $err, '/^BIOCSETIF: $fakedev: Device not configured/', " - \$err must be set: $err" );
} else {
    like( $err, '/^ioctl: (?:No such device)/', " - \$err must be set: $err" );
}
is( $pcap, undef, " - \$pcap isn't defined" );
$err = '';

