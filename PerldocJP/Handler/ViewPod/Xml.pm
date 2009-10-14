package PerldocJP::Handler::ViewPod::Xml;
use strict;
use Apache::Constants;
use Apache::File;
use IO::String;
use Jcode;
use Pod::XML;

use PerldocJP::Parser::PodXML;

sub handler {
    my($class, $r) = @_;
    my $parser = PerldocJP::Parser::PodXML->new;
    my $handle = IO::String->new(
	$class->slurp_utf8($r->filename),
    );
    $r->send_http_header('text/xml; charset=utf-8');
    $parser->parse_from_filehandle($handle, \*STDOUT);
    return OK;
}

sub slurp_utf8 {
    my($class, $file) = @_;
    my $handle = FileHandle->new($file);
    local $/;
    return Jcode->new(scalar <$handle>, 'euc')->utf8;
}

1;
