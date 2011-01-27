use strict;
use Cache::KyotoTycoon;
use Cache::KyotoTycoon::Serialize qw(-compat);

use Test::More tests => 1;

is(ref(new Cache::KyotoTycoon), ref(new Cache::KyotoTycoon::Serialize));
