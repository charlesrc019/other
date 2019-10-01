/*-------------------------------------------------------------
 * 
 *   .SYNOPSIS
 *   STOPLIGHT
 *   A simple, wifi-controlled stoplight.
 *   
 *   .NOTES
 *   Author: Charles Christensen
 *   
-------------------------------------------------------------*/

// Import libraries.
#include <ESP8266WiFi.h>        // WifiMgr
#include <DNSServer.h>          // WifiMgr
#include <WiFiManager.h>        // WifiMgr
#include <ESP8266WebServer.h>   // Webserver

// Set global varibles.
WiFiServer server(80);          // Webserver
int light_r = 2;                // Stoplight
int light_y = 0;                // Stoplight
int light_g = 4;                // Stoplight
int light_state = 0;            // Stoplight
bool auto_mode = true;          // Stoplight
unsigned long timer = 0;        // Stoplight

// Function. Initialization.
void setup() {

  // Enable serial port feedback.
  Serial.begin(115200);

  // WiFiManager initialization.
  WiFiManager wifiManager;
  wifiManager.autoConnect("arduino1");

  // Webserver initialization.
  server.begin();

  // Stoplight initialization.
  pinMode(light_r, OUTPUT);
  pinMode(light_y, OUTPUT);
  pinMode(light_g, OUTPUT);
}

// Function. Create timer value the specified number of millis in the future.
int addMillis(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}

// Function. Set stoplight to specified state.
void setLight(int state) {

  // Turn all lights off.
  digitalWrite(light_r, LOW);
  digitalWrite(light_y, LOW);
  digitalWrite(light_g, LOW);

  // Turn on specified light.
  if (state == 0) {
    digitalWrite(light_r, HIGH);
  }
  else if (state == 1) {
    digitalWrite(light_y, HIGH);
  }
  else if (state == 2) {
    digitalWrite(light_g, HIGH);
  }

  // Save light state information.
  light_state = state;
  
}

// Function. Main. Infinte loop.
void loop(){

  // Listen for incoming web clients.
  WiFiClient client = server.available();

  // Perform actions if a webclient is currently connected.
  if (client) {
    while (client.connected()) {

      // Collect request from client.
      String request = "";
      if (client.available()) {

        // Read request header, character by character.
        while (true) {
          char c = client.read();
          request += c;
          
          // Check for a new line, which means we have GET portion of request.
          if (c == '\n') {
              break;
          }
        }
    
        // Perform state adjustments by looking for GET parameters.
        if (request.indexOf("GET /auto") >= 0) {
            auto_mode = true;
        }
        else if (request.indexOf("GET /red") >= 0) {
            auto_mode = false;
            setLight(0);
        }
        else if (request.indexOf("GET /yellow") >= 0) {
            auto_mode = false;
            setLight(1);
        }
        else if (request.indexOf("GET /green") >= 0) {
            auto_mode = false;
            setLight(2);
        }

        // Send response to client.
        client.println("HTTP/1.1 200 OK");
        client.println("Content-type:text/html");
        client.println("Connection: close");
        client.println();
        char response[] = "<!DOCTYPE html>"
                            "<html>"
                            "<head>"
                            "  <title>Stoplight</title>"
                            "  <link rel='stylesheet' href='https://cdnjs.cloudflare.com/ajax/libs/uikit/3.2.0/css/uikit.min.css' />"
                            "</head>"
                            "<body>"
                            "  <div class='uk-container uk-margin-top'>"
                            "    <img class='uk-align-center' src='http://charlesrchristensen.com/storage/blog/graphics/post4_%20stoplight.png' />"
                            "    <a class='uk-button uk-button-default uk-align-center uk-width-1-4' href='/red'>Red</button></a>"
                            "    <a class='uk-button uk-button-default uk-align-center uk-width-1-4' href='/yellow'>Yellow</button></a>"
                            "    <a class='uk-button uk-button-default uk-align-center uk-width-1-4' href='/green'>Green</button></a>"
                            "    <a class='uk-button uk-button-primary uk-align-center uk-width-1-4' href='/auto'>Auto</button></a>"
                            "  </div>"
                            "</body>"
                            "</html>";
        client.println( response );
        client.println();
        break; 
      }
    }
    client.stop();
  }

  // Perform automatic state changes.
  if ( (auto_mode) && (millis() > timer) ) {
    if (light_state == 0) {
      setLight(2);
      timer = addMillis(2000);
    }
    else if (light_state == 1) {
      setLight(0);
      timer = addMillis(3000);
    }
    else if (light_state == 2) {
      setLight(1);
      timer = addMillis(1000);
    }
  }


}
