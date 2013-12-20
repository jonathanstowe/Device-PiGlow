#!perl

use strict;
use warnings;

use Device::PiGlow;

my $pg = Device::PiGlow->new();

my @rings = (0 .. 5);

$pg->enable_output();
$pg->enable_all_leds();

$SIG{INT} = sub { 
   print "Reset\n";
   $pg->reset();
   exit;
};

while (1 )
{
    print "Writing ring " . $rings[0] . "\n";
    $pg->set_ring($rings[0], 0xFE);
    foreach my $clear_rings ( 1 .. 5 )
    {
      print "clearing ring " . $rings[$clear_rings] . "\n";
      $pg->set_ring($rings[$clear_rings], 0x00);
    }
    print "updating \n";
    $pg->update();
    my $first = shift @rings;
    push @rings, $first;
    sleep 1;
}

