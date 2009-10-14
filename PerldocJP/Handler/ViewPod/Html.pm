package PerldocJP::Handler::ViewPod::Html;
use strict;
use Apache::Constants;
use Pod::POM;

my $Parser = Pod::POM->new;

sub handler {
    my($class, $r) = @_;
    my $pom = $Parser->parse_file($r->filename);
    my $encoding = check_encoding($r->filename) || "euc-jp";
    $r->send_http_header("text/html; charset=$encoding");
    $r->print(PerldocJP::View::HTML->print($pom));
    return OK;
}

sub check_encoding {
    open my $fh, "<", shift or die $!;
    while (<$fh>) {
        /^=encoding (\S*)/ and return $1;
    }
    return;
}

package PerldocJP::View::HTML;
use base qw(Pod::POM::View::HTML);
use Apache;

sub view_pod {
    my($self, $pod) = @_;
    my $title = $pod->head1->[0]->text;
    my $present = $pod->content->present($self);
    (my $uri = Apache->request->uri) =~ s/(?<=\.pod)\..*$//;
    return <<HTML;
<html>
<head>
<link rel="stylesheet" href="/index.css">
<title>$title</title>
</head>
<body>
<p>
<a href="$uri.pod">[pod]</a>
<a href="$uri.xml">[xml]</a><!--
<a href="$uri.pdf">[pdf]</a>
<a href="$uri.text">[text]</a> -->
</p>
$present
</body>
</html>
HTML
    ;

}

1;
