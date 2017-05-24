#!/usr/bin/perl
#
# memcached-tool:
#   stats/management tool for memcached.
#
# Author:
#   Brad Fitzpatrick <brad@danga.com>
#
# Contributor:
#   Andrey Niakhaichyk <andrey@niakhaichyk.org>
#
# License:
#   public domain.  I give up all rights to this
#   tool.  modify and copy at will.
#

use strict;
use IO::Socket::INET;

my $addr = shift;
my $mode = shift || "display";
my ($from, $to);

if ($mode eq "display") {
    undef $mode if @ARGV;
} elsif ($mode eq "move") {
    $from = shift;
    $to = shift;
    undef $mode if $from < 6 || $from > 17;
    undef $mode if $to   < 6 || $to   > 17;
    print STDERR "ERROR: parameters out of range\n\n" unless $mode;
} elsif ($mode eq 'dump') {
    ;
} elsif ($mode eq 'stats') {
    ;
} elsif ($mode eq 'settings') {
    ;
} elsif ($mode eq 'sizes') {
    ;
} else {
    undef $mode;
}

undef $mode if @ARGV;

die
    "Usage: memcached-tool <host[:port] | /path/to/socket> [mode]\n
       memcached-tool 10.0.0.5:11211 display    # shows slabs
       memcached-tool 10.0.0.5:11211            # same.  (default is display)
       memcached-tool 10.0.0.5:11211 stats      # shows general stats
       memcached-tool 10.0.0.5:11211 settings   # shows settings stats
       memcached-tool 10.0.0.5:11211 sizes      # shows sizes stats
       memcached-tool 10.0.0.5:11211 dump       # dumps keys and values

WARNING! sizes is a development command.
As of 1.4 it is still the only command which will lock your memcached instance for some time.
If you have many millions of stored items, it can become unresponsive for several minutes.
Run this at your own risk. It is roadmapped to either make this feature optional
or at least speed it up.
" unless $addr && $mode;


my $sock;
if ($addr =~ m:/:) {
    $sock = IO::Socket::UNIX->new(
        Peer => $addr,
    );
}
else {
    $addr .= ':11211' unless $addr =~ /:\d+$/;

    $sock = IO::Socket::INET->new(
        PeerAddr => $addr,
        Proto    => 'tcp',
    );
}
die "Couldn't connect to $addr\n" unless $sock;

if ($mode eq 'dump') {
    my %items;
    my $totalitems;

    print $sock "stats items\r\n";

    while (<$sock>) {
        last if /^END/;
        if (/^STAT items:(\d*):number (\d*)/) {
            $items{$1} = $2;
            $totalitems += $2;
        }
    }
    print STDERR "Dumping memcache contents\n";
    print STDERR "  Number of buckets: " . scalar(keys(%items)) . "\n";
    print STDERR "  Number of items  : $totalitems\n";

    foreach my $bucket (sort(keys(%items))) {
        print STDERR "Dumping bucket $bucket - " . $items{$bucket} . " total items\n";
        print $sock "stats cachedump $bucket $items{$bucket}\r\n";
        my %keyexp;
        while (<$sock>) {
            last if /^END/;
            # return format looks like this
            # ITEM foo [6 b; 1176415152 s]
            if (/^ITEM (\S+) \[.* (\d+) s\]/) {
                $keyexp{$1} = $2;
            }
        }

        foreach my $k (keys(%keyexp)) {
            print $sock "get $k\r\n";
            my $response = <$sock>;
            if ($response =~ /VALUE (\S+) (\d+) (\d+)/) {
                my $flags = $2;
                my $len = $3;
                my $val;
                read $sock, $val, $len;
                print "add $k $flags $keyexp{$k} $len\r\n$val\r\n";
                # get the END
                $_ = <$sock>;
                $_ = <$sock>;
            }
        }
    }
    exit;
}

if ($mode eq 'stats') {
    my %items;

    print $sock "stats\r\n";

    while (<$sock>) {
        last if /^END/;
        chomp;
        if (/^STAT\s+(\S*)\s+(.*)/) {
            $items{$1} = $2;
        }
    }
    printf ("#%-17s %5s %11s\n", $addr, "Field", "Value");
    foreach my $name (sort(keys(%items))) {
        printf ("%24s %12s\n", $name, $items{$name});

    }
    exit;
}

if ($mode eq 'settings') {
    my %items;

    print $sock "stats settings\r\n";

    while (<$sock>) {
        last if /^END/;
        chomp;
        if (/^STAT\s+(\S*)\s+(.*)/) {
            $items{$1} = $2;
        }
    }
    printf ("#%-17s %5s %11s\n", $addr, "Field", "Value");
    foreach my $name (sort(keys(%items))) {
        printf ("%24s %12s\n", $name, $items{$name});
    }
    exit;
}


if ($mode eq 'sizes') {
    my %items;

    print $sock "stats sizes\r\n";

    while (<$sock>) {
        last if /^END/;
        chomp;
        if (/^STAT\s+(\S*)\s+(.*)/) {
            $items{$1} = $2;
        }
    }
    printf ("#%-17s %5s %11s\n", $addr, "Size", "Count");
    foreach my $name (sort(keys(%items))) {
        printf ("%24s %12s\n", $name, $items{$name});
    }
    exit;
}

# display mode:

my %items;  # class -> { number, age, chunk_size, chunks_per_page,
#            total_pages, total_chunks, used_chunks,
#            free_chunks, free_chunks_end }

print $sock "stats items\r\n";
my $max = 0;
while (<$sock>) {
    last if /^END/;
    if (/^STAT items:(\d+):(\w+) (\d+)/) {
        $items{$1}{$2} = $3;
    }
}

print $sock "stats slabs\r\n";
while (<$sock>) {
    last if /^END/;
    if (/^STAT (\d+):(\w+) (\d+)/) {
        $items{$1}{$2} = $3;
        $max = $1;
    }
}

print "  #  Item_Size  Max_age   Pages   Count   Full?  Evicted Evict_Time OOM\n";
foreach my $n (1..$max) {
    my $it = $items{$n};
    next if (0 == $it->{total_pages});
    my $size = $it->{chunk_size} < 1024 ?
        "$it->{chunk_size}B" :
        sprintf("%.1fK", $it->{chunk_size} / 1024.0);
    my $full = $it->{free_chunks_end} == 0 ? "yes" : " no";
    printf("%3d %8s %9ds %7d %7d %7s %8d %8d %4d\n",
           $n, $size, $it->{age}, $it->{total_pages},
           $it->{number}, $full, $it->{evicted},
           $it->{evicted_time}, $it->{outofmemory});
}

