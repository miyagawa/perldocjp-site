package PerldocJP::Handler::ViewPod;
use strict;
use Apache::Constants;
use Apache::Request;
use Pod::POM;
use UNIVERSAL::require;

my %Supported = map { $_ => $_ } qw(html pod pdf txt xml);

sub handler($$) {
    my $class = shift;
    my $r = Apache::Request->new(shift);
    my($implementor, $filename) = $class->implementor($r->filename);
    $implementor->require;
    $r->filename($filename);
    my $rc = eval { $implementor->handler($r) };
    warn $@ if $@;
    return $@ ? NOT_FOUND : $rc;
}

sub implementor {
    my($class, $filename) = @_;
    $filename =~ s/(?<=\.pod)\.(.*)$//;
    my $as = $Supported{$1} || 'html';		# default
    return (__PACKAGE__ . "::" . ucfirst($as), $filename);
}

1;
