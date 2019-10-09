<?php

/*
/   BYU Y-TIME TRIGGER FOR IFTTT (UNOFFICIAL)
/   Author: Charles Christensen
/   Edited: April 3, 2019
/
/   Required Dependencies: 
/       - IFTTT
/       - PHP Webserver
/       - BYU API Token
/           (Non-expiring, production API access token. $API_TOKEN)
/           <https://api.byu.edu/store/apis/info?name=Punches&version=v1&provider=BYU/larowley>
/
/   Intended Use:
/   Use to clock in/out from your BYU campus job based on whatever
/   trigger you choose. As is standard with BYU, please remember the
/   honor code when using this trigger. It is dishonest to get paid
/   for time that you did not work.
/
/   Example:
/   [your_public_webserver]ytime.php?type=[IFTTT_EnteredOrExited]&id=[BYU_ID_#]
/
/   Caveats:
/   You may need to adjust the punch_time variable timezone to match the zone of
/   you hosting server.
*/

// Global variables.
$API_TOKEN = "[YOUR_API_TOKEN]";

// Check and get required parameters.
if ( !isset($_GET['type'])  ||
     !isset($_GET['id'])    ) {
    http_response_code(400);
    exit();
}
$_GET['id'] = preg_replace("/(%20|\s)/","",$_GET['id']);
$_GET['type'] = preg_replace("/(%20|\s)/","",$_GET['type']);
$_GET['type'] = strtolower($_GET['type']);
if ( ($_GET['type'] != "entered" &&
     $_GET['type'] != "exited" ) ||
     strlen($_GET['id']) != 9 ) {
    http_response_code(400);
    exit();
}
$id = $_GET['id'];

// Compile API content.
$punch_time = date('H:i:s',strtotime("-6 hours"));
$punch_date = date('Y-m-d');
$punch_type = "I";
$clock_in = "true";
if ($_GET['type'] == "exited") {
    $punch_type = "O";
    $clock_in = "false";
}

$data = array(
    "punch" => array(
        "clock_in"              =>  $clock_in,
        "employee_record"       =>  "0",
        "punch_date"            =>  $punch_date,
        "punch_time"            =>  $punch_time,
        "internet_address"      =>  "0.0.0.0",
        "punch_type"            =>  $punch_type,
        "longitude"             =>  "-111.649290",
        "latitude"              =>  "40.250990",
        "location_description"  =>  "Y-Time Mobile App",
        "time_collection_source"=>  "MBL"
        )
);
$json = json_encode($data);

// Compile API request.
$ch = curl_init("https://api.byu.edu:443/domains/erp/hr/punches/v1/$id");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLINFO_HEADER_OUT, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $json);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    "Content-Type: application/json",
    "Content-Length: " . strlen($json),
    "Authorization: Bearer $API_TOKEN",
    "Accept: application/json"
));
 
// Execute API call.
$result = curl_exec($ch);
curl_close($ch);

header('Content-Type: application/json');
echo $result;

?>
