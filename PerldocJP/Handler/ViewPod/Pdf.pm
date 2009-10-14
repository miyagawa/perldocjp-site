package PerldocJP::Handler::ViewPod::Pdf;
use strict;
use Apache::Constants;
use Apache::File;
use IO::String;
use Jcode;

sub handler {
    my($class, $r) = @_;
    my($sjis_pod, $sjis_fh) = Apache::File->tmpfile;
    my($outpdf) = Apache::File->tmpfile;
    _euc2sjis($r->filename, $sjis_fh);
    my $podpdf = PerldocJP::PodPdfParser->new;
    $podpdf->parse_from_file($sjis_pod, $outpdf);
    $podpdf->print;
    $r->content_type('application/pdf');
    $r->filename($outpdf);
    return DECLINED;
}

sub _euc2sjis {
    my($file, $outfh) = @_;
    local $/;
    my $handle = Apache::File->new($file);
    my $cont = <$handle>;
    print $outfh (Jcode->new($cont)->sjis);
}

# below is a cut-n-paste of pod2pdf.pl in PDFJ-0.3.zip

# pod2pdf.pl - PDFJ sample script
# 2002 <nakajima@netstock.co.jp>

# !!! CAUTION !!!
# This script contains Japanese characters. Please save this file 
# with the Japanese character code you use for the target text, and
# choice same code at following 'use PDFJ ...'.

#--------------------------------------------------------------------
#package PodPdf;
package PerldocJP::PodPdfParser;

# !!! Choice 'SJIS or 'EUC' !!!
use PDFJ 'SJIS';
#use PDFJ 'EUC';

use Pod::Parser;
use strict;
use vars qw(@ISA);

@ISA = qw(Pod::Parser);

sub initialize {
	my($self) = @_;
	$self->SUPER::initialize();
	my $doc = PDFJ::Doc->new(1.2, 612, 792);
	my $width = 612 - 72 - 72;
	my $height = 792 - 72 - 72;
	$self->{bodywidth} = $width;
	$self->{bodyheight} = $height;
	my $f_normal = $doc->new_font('Ryumin-Light', '90ms-RKSJ-H', 'Times-Roman');
	my $f_fix = $doc->new_font('Ryumin-Light', '90ms-RKSJ-H');
	my $f_bold = $doc->new_font('GothicBBB-Medium', '90ms-RKSJ-H', 'Helvetica');
	$self->{pdfdoc} = $doc;
	$self->{font} = {
		normal => $f_normal,
		fix => $f_fix,
		bold => $f_bold,
	};
	$self->{tstyle} = {
		head1 => TStyle(font => $f_bold, fontsize => 14),
		head2 => TStyle(font => $f_bold, fontsize => 12),
		defitem => TStyle(font => $f_bold, fontsize => 10),
		normal => TStyle(font => $f_normal, fontsize => 10),
		fix => TStyle(font => $f_fix, fontsize => 10),
		footer => TStyle(font => $f_bold, fontsize => 9),
	};
	$self->{pstyle} = {
		head1 => PStyle(size => $width, linefeed => 14, align => 'b', preskip => 30, postskip => 15, nobreak => 1, postnobreak => 1),
		head2 => PStyle(size => $width, linefeed => 12, align => 'b', preskip => 20, postskip => 10, nobreak => 1, postnobreak => 1),
		defitem => PStyle(size => $width, linefeed => 10, align => 'b', preskip => 10, postskip => 5, nobreak => 1, postnobreak => 1),
		normal => PStyle(size => $width, linefeed => 15, align => 'w', nobreak => 0, preskip => 5, postskip => 5),
		footer => PStyle(size => $width, linefeed => 10, align => 'm'),
	};
	$self->{listskip} = 5;
	$self->{head2mark} = "\x81\xa1";
	$self->{bullmark} = "\x81\x45";
}

sub pdfpara {
	my($self, $text, $stylename, $outlinelevel, $outlinetitle, $line) = @_;
	my $tstyle = $self->{tstyle}{$stylename} or 
		die "unknown style name $stylename\n";
	my $pstyle = $self->{pstyle}{$stylename} or 
		die "unknown style name $stylename\n";
	my @texts;
	push @texts, Shape->line(0, 0, $self->{bodywidth}, 0) if $line;
	if( defined $outlinelevel ) {
		$outlinetitle ||= $text;
		push @texts, Outline($outlinetitle, $outlinelevel), $text;
	} else {
		push @texts, $text;
	}
	Paragraph(Text([@texts], $tstyle), $pstyle);
}

sub add_pdfpara {
	my($self, $pdfpara) = @_;
	push @{$self->{pdfparas}}, $pdfpara;
}

sub status {
	my($self, $status) = @_;
	$self->{status} = $status if defined $status;
	$self->{status};
}

sub indent {
	my($self, $indent) = @_;
	$self->{indent} = $indent if defined $indent;
	$self->{indent};
}

sub itemnum {
	my($self, $itemnum) = @_;
	$self->{itemnum} = $itemnum if defined $itemnum;
	$self->{itemnum};
}

sub print {
	my($self) = @_;
	$self->{pdfdoc}->print($self->output_file);
}

sub end_pod {
	my($self) = @_;
	my $block = Block('V', $self->{pdfparas}, BStyle());
	for my $part( $block->break($self->{bodyheight}) ) {
		my $page = $self->{pdfdoc}->new_page;
		$part->show($page, 72, 72 + $self->{bodyheight});
		my $footer = $self->pdfpara($page->pagenum, 'footer');
		$footer->show($page, 72, 36);
	}
}

sub command {
	my($self, $command, $text, $linenum, $para) = @_;
	my $ptext = $text;
	$ptext =~ s/\n+$//;
	if( $command eq 'head1' ) {
		$self->status('normal');
		$self->add_pdfpara($self->pdfpara($ptext, 'head1', 0, $ptext, 1));
	} elsif( $command eq 'head2' ) {
		$self->status('normal');
		$self->add_pdfpara($self->pdfpara($self->{head2mark}.$ptext, 'head2', 
			1, $ptext));
	} elsif( $command eq 'over' ) {
		my($indent) = $ptext =~ /(\d+)/;
		$self->status('list');
		$self->indent($indent);
		$self->add_pdfpara($self->{listskip});
	} elsif( $command eq 'back' ) {
		$self->status('normal');
		$self->indent(0);
		$self->add_pdfpara($self->{listskip});
	} elsif( $command eq 'item' ) {
		if( $ptext eq '*' ) {
			$self->status('bullitem');
		} elsif( $ptext =~ /^(\d+)$/ ) {
			$self->status('numitem');
			$self->itemnum($1);
		} else {
			$self->add_pdfpara($self->pdfpara($ptext, 'defitem'));
			$self->status('normal');
		}
	}
}

sub verbatim {
	my($self, $text, $linenum, $para) = @_;
	$text =~ s/\n+$//s;
	my @texts;
	for my $line(split(/\n/, $text)) {
		push @texts, Text($line, $self->{tstyle}{fix}), NewLine;
	}
	my $indent = $self->indent;
	my $pstyle = $self->{pstyle}{normal}->
		clone(beginindent => $indent, align => 'b');
	$self->add_pdfpara(Paragraph(Text([@texts], $self->{tstyle}{normal}), $pstyle));
}

sub textblock {
	my($self, $text, $linenum, $para) = @_;
	$text = $self->interpolate($text, $linenum);
	$text =~ s/\n+$//;
	$text =~ s/\n/ /g;
	my $indent = $self->indent;
	my $pstyle;
	if( $self->status eq 'bullitem' ) {
		$pstyle = $self->{pstyle}{normal}->clone(
			labeltext => Text($self->{bullmark}, $self->{tstyle}{normal}), 
			labelsize => $indent * 3);
		$self->status('normal');
	} elsif( $self->status eq 'numitem' ) {
		$pstyle = $self->{pstyle}{normal}->clone(
			labeltext => Text($self->{itemnum}, $self->{tstyle}{normal}), 
			labelsize => $indent * 3);
		$self->status('normal');
	} else {
		$pstyle = $self->{pstyle}{normal}->clone(beginindent => $indent * 3);
	}
	$self->add_pdfpara(Paragraph(Text($text, $self->{tstyle}{normal}), $pstyle));
}

sub interior_sequence {
	my($self, $command, $text, $seq) = @_;
	$text;
}

1;
