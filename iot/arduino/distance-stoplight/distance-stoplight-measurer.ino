/*-------------------------------------------------------------
 * 
 *   .SYNOPSIS
 *   DISTANCE STOPLIGHT - INPUT
 *   The input end of a two-part distance measuring stoplight.
 *   
 *   .NOTES
 *   Author: Charles Christensen
 *   
-------------------------------------------------------------*/

// Import libraries.
#include <ESP8266WiFi.h>
#include <DNSServer.h>
#include <WiFiManager.h>
#include <ArduinoJson.h>
#include <ESP8266HTTPClient.h>
#include <ESP8266WebServer.h>
#include <NewPing.h>

// Set global varibles.
const char* HOSTNAME = "arduino2";
const char* DB_URL = "http://www.chris-eng.com/api/data/MongoLite.php";
int PIN_TRIG = 13;
int PIN_ECHO = 15;
int MEASURE_DELAY = 750;

// Set function variables.
WiFiServer web_server(80);
NewPing sonar(PIN_TRIG, PIN_ECHO, 200);
unsigned long timer = 0;
int distance = 0;

// Function. Create timer value the specified number of millis in the future.
int addMillis(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}

// Function. Post information about network status to private server.
bool postNetworkInfo() {

  // Compile network information.
  String post_data = "id=" + String(HOSTNAME) + "&doc=";
  StaticJsonDocument<64> network_info;
  network_info["local_ip"] = WiFi.localIP().toString();
  serializeJson(network_info, post_data);

  HTTPClient web_client;

  // Attempt to post network information until successful.
  bool post_status = false;
  while (post_status == false) {
  
    // Configure POST request.
    web_client.begin(DB_URL);
    web_client.addHeader("Content-Type", "application/x-www-form-urlencoded");
    int response_code = web_client.POST(post_data);
  
    // Get response info.
    String response_data = web_client.getString();
    if (response_data.indexOf("saved") >= 0)
      post_status = true;
    else {
      Serial.println("*NI: error saving network info");
      delay(20000);
    }

    web_client.end();
  }
  Serial.println("*NI: network info saved successfully");
}

// Function. Initialization.
void setup() {

  // Enable serial port feedback.
  Serial.begin(115200);

  // WiFiManager initialization.
  WiFiManager wifiManager;
  wifiManager.autoConnect(HOSTNAME);

  // Configure network information.
  postNetworkInfo();

  // Webserver initialization.
  web_server.begin();
}

// Function. Main. Infinte loop.
void loop(){

  // Update distance measurement.
  if (millis() > timer) {

    // Fetch new distance.
    int distance_new = sonar.ping_cm();
    
    // Reject radically different measurements.
    if (distance_new > 0) {
      distance = distance_new;
    }

    // Update timer.
    timer = addMillis(MEASURE_DELAY);
  }

  // Perform actions if a webclient is currently connected.
  WiFiClient client = web_server.available();
  if (client) {
    while (client.connected()) {

      // Compile distance information in JSON.
      StaticJsonDocument<64> sensor_info;
      sensor_info["update_interval"] = String(MEASURE_DELAY);
      sensor_info["distance"] = String(distance);
      String response;
      serializeJson(sensor_info, response);

      // Send HTTP response.
      client.println("HTTP/1.1 200 OK");
      client.println("Content-type: application/json");
      client.println("Connection: close");
      client.println();
      client.println( response );
      client.println();
      break;
    }
    client.stop();
  }

}
