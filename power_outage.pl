#!/usr/bin/env perl
# Date: 2013-11-13
# Author: zhao
# Purpose: 查询江苏电力网，将科勒线的停电信息发送邮件

use 5.012;
use Data::Dump qw/dump/;
use POSIX qw(strftime);
use LWP::Simple;
use utf8;
use Encode;

my $datetd = strftime "%Y-%m-%d", localtime;
my $date7l = strftime "%Y-%m-%d", localtime(time() + 3600*24*6);
my $url = "http://www.js95598.com/95598/powercolumn/getSRegionOutage.action?sRegionOutage.startTime=$datetd&sRegionOutage.stopDate=$date7l&sRegionOutage.areaType=city&sRegionOutage.poweroffArea=320400&sRegionOutage.cityName=%E5%B8%B8%E5%B7%9E%E5%B8%82&sRegionOutage.facilityArea=&sRegionOutage.scope=%E7%A7%91%E5%8B%92";

my $content = get($url);

if ($content =~ /(<table id="table_list".*<\/table>)/ms) {
  open my $fh, '>', '/home/zhaorui/tmp/outage.html' or die $!;
  my $html = "<html>$1</html>";
  if ( decode_utf8($html) !~ /没有查到任何停电信息/ ) {
    say $fh $html;
    system("cat /home/zhaorui/tmp/outage.html | sendemail -u 'Power outage - CT Bio.' -f ctbioscience\@163.com -s smtp.163.com -t zzqr\@163.com -xu ctbioscience\@163.com -xp ctb051989886883 -o message-charset=utf-8");
  }
  else {
    say "没有查到任何停电信息";
  }
}
else {
  say "content error: $content";
}
