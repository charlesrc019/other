<?php

/*
/   TWILIO TEXT MESSAGE API
/   Author: Charles Christensen
/   Edited: June 3, 2019
/
/   Required Dependencies: 
/       - Twilio account
/       - Twilio PHP libraries
/  
/   Intended Use:
/   Use webhooks to send Twilio messages.
/
*/

// Global variables.
$TWILIO_SID = "[YOUR_TWILO_SID]";
$TWILIO_TOKEN = "[YOUR_TWILO_TOKEN]";

// Check and get required parameters.
if ( !isset($_GET['dst'])  ||
     !isset($_GET['msg'])    ) {
    http_response_code(400);
    exit();
}

$_GET['dst'] = preg_replace("/(%20|\s)/","",$_GET['dst']);
$_GET['dst'] = strtolower($_GET['dst']);
$dsts = explode(";", $_GET['dst']);
$_GET['msg'] = preg_replace("/(%27|\')/","",$_GET['msg']);
$body = $_GET['msg'];
$msg = "<Automated Message>\n$body";

// Create new Twilio connection.
require_once 'vendor/autoload.php';
use Twilio\Rest\Client;
$twilio = new Client($TWILIO_SID, $TWILIO_TOKEN);

// Send messages.
$txt_sids = [];
foreach ($dsts as $dst)
{
  $to = "+1$dst";
  $message = $twilio->messages
                      ->create($to,                      // << TO
                        array("from" => "+12083141480",  // << FROM
                              "body" => $msg             // << MESSAGE
                              )
                      );
  $txt_sids[] = $message->sid;
}

header('Content-Type: application/json');
echo json_encode($txt_sids,JSON_PRETTY_PRINT);
http_response_code(200);
exit();

?>
