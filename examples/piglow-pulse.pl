#!perl

use strict;
use warnings;

use Device::PiGlow;

my $pg = Device::PiGlow->new();

my @rings = (0 .. 5);

my @values = ( 0 .. 255);

$pg->enable_output();
$pg->enable_all_leds();

$SIG{INT} = sub { 
   print "Reset\n";
   $pg->reset();
   exit;
};

while (1 )
{
    foreach my $ring ( @rings )
    {
       my $value = shift @values;
       print "Setting ring $ring to $value\n";
      $pg->set_ring($ring, $value);
      push @values, $value;
    }
    $pg->update();
    sleep 1;
}

