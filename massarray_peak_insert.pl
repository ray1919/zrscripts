#!/usr/bin/env perl
# Date: 2014-01-09
# Author: Zhao
# Purpose: 检查是否能在massarray的assay中再插入一些assay

use 5.010;
use Data::Dump qw/dump/;
use Data::Table;

my $MPS = 30;
my $MMR = 9000; # Max Mass Range

my @assay; # 需要插入的峰大小
my %well; # 记录已有的峰大小

my $assay_file = shift; # Assay Design/xxx.xls
my $seq_file = shift;   # Assat Design/xxx.txt

my $at = Data::Table::fromTSV($assay_file);
my $st = Data::Table::fromTSV($seq_file);

$at->addCol(undef,'SNP_SEQ');
my %snp_seq;
map {$snp_seq{$st->elm($_,'SNP_ID')} = $st->elm($_,'Sequence')}
    0 .. $st->lastRow;
map {$at->setElm($_,'SNP_SEQ',$snp_seq{$at->elm($_,'SNP_ID')})}
    0 .. $at->lastRow;

my $ata = $at->match_pattern_hash('$_{"WELL"} ne "W3"');
my $atb = $at->match_pattern_hash('$_{"WELL"} eq "W3"');

foreach my $r ( 0 .. $ata->lastRow) {
  push @{$well{$ata->elm($r,'WELL')}}, $ata->elm($r,'UEP_MASS');
  push @{$well{$ata->elm($r,'WELL')}}, $ata->elm($r,'EXT1_MASS');
  push @{$well{$ata->elm($r,'WELL')}}, $ata->elm($r,'EXT2_MASS');
}

my $abl = 0;
while ($atb->nofRow > 0) {
  foreach my $w (keys %well) {
    foreach my $r ( reverse 0 .. $atb->lastRow) {
      my $assay = [$atb->elm($r,'UEP_MASS'),
                  $atb->elm($r,'EXT1_MASS'),
                  $atb->elm($r,'EXT2_MASS')];
      if (is_peak_seperation($well{$w},$assay,$MPS)) {
        say "$w incorparate with ", $atb->elm($r,'SNP_ID')," +$abl";

        push @{$well{$ata->elm($r,'WELL')}}, $atb->elm($r,'UEP_MASS');
        push @{$well{$ata->elm($r,'WELL')}}, $atb->elm($r,'EXT1_MASS');
        push @{$well{$ata->elm($r,'WELL')}}, $atb->elm($r,'EXT2_MASS');
        $atb->setElm($r,'WELL',$w);
        my $row = $atb->delRow($r);
        $ata->addRow($row);
      }
    }
  }
  $atb = add1bp($atb);
  $abl += 1;
}

outputTSV($ata,'new_assay.txt');

sub add1bp {
  my $t = shift;
  my %atgcmass = ('A',271.2,'T',327.1,'G',287.2,'C',247.2);
  foreach my $r ( reverse 0 .. $t->lastRow) {
    $uep_seq = $t->elm($r,'UEP_SEQ');
    $snp_seq = $t->elm($r,'SNP_SEQ');
    $snp_seq =~ s/^[a-z]+//;
    $snp_seq =~ s/[a-z]+$//;
    if ($t->elm($r,'UEP_DIR') eq 'F') {
      $p1 = index($snp_seq,'[');
      if ($p1 == length($uep_seq) ) {
        say $atb->elm($r,'SNP_ID')," exceed max product range.";
        $t->delRow($r);
      }
      $eb = substr($snp_seq,$p1-length($uep_seq)-1,1); # 延伸引物前一位的碱基
    }
    else {
      $p1 = index($snp_seq,']');
      if (length($snp_seq) - $p1 + 1 == length($uep_seq) ) {
        say $atb->elm($r,'SNP_ID')," exceed max product range.";
        $t->delRow($r);
      }
      $eb = substr($snp_seq,$p1+length($uep_seq)+1,1); # 延伸引物前一位的碱基
    }
    $eb = uc($eb);
    $eb =~ tr/ATGC/CGTA/; # 延长错配的碱基
    $uep_seq = $eb . $uep_seq;
    $t->setElm($r,'UEP_SEQ',$uep_seq);
    $t->setElm($r,'EXT1_SEQ',$eb . $t->elm($r,'EXT1_SEQ'));
    $t->setElm($r,'EXT2_SEQ',$eb . $t->elm($r,'EXT2_SEQ'));
    my $e1_mass = $t->elm($r,'EXT1_MASS') + $atgcmass{$eb};
    my $e2_mass = $t->elm($r,'EXT2_MASS') + $atgcmass{$eb};
    $t->setElm($r,'UEP_MASS',$t->elm($r,'UEP_MASS') + $atgcmass{$eb});
    $t->setElm($r,'EXT1_MASS',$e1_mass);
    $t->setElm($r,'EXT2_MASS',$e2_mass);
    if ($e1_mass > $MMR or $e2_mass > $MMR ) {
      say $atb->elm($r,'SNP_ID')," exceed max mass range.";
      $t->delRow($r);
    }
  }
  return $t;
}

sub is_peak_seperation {
  my ($a, $b, $c) = @_;
  foreach my $bp (@$b) {
    foreach my $ap ( @$a ) {
      if ( abs($ap - $bp) < $c) {
        return 0;
      }
    }
  }
  return 1;
}

sub outputTSV {
    my ( $table, $file, $header ) = @_;
    say "outputTSV() parameter ERROR!" unless defined $table;
    $header = defined $header ? $header : 1;
    if ( defined $file ) {
        $table->tsv( $header, { OS => 0, file => $file } );
    }
    else {
        print $table->tsv( $header, { OS => 0, file => undef } );
    }
    return $table->tsv( $header, { OS => 0, file => undef } );
}

