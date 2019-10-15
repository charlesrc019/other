/*-------------------------------------------------------------
 * 
 *   .SYNOPSIS
 *   DISTANCE STOPLIGHT - OUTPUT
 *   The output end of a two-part distance measuring stoplight.
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

// Set global varibles.
const char* HOSTNAME = "arduino1";
const char* DB_URL = "http://www.chris-eng.com/api/data/MongoLite.php";
const int TIMEOUT_DELAY = 1000;
const int PIN_RED = 2;
const int PIN_YELLOW = 0;
const int PIN_GREEN = 4;
const char* SENSOR_NAME = "arduino2";
const int STOP_CM = 20;
const int SLOW_CM = 40;

// Set function variables.
WiFiServer web_server(80);
unsigned long timer = 0;
String sensor_ip = "";

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
      delay(TIMEOUT_DELAY);
    }
    
    web_client.end();
  }
  Serial.println("*NI: network info saved successfully");
}

// Function. Get the network information about a specified device.
String getNetworkInfo(String dev) {

  String get_url = String(DB_URL) + "?id=" + dev;
  StaticJsonDocument<64> network_info;
  HTTPClient web_client;
  String response_data = "";

  // Attempt to post network information until successful.
  bool get_status = false;
  while (get_status == false) {

    // Configure GET request.
    web_client.begin(get_url);
    int response_code = web_client.GET();

    // Compile response data.
    response_data = web_client.getString();
    if (response_data.indexOf("local_ip") >= 0)
      get_status = true;      
    else {
      Serial.println("*NI: error getting network info");
      delay(TIMEOUT_DELAY);
    }

    web_client.end();
  }

  deserializeJson(network_info, response_data);
  String dev_ip = network_info["local_ip"];
  
  Serial.print("*NI: ");
  Serial.print(dev);
  Serial.print(" = ");
  Serial.println(dev_ip);
  
  return dev_ip;
}

// Function. Set stoplight to specified state.
void setLight(int state) {

  // Turn all lights off.
  digitalWrite(PIN_RED, LOW);
  digitalWrite(PIN_YELLOW, LOW);
  digitalWrite(PIN_GREEN, LOW);

  // Turn on specified light.
  if (state == 0) {
    digitalWrite(PIN_RED, HIGH);
  }
  else if (state == 1) {
    digitalWrite(PIN_YELLOW, HIGH);
  }
  else if (state == 2) {
    digitalWrite(PIN_GREEN, HIGH);
  }
  
}

// Function. Initialization.
void setup() {

  // Stoplight initialization.
  pinMode(PIN_RED, OUTPUT);
  pinMode(PIN_YELLOW, OUTPUT);
  pinMode(PIN_GREEN, OUTPUT);
  setLight(-1);

  // Enable serial port feedback.
  Serial.begin(115200);

  // WiFiManager initialization.
  WiFiManager wifiManager;
  wifiManager.autoConnect(HOSTNAME);

  // Configure network information.
  postNetworkInfo();
  sensor_ip = getNetworkInfo(SENSOR_NAME);

}

// Function. Main. Infinte loop.
void loop(){

  // Get distance information from detector.
  String response_data = "";
  if (millis() > timer) {
    
    HTTPClient web_client;
  
    // Perform web request.
    String remote_url = "http://" + sensor_ip;
    web_client.begin(remote_url);
    int response_code = web_client.GET();

    // Verify web request.
    response_data = web_client.getString();
    web_client.end();
    if (response_data.indexOf("distance") < 0) {
      setLight(-1);
      Serial.println("Stoplight: error getting distance info");
      timer = addMillis(TIMEOUT_DELAY);
      response_data = "";
    }  
    
  }

  // Update state and timer.
  if (response_data != "") {

    // Extract distance information.
    StaticJsonDocument<64> sensor_info;
    deserializeJson(sensor_info, response_data);
    String tmp1 = sensor_info["update_interval"];
    int update_interval = tmp1.toInt();
    String tmp2 = sensor_info["distance"];
    int distance = tmp2.toInt();

    // Update timer. 
    timer = addMillis( (update_interval-250) );

    // Update distance states.
    if (distance <= STOP_CM) {
      setLight(0);
    }
    else if (distance <= SLOW_CM) {
      setLight(1);
    }
    else if (distance > SLOW_CM) {
      setLight(2);
    }
  }

}
