#!/usr/bin/perl
#
# Test loop function
#
# $Id: 04-loop.t,v 1.5 1999/03/15 06:33:29 tpot Exp $
#

use strict;
use English;

use ExtUtils::testlib;
use Net::Pcap;

print("1..1\n");

# Must run as root

if ($UID != 0) {
    print("must run as root!\n");
    print("not ok\n");
    exit;
}

my($dev, $pcap_t, $err);

#
# Test loop on open_live interface
#

$dev = Net::Pcap::lookupdev(\$err);
$pcap_t = Net::Pcap::open_live($dev, 1024, 1, 0, \$err);

if (!defined($pcap_t)) {
    print("Net::Pcap::open_live returned error $err\n");
    print("not ok\n");
    exit;
}

my $count = 0;

sub process_pkt {
    my($user, $hdr, $pkt) = @_;

    if (($user ne "abc") or !defined($hdr) or !defined($pkt)) {
	print("Bad args passed to callback\n");
	print("Bad user data\n"), if ($user ne "abc");
	print("Bad pkthdr\n"), if (!defined($hdr));
	print("Bad pkt data\n"), if (!defined($pkt));
	print("not ok\n");
	exit;
    }

    print("Received packet of len $hdr->{len}\n");
    $count++;
}

Net::Pcap::loop($pcap_t, 10, \&process_pkt, "abc");

if ($count != 10) {
    print("Bad pkt count\n");
    print("not ok\n");
    exit;
}

Net::Pcap::close($pcap_t);

print("ok\n");
