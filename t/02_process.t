use strict;
use warnings;
use utf8;
use Test::More;
use Web::Scrape::Configure;

if ($ENV{TEST_HTTP}) {
    plan tests => 3;
} else {
    plan skip_all => 'TEST_HTTP not set. skip';
}

my $scraper = Web::Scrape::Configure->new;
$scraper->configure(
    '2chan.net' => {
        qr</b/res/\d+\.htm$> => {
            image => { xpath => '//form/a/img/../@href' },
        },
    },

    'pixiv.net' => {
        qr</member_illust\.php\?mode=medium&illust_id=\d+> => {
            control => {
                follow => { xpath => 'id("content2")//a/img/../@href' },
            },
            'tags[]' => { xpath => 'id("tag_area_")//a/text()' },
        },
        qr</member_illust\.php\?mode=big&illust_id=\d+> => {
            image => { xpath => '//img/@src' },
        },
    },

    'f.hatena.ne.jp' => {
        qr</\w+/\d+> => {
            image => { xpath => 'id("foto-body")/img/@src' },
            title => { selector => 'div.fototitle' },
        },
    },
);

{
    my $result = $scraper->process('http://f.hatena.ne.jp/motemen/20090418030322');
    isa_ok $result, 'HASH';
    is     $result->{image}, 'http://img.f.hatena.ne.jp/images/fotolife/m/motemen/20090418/20090418030322.png';
    is     $result->{title}, 'あんちぽ！';
    note explain $result;
}

