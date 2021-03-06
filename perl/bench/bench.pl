use Benchmark ':all';

use BEEF;
use Cache::Memcached::Fast;
my $memd = new Cache::Memcached::Fast({servers => [ { address => 'localhost:11211', weight => 2.5 } ]});
my $beef = BEEF->new(0xBEEF);
my %hash;

for my $key(qw(a abcd aaaaaaaabbbbbbb aaaaaaaaaaaaaaaabbbbbbbbbbbbbbb)) {
    for my $i(qw(1000 10_000 1_000_000 )) {
        my $value = "a" x int($i);
        my $r = timethese($count, {
            "$i $key - memcached fast store" => sub { $memd->set($key,$value)},
            "$i $key - 0xbeef store" => sub { $beef->store($key,$value)},
            "$i $key - native hash store" => sub { $hash{$key} = $value },
        });
        cmpthese($r); 

        $beef->copy_locally();
        $r = timethese($count, {
            "$i $key - memcached fast get" => sub { my $x = $memd->get($key)},
            "$i $key - 0xbeef get" => sub { $x = $beef->find($key)},
            "$i $key - 0xbeef get locally" => sub { $x = $beef->find_locally($key)},
            "$i $key - native hash get" => sub { my $x = $hash{$key}},
        });
        cmpthese($r); 
        my $missing = $key . "x";
        $r = timethese($count, {
            "$i $key - memcached fast miss" => sub { my $x = $memd->get($missing)},
            "$i $key - 0xbeef miss" => sub { $x = $beef->find($missing)},
            "$i $key - 0xbeef get locally miss" => sub { $x = $beef->find_locally($missing)},
            "$i $key - native hash miss" => sub { my $x = $hash{$missing}},
        });
        cmpthese($r); 
        print "*"x80 . "\n";
    }
}
