use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
#$ENV{LANG} = 'C';
#add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');
__DATA__
Kenta Sato
kenta.sato.1990@gmail.com
Cache::KyotoTycoon::Serialize
