<?php

// Initialize global parameters.
$SQL_USERNAME = "";
$SQL_PASSWORD = "";
$SQL_DATABASE = "";
$conn = NULL;

// Function. Display an JSON message.
function jsonMessage ($msg='Generic error.', $success=FALSE) {
    
    // Compile message.
    $status = 'error';
    if ($success) {
        $status = 'success';
    }
    $json = array(
        'status' => $status,
        'details' => $msg
    );

    // Return message.
    header('Connection: close');
    header('Content-Type: application/json');
    header('Content-Encoding: none');
    echo json_encode($json,JSON_PRETTY_PRINT);

    // Close SQL.
    if ( !($GLOBALS['conn']->connect_error) && ($GLOBALS['conn'] != NULL) ) {
        mysqli_close($GLOBALS['conn']);
    }

    exit();
}

// Function. Open SQL connection.
function openSQL() {
    $GLOBALS['conn'] = new mysqli('localhost', $GLOBALS['SQL_USERNAME'], $GLOBALS['SQL_PASSWORD'], $GLOBALS['SQL_DATABASE']);
    if ($GLOBALS['conn']->connect_error) {
        jsonMessage("Unable to connect to database.");
    }
    mysqli_set_charset($GLOBALS['conn'], 'utf8');
    return;
}

// Function. Check if string is JSON. 
// (https://stackoverflow.com/questions/6041741/fastest-way-to-check-if-a-string-is-json-in-php)
function isJSON($string) {
    json_decode($string);
    return (json_last_error() == JSON_ERROR_NONE);
}

// MAIN.
// Process a POST request.
if ($_SERVER['REQUEST_METHOD'] === 'POST') {

    // Check and read variables, if provided.
    if (!isset($_POST['id']) || 
        !isset($_POST['doc'])) {
        jsonMessage("Incorrect parameters.");
    }
    if (preg_match("/[^A-Za-z0-9-_.:]+/", $_POST['id']) || 
        preg_match("/[^A-Za-z0-9\s-_.!?,:\"{}\[\]\(\)]+/", $_POST['doc'])) {
        jsonMessage("Invalid parameters.");
    }
    if ( !isJSON($_POST['doc']) ) {
        jsonMessage("New document is invalid.");
    }
    $id = $_POST['id'];
    $doc = $_POST['doc'];

    // Prepare SQL.
    $sql1 = "SELECT * FROM mongo_lite WHERE id='$id';";
    $sql2 = "UPDATE mongo_lite SET document='$doc' WHERE id='$id';";
    openSQL();

    // Change SQL if variable doesn't exist.
    if ($result1 = $GLOBALS['conn']->query($sql1)) {
        if ($result1->num_rows == 0) {
            $sql2 = "INSERT INTO mongo_lite (id, document) VALUES ('$id', '$doc');";
        }
        $result1->close();
    }
    else {
        jsonMessage("Unable to evaluate document.");
    }

    // Insert new values.
    if ($result2 = $GLOBALS['conn']->query($sql2)) {
        jsonMessage('Document saved.', TRUE);
    }
    else {
        jsonMessage('Unable to save document.');
    }

}

// Process a GET request.
else if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    // Check and read variable, if provided.
    if ( !isset($_GET['id']) ) {
        jsonMessage("Incorrect parameters.");
    }
    if (preg_match("/[^A-Za-z0-9-_.:]+/", $_GET['id'])) {
        jsonMessage("Invalid parameters.");;
    }
    $id = $_GET['id'];

    // Prepare SQL.
    $sql1 = "SELECT * FROM mongo_lite WHERE id LIKE '$id';";
    openSQL();

    // Fetch SQL results.
    $raw = NULL;
    if ($result1 = $GLOBALS['conn']->query($sql1)) {
        while ($row = $result1->fetch_row()) {
            $raw = $row[1];
        }
    }
    else {
        jsonMessage("Unable to evaluate document.");
    }

    // Check results.
    if ($raw == NULL) {
        jsonMessage("Unable to find document.");
    }
    if ( !isJSON($raw) ) {
        jsonMessage("Document is corrupt. Manual modification required.");
    }

    // Return results.
    $json = json_decode($raw);
    header('Connection: close');
    header('Content-Type: application/json');
    header('Content-Encoding: none');
    echo json_encode($json,JSON_PRETTY_PRINT);

    mysqli_close($GLOBALS['conn']);
}

// Process other request types.
else {
    jsonMessage("Database operation type not permitted.");
}

?>
