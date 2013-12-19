package Device::PiGlow;

use Moose;

use Device::SMBus;

# These are all the register numbers defined by the device
use constant CMD_ENABLE_OUTPUT => 0x00;
use constant CMD_ENABLE_LEDS => 0x13;
use constant CMD_ENABLE_LEDS_1 => 0x13;
use constant CMD_ENABLE_LEDS_2 => 0x14;
use constant CMD_ENABLE_LEDS_3 => 0x15;
use constant CMD_SET_PWM_VALUES => 0x01;
use constant CMD_SET_PWM_VALUE_1 => 0x01;
use constant CMD_SET_PWM_VALUE_2 => 0x02;
use constant CMD_SET_PWM_VALUE_3 => 0x03;
use constant CMD_SET_PWM_VALUE_4 => 0x04;
use constant CMD_SET_PWM_VALUE_5 => 0x05;
use constant CMD_SET_PWM_VALUE_6 => 0x06;
use constant CMD_SET_PWM_VALUE_7 => 0x07;
use constant CMD_SET_PWM_VALUE_8 => 0x08;
use constant CMD_SET_PWM_VALUE_9 => 0x09;
use constant CMD_SET_PWM_VALUE_10 => 0x0A;
use constant CMD_SET_PWM_VALUE_11 => 0x0B;
use constant CMD_SET_PWM_VALUE_12 => 0x0C;
use constant CMD_SET_PWM_VALUE_13 => 0x0D;
use constant CMD_SET_PWM_VALUE_14 => 0x0E;
use constant CMD_SET_PWM_VALUE_15 => 0x0F;
use constant CMD_SET_PWM_VALUE_16 => 0x10;
use constant CMD_SET_PWM_VALUE_17 => 0x11;
use constant CMD_SET_PWM_VALUE_18 => 0x12;
use constant CMD_UPDATE => 0x16;
use constant CMD_RESET => 0x17;
=head1 NAME

Device::PiGlow - Interface to the PiGlow board using i2c

=head1 SYNOPSIS

    use Device::PiGlow;

    my $pg = Device::PiGlow->new();

    my $values = [0x01,0x02,0x04,0x08,0x10,0x18,0x20,0x30,0x40,0x50,0x60,0x70,0x80,0x90,0xA0,0xC0,0xE0,0xFF];

    $pg->enable_output();
    $pg->enable_all_leds();

    $pg->write_all_leds($values);
    sleep 10;
    $pg->reset();



=head1 DESCRIPTION

The PiGlow from Pimoroni (http://shop.pimoroni.com/products/piglow) is 
a small board that plugs in to the Raspberry PI's GPIO header 
with 18 LEDs on that can be addressed individually via i2c.

This module uses L<Device::SMBus> to abstract the interface to the device
so that it can be controlled from a Perl programme.

It is assumed that you have installed the OS packages required to make
i2c work and have configured and tested the i2c appropriately.  The only
difference that seems to affect the PiGlow device is that it only seems
to be reported by C<i2cdetect> if you use the "quick write" probe flag:

   sudo i2cdetect -y -q 1

(assuming you have a Rev B. Pi - if not you should supply 0 instead of 1.) 
I have no way of knowing the compatibility of the "quick write" with any
other devices you may have plugged in to the Pi, so I wouldn't recommend
doing this with any other devices unless you know that they won't be adversely
affected by "quick write".  The PiGlow has a fixed address anyway so the
information isn't that useful.

=head2 METHODS

=over 4

=item new

The constructor.  This takes two optional attributes which are passed on
directly to the L<Device::SMBus> constructor:

=over 4

=item I2CBusDevicePath

This sets the device path, it defaults to /dev/i2c-1 (assuming a newer
Raspberry PI,) You will want to set this if you are using an older PI or
an OS that creates a different device.

=cut

has I2CBusDevicePath =>	(
			   is  => 'rw',
                           isa => 'Str',
                           default => '/dev/i2c-1',
			);

=item I2CDeviceAddress

This sets the i2c device address,  this defaults to 0x54.  Unless you have
somehow altered the address you shouldn't need to change this.

=cut

has I2CDeviceAddress => (
			   is  => 'rw',
                           isa => 'Num',
                           default => 0x54,
			);

=back

=item device_smbus

This is the L<Device::SMBus> object we will be using to interact with i2c.
It will be initialised with the attributes described above.  You may want
this if you need to do something to the PiGlow I haven't thought of.

=cut

has device_smbus  => (
                        is => 'ro',
                        isa => 'Device::SMBus',
                        lazy => 1,
                        builder => '_get_device_smbus',
                        handles => {
                                     i2c_file => 'I2CBusFilenumber',
                                     _write_byte => 'writeByteData',
                                   },
		     );

sub _get_device_smbus
{
   my ( $self ) = @_;

   my $smbus = Device::SMBus->new(
				    I2CBusDevicePath => $self->I2CBusDevicePath,
                                    I2CDeviceAddress => $self->I2CDeviceAddress
                                 );
   return $smbus;
}

=item update

This updates the values set to the LED registers to the LEDs and changes
the display.

=cut

sub update
{
   my ( $self ) = @_;
   
   return $self->_write_byte(CMD_UPDATE, 0xFF);
}

=item enable_output

This sets the state of the device to active.  

=cut

sub enable_output
{
   my ( $self ) = @_;
   return $self->_write_byte(CMD_ENABLE_OUTPUT, 0x01);
}

has '_led_bank_enable_registers' => (
                                       is  => 'ro',
                                       isa => 'ArrayRef',
                                       lazy => 1,
                                       auto_deref => 1,
                                       default  => sub {
                                          return [
                                                   CMD_ENABLE_LEDS_1,
                                                   CMD_ENABLE_LEDS_2,
                                                   CMD_ENABLE_LEDS_3,
                                                 ];
                                       },
                                    );

=item enable_all_leds

This turns on all three banks of LEDs.

=cut

sub enable_all_leds
{
   my ( $self ) = @_;
   return $self->write_block_data(CMD_ENABLE_LEDS, [0xFF, 0xFF, 0xFF]);
}

=item write_all_leds

This writes the PWM values supplied as an Array Reference and immediately
calls C<update> to apply the values to the LEDs.

The array must be exactly 18 elements long.

=cut

sub write_all_leds
{
   my ( $self, $values ) = @_;

   if ( @{$values} == 18 )
   {
       $self->write_block_data(CMD_SET_PWM_VALUES, $values);
       $self->update();
   }
}

=item reset

Resets the device to its default state.  That is to say all LEDs off.

It will be necessary to re-enable the groups of LEDs again after calling
this.

=cut

sub reset
{
   my ( $self) = @_;
   return $self->_write_byte(CMD_RESET, 0xFF);
}


=item write_block_data

$self->writeBlockData($register_address, $values)

Writes a maximum of 32 bytes in a single block to the i2c device.
The supplied $values should be an array ref containing the bytes to
be written.

The register address supplied should be the first of a consecutive set
of addresses equal to the number of values supplied.  Supplying an 
address that doesn't fit that description is unlikely to work well and
will almost certainly result in undefined behaviour in the device.

=cut

# Device::SMBus seems to have the XS part of this but not the perl.
# I'll use this one if it doesn't

sub write_block_data 
{
    my ( $self, $register_address, $values ) = @_;
    
    my $value  = pack "C*", @{$values};

    my $retval = Device::SMBus::_writeI2CBlockData($self->i2c_file,$register_address, $value);
    return $retval;
}

=back

=head2 CONSTANTS

These define the command registers used by the SN3218 IC used in PiGlow

=over 4

=cut


=item CMD_ENABLE_OUTPUT

If set to 1 the device will be ready for operation, if 0 then it will
be "shutdown"

=cut


=item CMD_ENABLE_LEDS

This should be used for a block write to enable (or disable) all three
groups of LEDs in one go.  The values are a 6 bit mask, one bit for each
LED in the group.

=cut


=item CMD_ENABLE_LEDS_1

A bit mask to enable the LEDs in group 1

=cut


=item CMD_ENABLE_LEDS_2

A bit mask to enable the LEDs in group 2

=cut


=item CMD_ENABLE_LEDS_3

A bit mask to enable the LEDs in group three.

=cut


=item CMD_SET_PWM_VALUES

This should be used in a block write to set the PWM values of all 18 LEDs
at once.  The values should be 8 bit values.

There are also CMD_SET_PWN_VALUE_[1 .. 18] to set the LEDs individually.

=cut



=item CMD_UPDATE

The written LED values are stored in a temporary register and are not
applied to the LEDs until an 8 bit value is written to this register/

=cut


=item CMD_RESET

Writing a value to this register will restore the device to its power
on default (i.e. all LEDs blank)

=back

=head1 AUTHOR

Jonathan Stowe <jns@gellyfish.co.uk>

=head1 COPYRIGHT

This is licensed under the same terms as Perl itself.  Please see the
LICENSE file in the distribution files for the full details.

=head1  SEE ALSO

L<Device::SMBus>

=cut

1;
