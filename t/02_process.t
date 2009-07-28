use strict;
use warnings;
use utf8;
use Test::More;
use Web::Scrape::Configure;
use YAML;
use UNIVERSAL::require;

if ($ENV{TEST_HTTP}) {
    plan tests => 14;
} else {
    plan skip_all => 'TEST_HTTP not set. skip';
}

my $scraper = Web::Scrape::Configure->new;
$scraper->configure(YAML::LoadFile('t/files/config.yaml'));

{
    my $result = $scraper->process('http://f.hatena.ne.jp/motemen/20090418030322');
    isa_ok $result, 'HASH';
    is     $result->{image}, 'http://img.f.hatena.ne.jp/images/fotolife/m/motemen/20090418/20090418030322.png';
    is     $result->{title}, 'あんちぽ！';
    note explain $result;
}

SKIP: {
    skip 'Could not load Config::Pit', 1 unless Config::Pit->use;

    $scraper->add_callback(
        before_login => sub {
            my ($scraper, $config) = @_;
            my $host = URI->new($config->{uri})->host;
            my $pit_config = pit_get($host);
            $config->{form}->{$_} ||= $pit_config->{$_} foreach keys %{$config->{form}};
        }
    );

    my $result = $scraper->process('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=2236079');
    isa_ok $result, 'HASH';
    isa_ok $result->{tags}, 'ARRAY';
    note explain $result;
}

{
    my $result = $scraper->process('http://twitpic.com/54hmy/full');
    isa_ok $result, 'HASH';
    like   $result->{image}, qr<^http://s3\.amazonaws\.com/twitpic/photos/full/8607562\.jpg\?AWSAccessKeyId=0ZRYP5X5F6FSMBCCSE82&Expires=\d+&Signature=.+$>;
    note explain $result;
}

{
    my $result = $scraper->process('http://twitpic.com/54hmy');
    isa_ok $result, 'HASH';
    like   $result->{image}, qr<^http://s3\.amazonaws\.com/twitpic/photos/full/8607562\.jpg\?AWSAccessKeyId=0ZRYP5X5F6FSMBCCSE82&Expires=\d+&Signature=.+$>;
    is     $result->{title}, ' にあかわ！ '; # TODO trim
    note explain $result;
}

{
    my $result = $scraper->process('http://danbooru.donmai.us/post/show/488994/aqua_eyes-aqua_hair-bound_hands-breasts-cleavage-e');
    isa_ok $result, 'HASH';
    is     $result->{image}, 'http://danbooru.donmai.us/data/a7d475cbc08a7b35709958d626b62a98.jpg';
    isa_ok $result->{tags},  'ARRAY';
    ok     grep /^hatsune miku$/, @{$result->{tags}};
    note explain $result;
}
