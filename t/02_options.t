use strict;
use Test::More tests => 2;

use Cache::KyotoTycoon::Serialize (
    -serializer   => sub{ unpack('H*', shift); },
    -deserializer => sub{ pack('H*', shift); },
);

my $raw = 'foo';
my $serialized   = Cache::KyotoTycoon::Serialize::_serialize($raw);
my $deserialized = Cache::KyotoTycoon::Serialize::_deserialize($serialized);

is($serialized, unpack('H*', $raw));
is($deserialized, $raw);
