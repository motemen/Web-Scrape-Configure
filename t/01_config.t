use strict;
use warnings;
use Test::More tests => 5;
use Web::Scrape::Configure;

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
);

ok my ($config) = $scraper->_site_config('http://img.2chan.net/b/res/65778369.htm'), 'existent site';
ok $config->{image};
ok $config->{image}->{xpath};

ok $scraper->_site_config('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=2236079'), 'subdomain';

ok !$scraper->_site_config('http://nonexistentsite/'), 'nonexistent site';
