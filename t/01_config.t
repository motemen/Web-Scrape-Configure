use strict;
use warnings;
use Test::More tests => 5;
use Web::Scrape::Configure;
use YAML;

my $scraper = Web::Scrape::Configure->new;
$scraper->configure(YAML::LoadFile('t/files/config.yaml'));

ok my ($config) = $scraper->_site_config('http://img.2chan.net/b/res/65778369.htm'), 'existent site';
ok $config->{image};
ok $config->{image}->{xpath};

ok $scraper->_site_config('http://www.pixiv.net/member_illust.php?mode=medium&illust_id=2236079'), 'subdomain';

ok !$scraper->_site_config('http://nonexistentsite/'), 'nonexistent site';
