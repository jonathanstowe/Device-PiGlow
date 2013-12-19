use 5.014004;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Device::PiGlow',
    VERSION_FROM      => 'lib/Device/PiGlow.pm', 
    PREREQ_PM         => {
                           'Moose' => '2.0402',
                           'Device::SMBus' => '0.35',
                         },
    ABSTRACT_FROM  => 'lib/Device/PiGlow.pm', 
    AUTHOR         => 'Jonathan Stowe <jns@gellyfish.co.uk>'
);

