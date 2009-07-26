package Web::Scrape::Configure;
use strict;
use warnings;
use base 'WWW::Mechanize';

our $VERSION = '0.01';

sub configure {
    my $self = shift;
    $self->{config} = { @_ };
}

sub process {
    my ($self, $uri) = @_;
    $uri = URI->new($uri) unless ref $uri;

    my $config = $self->_site_config($uri) or return;
    my $control = $config->{control};

    $self->get($uri);
    
    my $result;
    foreach my $key (keys %$config) {
        next if $key eq 'control';
        my ($method, $arg) = %{ $config->{$key} };
        my @values = map $_->string_value, $self->$method($arg);
        my $value = ($key =~ s/\[\]$// ? \@values : $values[0]);
        $result->{$key} = $value;
    }
    $result;
}

sub _host_config {
    my ($self, $uri) = @_;
    $uri = URI->new($uri) unless ref $uri;
    my $host = $uri->host;
    my @parts = split /\./, $host;
    while (@parts) {
        my $config = $self->{config}->{ join '.', @parts };
        return $config if $config;
        shift @parts;
    }
}

sub _site_config {
    my ($self, $uri) = @_;
    $uri = URI->new($uri) unless ref $uri;
    my $config = $self->_host_config($uri) or return;
    foreach (keys %$config) {
        return $config->{$_} if $uri->path =~ qr/$_/;
    }
}

use Encode;
use HTML::Selector::XPath;
use HTML::TreeBuilder::XPath;

sub WWW::Mechanize::selector {
    my ($mech, $selector) = @_;
    $mech->xpath(HTML::Selector::XPath->new($selector)->to_xpath);
}
sub WWW::Mechanize::xpath {
    my ($mech, $xpath) = @_;
 
    my @ct = $mech->response->header('Content-Type');
 
    my $content = $mech->content;
    unless (Encode::is_utf8($content)) {
        if ($ct[0] && $ct[0] =~ /charset=([\w\-]+)/) {
            $content = decode($1, $mech->content);
        } else {
            $content = decode_utf8($mech->content);
        }
    }
 
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);
    $tree->eof;
 
    my @nodes = $tree->findnodes($xpath);
    return wantarray ? @nodes : $nodes[0];
}

1;

__END__

=head1 NAME

Web::Scrape::Configure -

=head1 SYNOPSIS

  use Web::Scrape::Configure;

=head1 DESCRIPTION

Web::Scrape::Configure is

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
