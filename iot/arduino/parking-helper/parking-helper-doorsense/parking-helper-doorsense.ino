/*-------------------------------------------------------------
 * 
 *   .SYNOPSIS
 *   PARKING HELPER - MEASURE
 *   Measure the position of a car to park to correctly.
 *   
 *   .NOTES
 *   Author: Charles Christensen
 *   
-------------------------------------------------------------*/

// Import libraries.
#include <ESP8266WiFi.h>
#include <WiFiManager.h>
#include <PubSubClient.h>

// Global varibles: network.
const char* mqtt_HOST = "";
const char* mqtt_NAME = "home/garage/port1/door";
const int serial_FREQ = 115200;
const int net_DELAY = 5000;
WiFiClient wifi_client;
WiFiManager wifi_manager;
PubSubClient mqtt_client(wifi_client);
unsigned long mqtt_timer = 0;

// Global variables: door
const int door_PIN = 15;
char* door_state = "0";

// Initialization.
void setup() {

  // Network setup.
  Serial.begin(serial_FREQ);

  wifi_manager.autoConnect(mqtt_NAME);
  
  mqtt_client.setServer(mqtt_HOST, 1883);
  mqttConnect();

  // Sensor setup.
  pinMode(door_PIN, INPUT);

}

// Main.
void loop() {

  // Network. Reconnect MQTT, if needed.
  while (!mqtt_client.connected()) {
    mqttConnect();
  }

  // Network. Publish periodic MQTT updates.
  if (millis() > mqtt_timer) {
    mqttPublish();
    mqtt_timer = timerFetch(net_DELAY);
  }

  // Door. Check door state.
  doorUpdate();

}

// Door function. Check if door sensor is open or closed.
void doorUpdate() {

  // Update door state.
  char* state = "";
  if (digitalRead(door_PIN) == 0) {
    state = "0";
  }
  else {
    state = "1";
  }

  // Publish updates, if necessary.
  if (strcmp(state, door_state) != 0) {
    door_state = state;
    mqttPublish();

    // Print out changes to state.
    Serial.print("Door: ");
    Serial.println(door_state);
  }
  
}

// Network function. Publish a brief update of relevant state information.
void mqttPublish() {

  // measure_state
  mqtt_client.publish(mqtt_NAME, door_state);
  
}

// Network function. Connect to MQTT server.
void mqttConnect() {
  
  // Connect to MQTT server.
  while (true) {
    Serial.println("*MQTT: Attempting MQTT connection.");
    if (mqtt_client.connect(mqtt_NAME)) {
      Serial.println("*MQTT: Successfully connected to broker.");
      break;
    }
    else {
      Serial.println("*MQTT: Connection failed. Retrying...");
      delay(net_DELAY);
    }
  }
  
}

// System function. Create timer value the specified number of millis in the future.
int timerFetch(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}
