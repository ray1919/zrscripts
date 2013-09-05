#!/usr/bin/env perl
# Author: Zhao Rui
# Date: 2013-9-2
# Purpose: 检查任务时间表，发送提醒邮件

use warnings;
use lib '/home/xxxxxxx/bin/lib';
use Ctnet::Schema;
use 5.010;
use POSIX qw(strftime);
use Data::Dump qw/dump/;
my $schema = Ctnet::Schema->connect('dbi:mysql:xxxx', 'xxxx', 'xxxx', { mysql_enable_utf8 => 1 });

my $manager_email = 'xxxxx@xxxxx.com';
my $date = strftime "%Y-%m-%d", localtime;
my $date4b = strftime "%Y-%m-%d", localtime(time() - 3600*24*4);
my $date7b = strftime "%Y-%m-%d", localtime(time() - 3600*24*7);
my (%return_content, $new_content, $comm_content);
my $baseurl = 'http://192.168.1.178/~xxxxxxx/xxxx/index.php/';

task_remind();

sub return_visit {
# 回访提醒
my $all_returns = $schema->resultset('Visit')->search(
  { return_visit => 1,
    scheduled => { '<' => $date }
  });

if ( $all_returns > 0 ) {
while (  my $return = $all_returns->next) {
  my $vurl = "${baseurl}visit/".$return->id;
  $return_content{$return->executor} .= "<tr> <td>".$return->customer->title.
  "</td> <td>".$return->scheduled.
  "</td> <td><a href=\"$vurl\" target=\"view_window\">$vurl</a>".
  "</td> </tr>\n";
}

foreach $email (keys %return_content) {
  next unless ($email =~ /\S+@\S+/);
  open(OUT, ">/home/xxxxxxx/bin/return_visit/${email}_$date.html") or die $!;
  # binmode OUT, ':encoding(utf8)';
  say OUT "<html><table border=1>\n";
  say OUT "<tr> <td>title</td> <td>scheduled date</td> <td>url</td> </tr>\n";
  say OUT $return_content{$email};
  say OUT "</table></html>\n";
  say OUT "<br>XXXX";
  say OUT "<br>(系统邮件请勿回复)";
  close(OUT);
  my $title = "$date communication return visit scheduled";
  system("cat /home/xxxxxxx/bin/return_visit/${email}_$date.html | sendemail -u '$title' -f sender\@163.com -s smtp.163.com -t '".$email."' -cc 'xdlei\@yahoo.com' -xu sender\@163.com -xp passwd -o message-charset=utf-8");
}
}
}

sub new_customers {
# 新客户统计
my $new_content = '';
$all_returns = $schema->resultset('Customer')->search(
  { add_date => { '>=' => $date4b } });
while (  my $return = $all_returns->next) {
  $new_content .= "<tr> <td>".$return->title."</td> <td>".$return->organization."</td> <td>".$return->add_date."</td> <td>".$return->source."</td> <td>".$return->comment."</td> </tr>\\n";
}
$new_content =~ s/\r//g;
$new_content =~ s/\n/<br>/g;
$new_content =~ s/\\n/\n/g;

  open(OUT, ">/home/xxxxxxx/bin/return_visit/${manager_email}_new_$date.html") or die $!;
  say OUT "<html><table border=1>\n";
  say OUT "<tr><th colspan=5>new contacts added in last 4 days</th></tr>\n";
  say OUT "<tr> <td>title</td> <td>organization</td> <td>add_date</td> <td>source</td> <td>note</td> </tr>\n";
  say OUT $new_content;
  say OUT "</table></html>\n";
  say OUT "<br>";
  say OUT "<br>";
  close(OUT);

# 新交流统计
$all_returns = $schema->resultset('Visit')->search(
  { time  => { '>=' => $date4b } });
while (  my $return = $all_returns->next) {
  $comm_content .= "<tr> <td>".$return->customer->title."</td> <td>".
      $return->customer->organization."</td> <td>".
      $return->status."</td> <td>".
      $return->way."</td> <td>".
      $return->class->class."</td> <td>".
      $return->time."</td> <td>".
      $return->user->username."</td> <td>".
      $return->return_visit."</td> <td>".
      $return->scheduled."</td> <td>".
      $return->comment."</td> </tr>\\n";
}
$comm_content =~ s/\r//g;
$comm_content =~ s/\n/<br>/g;
$comm_content =~ s/\\n/\n/g;

  open(OUT, ">>/home/xxxxxxx/bin/return_visit/${manager_email}_new_$date.html") or die $!;
  say OUT "<html><table border=1>\n";
  say OUT "<tr><th colspan=10>new communication added in last 4 days</th></tr>\n";
  say OUT "<tr> <td>title</td> <td>organization</td> <td>status</td> <td>way</td> <td>class</td> <td>date</td> <td>employee</td> <td>follow up</td> <td>scheduled</td> <td>note</td> </tr>\n";
  say OUT $comm_content;
  say OUT "</table></html>\n";
  say OUT "<br>XXXX";
  say OUT "<br>(空表表示没有相关记录，系统邮件请勿回复)";
  close(OUT);

  system("cat /home/xxxxxxx/bin/return_visit/${manager_email}_new_$date.html | sendemail -u 'new contacts and communication in last 4 days - CT Bio.' -f sender\@163.com -s smtp.163.com -t '".$manager_email."' -xu sender\@163.com -xp passwd -o message-charset=utf-8");
}

sub task_remind {
# 过去3个月任务
my %new_content = ();
my $date90b = strftime "%Y-%m-%d", localtime(time() - 3600*24*90);
$all_returns = $schema->resultset('Task')->search(
  { acceptance_date => { '>=' => $date90b } });
while (  my $return = $all_returns->next) {
  my $id = $return->id;
  $new_content{$return->owner->email} .= "<tr> <td>".$return->name."</td> <td>".$return->description."</td> <td>".$return->note."</td> <td>".$return->status."</td> <td>".$return->due_date."</td> <td>".$return->acceptance_date."</td> </tr>\\n";
  $username{$return->owner->email} = $return->owner->username;
  $new_content{$return->owner->email} =~ s/\r//g;
  $new_content{$return->owner->email} =~ s/\n/<br>/g;
  $new_content{$return->owner->email} =~ s/\\n/\n/g;
}

  open(OUT, ">/home/xxxxxxx/bin/return_visit/task_$date.html") or die $!;
  say OUT "<html>\n";
foreach my $email (keys %new_content) {
  say OUT "<table border=1>\n";
  say OUT "<tr><th colspan=6>$username{$email}</th></tr>\n";
  say OUT "<tr> <td>task</td> <td>description</td> <td>note</td> <td>status</td> <td>due date</td> <td>create_date</td> </tr>\n";
  say OUT $new_content{$email};
  say OUT "</table>\n";
  say OUT "<br>";
}
  say OUT "<br>XXXX";
  say OUT "<br>(系统邮件请勿回复)";
  say OUT "</html>\n";
  close(OUT);
  system("cat /home/xxxxxxx/bin/return_visit/task_$date.html | sendemail -u 'Employee task in last 3 months - CT Bio.' -f sender\@163.com -bcc xxxxxx\@163.com -s smtp.163.com -t '".$manager_email."' -xu sender\@163.com -xp passwd -o message-charset=utf-8");
}
