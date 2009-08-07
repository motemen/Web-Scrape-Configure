package Web::Scrape::Configure;
use strict;
use warnings;
use base 'WWW::Mechanize';
use URI;

our $VERSION = '0.01';

sub configure {
    my $self = shift;
    $self->{config} = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
}

sub process {
    my ($self, $uri, $result) = @_;
    $uri = URI->new($uri) unless ref $uri;

    my ($config, $host_config) = $self->_site_config($uri) or return;

    if (my $login = $host_config->{'::login'}) {
        $self->login_by_config($login);
    }

    $self->get($uri);

    foreach my $key (keys %$config) {
        next if $key =~ /^\W/;
        my @values = $self->scrape_by_config($config->{$key});
        my $value = ($key =~ s/\[\]$// ? \@values : $values[0]);
        $result->{$key} = $value;
    }

    if (my $follow = $config->{'::follow'}) {
        my ($link) = $self->scrape_by_config($follow);
        my $uri = URI->new_abs($link, $self->base);
        return $self->process($uri, $result);
    }

    $result;
}

sub login_by_config {
    my ($self, $config) = @_;

    $self->invoke_callback(before_login => $config);

    unless ($self->{_session}->{$config->{uri}}) {
        $self->get($config->{uri});
        $self->submit_form(fields => $config->{form});
        $self->{_session}->{$config->{uri}}++ if $self->success;
    }
}

sub scrape_by_config {
    my ($self, $config) = @_;
    my ($method, $arg) = %$config;
    $self->die("method $method not allowed") unless $method =~ /^(?:xpath|selector)$/;
    map {
        my $s = $_->string_value;
        $s =~ s/^\s+//;
        $s =~ s/\s+$//;
        utf8::downgrade($s, 1);
        decode_utf8($s);
    } $self->$method($arg);
}

sub add_callback {
    my ($self, $name, $code) = @_;
    push @{$self->{callbacks}->{$name}}, $code;
}

sub invoke_callback {
    my ($self, $name, @args) = @_;
    foreach (@{$self->{callbacks}->{$name}}) {
        $_->($self, @args);
    }
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
        return ($config->{$_}, $config)  if $uri->path_query =~ qr/^$_/;
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
 
    my $content = $mech->content;
    unless (Encode::is_utf8($content)) {
        my @ct = $mech->response->header('Content-Type');
        if ($ct[0] && $ct[0] =~ /charset=([\w\-]+)/) {
            $content = decode($1, $content);
        } else {
            $content = decode_utf8($content);
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
