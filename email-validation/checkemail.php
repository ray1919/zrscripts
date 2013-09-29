<?php

include_once('smtp_validateEmail.class.php');
include_once('php-progress-bar.php');
error_reporting(0);
// the email to validate  
$email_list = file('email.txt');
function chomp($input) {
  return trim(preg_replace('/\s+/', ' ', $input));
}
$email_list = array_map("chomp", $email_list);
$chunk = 1;
$total = ceil(count($email_list) / $chunk) + 1;
$done = 1;
unlink('e.txt');
while ( $emails = array_splice($email_list, 0, $chunk) ) {
  show_status($done++,$total);
  // an optional sender  
  $sender = 'zhaori@gmail.com';  
  // instantiate the class  
  $SMTP_Valid = new SMTP_validateEmail();  
  // do the validation  
  // $result = $SMTP_Valid->validate($email, $sender);  
  $result = $SMTP_Valid->validate($emails, $sender);  
  // view results  
  // var_dump($result);

  $boolarray = Array(false => 'false', true => 'true');
  $fp = fopen('e.txt', 'a');
  foreach ( $result as $email => $is_valid ) {
    fwrite($fp, "$email\t$boolarray[$is_valid]\n");
  }
  if (empty($result)) {
    fwrite($fp, "$emails[0]\tfalse\n");
  }
}
fclose($fp);
show_status($done++,$total);
?>  
