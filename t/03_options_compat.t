use strict;
use Test::More tests => 2;

use Cache::KyotoTycoon;
use Cache::KyotoTycoon::Serialize (
    -compat,
    -serializer   => sub{ unpack('H*', $_[1]); },
    -deserializer => sub{ pack('H*',   $_[1]); },
);

my $obj = Cache::KyotoTycoon->new;
my $raw = 'foo';
my $serialized   = $obj->_serialize($raw);
my $deserialized = $obj->_deserialize($serialized);

is($serialized, unpack('H*', $raw));
is($deserialized, $raw);
