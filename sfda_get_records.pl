#!/usr/bin/env perl
# Author: Zhao
# Purpose: 从药监局网站获取国产器械的全部数据
# Date: 2012年9月28日

use LWP::Simple;
use 5.010;
use utf8;
use Smart::Comments;

open(SUC, '>gcqx.txt');
open(ERR, '>error.txt');
binmode(SUC, ':encoding(utf8)');

$startid = shift || 1;
$totalid = shift || 60665;

say "start by $startid, get $totalid records";
say "Press ENTER to continue, press Ctrl-C to exit";
<STDIN>;

$id = $startid;
$cnt = 0;
# foreach my $id ( $startid .. $totalid) { ### fetching [===[%]                            ] done
foreach my $id ( 29878,59294 ) { ### fetching [===[%]                            ] done
  $url = "http://app1.sfda.gov.cn/datasearch/face3/content.jsp?tableId=26&tableName=TABLE26&Id=$id";
  $content = get($url);
  if (defined $content) {
    print SUC $id;
    # say "$id\t$cnt";
    undef($td);
    while ($content =~ /83%>(.*?)<\/td>/g) {
      $td = $1;
      print SUC "\t$td";
      # print "\t$td";
    }
    if (defined $td) {
      $cnt++;
    }
    say SUC '';
    # say '';
  }
  else {
    $cnt++;
    say ERR $id;
    # say "\033[01;33m$id\033[00m";
  }
  # $id++;
}
say $cnt;
