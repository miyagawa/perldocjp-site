package PerldocJP::Parser::PodXML;
use strict;
use base qw(Pod::XML);

sub begin_pod {
    my ($parser) = @_;

    $parser->{headlevel} = 0;
    $parser->{seentitle} = 0;
    $parser->{closeitem} = 0;
    $parser->{waitingfortitle} = 0;

    $parser->xml_output(<<EOT);
<?xml version='1.0' encoding='utf-8'?>
<pod xmlns="http://axkit.org/ns/2000/pod2xml">
EOT
}

1;
