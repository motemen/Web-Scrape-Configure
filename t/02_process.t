use strict;
use warnings;
use utf8;
use Test::More;
use Web::Scrape::Configure;

if ($ENV{TEST_HTTP}) {
    plan tests => 9;
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
        control => {
            login => {
                uri => 'http://www.pixiv.net/',
                form => {
                    pixiv_id => $ENV{PIXIV_ID},
                    pass     => $ENV{PIXIV_PASSWORD},
                },
            }
        },
        qr</member_illust\.php\?mode=medium&illust_id=\d+> => {
            control => {
                follow => { xpath => 'id("content2")//a/img/../@href' },
            },
            'tags[]' => { xpath => 'id("tags")/a/text()' },
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

    'twitpic.com' => {
        qr</\w+$> => {
            control => {
                follow => { xpath => 'id("photo-controls")/a[@href!="#"]/@href' },
            },
            title => { selector => '#view-photo-caption' },
        },
        qr</\w+/full$> => {
            image => { xpath => 'id("pic")/img/@src' },
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

SKIP: {
    skip 'PIXIV_ID, PIXIV_PASSWORD not set', 1 unless $ENV{PIXIV_ID} && $ENV{PIXIV_PASSWORD};
    my $result = $scraper->process('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=2236079');
    isa_ok $result, 'HASH';
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
