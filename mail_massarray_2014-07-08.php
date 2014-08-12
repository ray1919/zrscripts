<?php
require_once '/home/zhaorui/bin/sendmail/lib/swift_required.php';
date_default_timezone_set('Asia/shanghai');

// the email to validate  
$list_file = '/home/zhaorui/bin/sendmail/massarray_list.txt';
$email_list = file($list_file);
function chomp($input) {
  return trim(preg_replace('/\s+$/', ' ', $input));
}
$email_list = array_map("chomp", $email_list);

//select host and change from accordingly. Note the value of from and username must be the same. Otherwise the server would not send the mail out.
if (rand() % 2 == 0) //if times 2
 { $host = "smtp.chutianbio.net";
   $username = "techsupport@chutianbio.net";
   $password = "20081028ctbio";
   $from = "techsupport@chutianbio.net";
  }
else
 { $host = "smtp.chutianbio.cn";
   $username = "techsupport@chutianbio.cn";
   $password = "20081028ctbio";
   $from = "techsupport@chutianbio.cn";
 }

$fp = fopen($list_file, 'w');
$flag = 0;
foreach ($email_list as $email) {
  $email = preg_split("/\t/", $email);
  if ($email[1] == 0 and $flag == 0) {
    $flag = 1;
    try {
    if (ctmail($email[0],$host,$username,$password) == 1) {
      $email[1] = 1;
    }
    else {
      $email[1] = -1;
    }
    } catch (Exception $e) {
      echo 'Caught exception: ',  $e->getMessage(), "\n";
      $email[1] = -1;
    }
  }
  fwrite($fp, join("\t",$email)."\n");
}
fclose($fp);

function ctmail($email,$host,$username,$password) {

  echo $email;
$subject = '楚天生物: MassARRAY SNP基因型分析';

$html = '
<html>
<head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type">

    <title>需要验证大量生物样本的几个至几十个标志基因表达吗？</title>
    <style media="screen" type="text/css">
  body {
         background-color: #FFFFFF;
      }

      a img {
         border: none;
      }

      table.bg1 {
         background-color: #FFFFFF;
      }

      table.bg2 {
         background-color: #ffffff;
      }

      td.permission {
         background-color: #eeeeee;
         padding: 10px 20px 10px 20px;
      }

      td.permission p {
         font-family: Arial;
         font-size: 11px;
         font-weight: normal;
         color: #333333;
         margin: 0;
         padding: 0;
      }

      td.permission p a {
         font-family: Arial;
         font-size: 11px;
         font-weight: normal;
         color: #333333;
      }

      td.body {
         padding: 0 20px 20px 20px;
         background-color: #ffffff;
      }


      td.buttons {
        padding: 20px 0 0 0; 
      }

      td.mainbar h2 {
         font-family: Arial;
         font-size: 16px;
         font-weight: bold;
         color: #680606;
         margin: 0;
         padding: 0;
      }

      td.mainbar h2 a {
         font-family: Arial;
         font-size: 16px;
         font-weight: bold;
         color: #680606;
         text-decoration: none;
         margin: 0;
         padding: 0;
      }

      td.mainbar img.hr {
         margin: 0;
         padding: 0 0 10px 0;
      }

      td.mainbar p {
         font-family: Arial;
         font-size: 13px;
         font-weight: normal;
         color: #333333;
         margin: 0 0 14px 0;
         padding: 0;
      }

      td.mainbar p a {
         font-family: Arial;
         font-size: 13px;
         font-weight: normal;
         color: #680606;
      }

      td.mainbar p.more a {
         font-family: Arial;
         font-size: 13px;
         font-weight: normal;
         color: #680606;
         text-decoration: none;
      }

      td.mainbar ul {
         font-family: Arial;
         font-size: 13px;
         font-weight: normal;
         color: #333333;
         margin: 0 0 14px 24px;
         padding: 0;
      }

      td.mainbar ul li a {
         font-family: Arial;
         font-size: 13px;
         font-weight: normal;
         color: #680606;
      }

      td.footer {
         padding: 10px 20px 10px 20px;
         background-position: top center;
         background-color: #333333;
         height: 50px;
         vertical-align: middle;
         color: white;
      }

      td.footer p {
         font-family: Arial;
         font-size: 12px;
         color: white;
         line-height: 16px;
         background-color: #333333;
         width: 600px;
         vertical-align: middle;
         align: left;
         background-position: top center;
      }
    </style>
</head>

<body>
    <img src=
    "http://www.ctbioscience.com/images/ctbio_logo.jpg?EID='.$email.'">

    <table border="0" cellpadding="0" cellspacing="0" class="bg1" width="600">
        <tr>
            <td align="center">
                <table border="0" cellpadding="0" cellspacing="0" class="bg2"
                width="600">
                    <tr>
                        <td align="left" class="permission">
                            <p>页面没有正常显示? 请点击<a href=
                            "http://www.ctbioscience.com/?EID=' .$email.'/">这里</a>。</p>
                        </td>
                    </tr>

                    <tr>
                        <td style=
                        "background-color: #005aca; width: 600px; height: 50px; text-align: center; font-weight: bold; font-size: 24px; color: white">
                        江苏楚天生物科技有限公司</td>
                    </tr>

                    <tr>
                        <td height="30" style=
                        "background-color: white; width=">
                    </tr><!-- <td class="header" align="left">
                 <img src="header.gif" alt="Header" width="600" height="150" /> 
                 
               </td> -->

                    <tr>
                        <td class="body" valign="top">
                            <table border="0" cellpadding="0" cellspacing="0"
                            width="100%">
                                <tr>
                                    <td align="left" class="mainbar" valign=
                                    "top">
                                        <h2><a href=
                                        "http://ctbioscience.com/massarray-snp-genotyping-S9/">
                                        MassARRAY SNP基因型分析</a></h2>
                                        <hr width="560px">

                                        <p style="line-height: 175%;">
                                        MassARRAYSNP基因分型技术是由美国Sequenom公司开发的基于飞行质谱的分型技术，楚天生物为该公司<u><b><a href="http://ctbioscience.com/news/NID-12">中国区授权服务商</a></b></u>（Certified Service Provider）。该技术通过PCR扩增跨越SNP位点的DNA序列，然后应用单一延伸引物(extension primer)扩增PCR产物，确保延伸引物只延长一个碱基。延伸产物用飞行质谱(TOF, time of flight)进行分析，根据一个碱基的分子量差别对SNP进行分型，也可做SNP位点等位基因频率计算。MassARRAY SNP基因型分析可以进行多重SNP分型，即一个反应可同时分型多个SNP位点。该技术分析准确，在分析数十上百个SNP时具有价格优势。</p>
                                        <p><a href="http://ctbioscience.com/massarray-snp-genotyping-S9/">更多信息 >></a></p>

                                        <h2><a href=
                                        "http://ctbioscience.com/massarray-snp-genotyping-S9/">
                                        产品特点</a></h2>

										<ul>
										<li>高性价比：在所有的SNP分型方法中，价格最低。</li>
										<li>高准确性：采用尖端的飞行质谱的分型技术，分析精准。</li>
										<li>广泛性：超过2000篇SCI文章，包括<i>Nature, Science</i>等顶尖杂志。</li>
										<li>高效性：最快2周即可提供完整的实验报告。</li>
										</ul>


                                        <hr width="560">
                                    </td>
                                </tr>

                            </table>
                        </td>
                    </tr>

                    <tr>
                        <td class="footer">
                            <p>江苏楚天生物科技有限公司<br>

                            江苏常州市国家高新区科勒路1号1栋四层，电话：0519 - 8988 6883</p>
                        </td>
                    </tr>

                    <tr>
                        <td align="left" class="permission">
                            <p>
                            江苏楚天生物竭诚为您提供高品质的产品和服务，让您省下宝贵的时间和有限的资源，专注您的科研。</p>

                            <p>如果你不想收到产品推荐邮件，请点击<a href=
                            "http://www.ctbioscience.com/unsubscribe/'.$email.'">这里退订</a></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
';

// Create the Transport
//$transport = Swift_SmtpTransport::newInstance('smtp.163.com', 25)
//  ->setUsername('ctbioscience@163.com')
//  ->setPassword('ctb051989886883')
//  ;
$transport = Swift_SmtpTransport::newInstance($host, 25)
  ->setUsername($username)
  ->setPassword($password)
  ;

// Create the Mailer using your created Transport
$mailer = Swift_Mailer::newInstance($transport);

// Create a message
$message = Swift_Message::newInstance($subject)
  //->setFrom(array('techsupport@ctbioscience.com' => 'Ct Bioscience'))
  ->setFrom(array($username => 'Ct Bioscience'))
  ->setTo($email)
  ->setBody($html, 'text/html')
  ;

// Send the message
// $result = $mailer->send($message);
// Pass a variable name to the send() method
if (!$mailer->send($message, $failures))
{
  return 0;
}

return 1;
}

?>



