<?php

$SQL_DATABASE = "";
$SQL_USERNAME = "";
$SQL_PASSWORD = "";

// Function. Display an JSON message.
function jsonMessage ($MessageDetails='Generic error.', $IsSuccess=FALSE) {
    
    // Return message.
    $MessageResult = 'error';
    if ($IsSuccess) {
        $MessageResult = 'success';
    }
    $json = array(
        'result' => $MessageResult,
        'details' => $MessageDetails
    );
    ob_end_clean();
    header('Connection: close');
    header('Content-Type: application/json');
    header('Content-Encoding: none');
    ignore_user_abort(true);
    ob_start();
    echo json_encode($json,JSON_PRETTY_PRINT);
    $size = ob_get_length();
    header("Content-Length: $size");
    ob_end_flush();
    ob_flush();
    flush();
    sleep(10);

    // Terminate PHP.
    if ( !$GLOBALS['conn']->connect_error ) {
        mysqli_close($GLOBALS['conn']);
    }
    exit();
}

if ( isset($_GET['write']) xor isset($_GET['read']) ) {

    // Open connection to SQL database.
    $conn = new mysqli('localhost', $SQL_DATABASE, $SQL_PASSWORD, $SQL_USERNAME);
    if ($conn->connect_error) {
        jsonMessage("Unable to connect to database.");
    }
    mysqli_set_charset($conn, 'utf8');

    // Record a new tracker variable.
    if ( isset($_GET['write']) ) {
        
        // Compile SQL.
        $name = "Tracker." . preg_replace("!'%?[a-zA-Z0-9]+%?'!", "?", $_GET['write']);
        $value = "$_SERVER[REMOTE_ADDR]:$_SERVER[REMOTE_PORT]";
        $sql1 = "SELECT * FROM Variables WHERE Name='$name';";
        $sql2 = "";

        // Determine if variable has already been set.
        if ($result1 = $conn->query($sql1)) {

            // SQL to update variable.
            if ($result1->num_rows > 0) {
                $sql2 = "UPDATE Variables SET Value='$value' WHERE Name='$name';";
            }
            // SQL to create new variable.
            else {
                $sql2 = "INSERT INTO Variables (Name, Value) VALUES ('$name', '$value');";
            }

            $result1->close();
        }
        else {
            jsonMessage('Error querying database.');
        }

        // Insert new values.
        if ($result2 = $conn->query($sql2)) {
            jsonMessage('Variable recorded.', TRUE);
        }
        else {
            jsonMessage('Error recording variable.');
        }
    }

    // Search tracked variables.
    if ( isset($_GET['read']) ) {
        
        // Compile SQL.
        $name = "Tracker.%" . preg_replace("!'%?[a-zA-Z0-9]+%?'!", "?", $_GET['read']) ."%";
        $sql = "SELECT * FROM Variables WHERE Name LIKE '$name';";

        // Execute query.
        if ($result = $conn->query($sql)) {
            $results = array();
            while ($row = $result->fetch_row()) {
                $results[$row[0]] = $row[1];
            }
            $json['results'] = $results;
            ob_end_clean();
            header('Connection: close');
            header('Content-Type: application/json');
            header('Content-Encoding: none');
            ignore_user_abort(true);
            ob_start();
            echo json_encode($json,JSON_PRETTY_PRINT);
            $size = ob_get_length();
            header("Content-Length: $size");
            ob_end_flush();
            ob_flush();
            flush();
        }
        else {
            jsonMessage('Error querying database.');
        }
    }

    // Close MySQL connection.
    mysqli_close($conn);
}

// Return 404 error.
else {
    http_response_code(404);
}

?>