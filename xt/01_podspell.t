use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
set_spell_cmd("aspell -l en list");
all_pod_files_spelling_ok('lib');
__DATA__
Masahiro Nagano
kazeburo {at} gmail.com
Log::Minimal
Shimada
Yuji
xaicron
debugf
debugff
sugi
yoshihiro
sugyan
BG
FG

