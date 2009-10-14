package PerldocJP::Handler::ViewPod::Txt;
use strict;
use Apache::Constants;
use Apache::File;
use Jcode;
use Pod::POM;
use Pod::POM::View::Text;

my $Parser = Pod::POM->new;

sub handler {
    my($class, $r) = @_;
    my $pom = $Parser->parse_text($class->slurp_utf8($r->filename));
    $r->send_http_header('text/plain; charset=utf-8');
    $r->print(Pod::POM::View::Text->print($pom));
    return OK;
}

sub slurp_utf8 {
    my($class, $filename) = @_;
    my $handle = Apache::File->new($filename);
    local $/;
    return return Jcode->new(scalar <$handle>, 'euc')->utf8;
}


1;
