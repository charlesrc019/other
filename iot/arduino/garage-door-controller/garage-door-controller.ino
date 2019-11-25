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
const char* mqtt_HOST = "charlesrc19-dev-sandbox1.westus2.cloudapp.azure.com";
const char* mqtt_NAME = "charlesrc19/garage/port1/door/trigger";
const int serial_FREQ = 115200;
const int net_DELAY = 5000;
WiFiClient wifi_client;
WiFiManager wifi_manager;
PubSubClient mqtt_client(wifi_client);

// Global variables: door opener.
const char* dooropen_CHANNEL = "charlesrc19/garage/port1/door/trigger";
const int dooropen_PIN = 15;

// Initialization.
void setup() {

  // Network setup.
  Serial.begin(serial_FREQ);

  wifi_manager.autoConnect();
  
  mqtt_client.setServer(mqtt_HOST, 1883);
  mqtt_client.setCallback(mqttCallback);
  mqttConnect();

  // Door opener setup.
  pinMode(dooropen_PIN, OUTPUT);
  digitalWrite(dooropen_PIN, LOW);
}

// Main.
void loop() {

  // Network. Reconnect MQTT, if needed.
  while (!mqtt_client.connected()) {
    mqttConnect();
  }

  // Network. Check for MQTT messages.
  mqtt_client.loop();

}

// Opener function. Trigger garage door to open/close.
void dooropenTrigger() {
  digitalWrite(dooropen_PIN, HIGH);
  delay(250);
  digitalWrite(dooropen_PIN, LOW);

}

// Network function. Process arriving MQTT message.
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  
  // Print the MQTT message to serial.
  Serial.print("MQTT://");
  Serial.print(topic);
  Serial.print(": ");
  for (int i = 0; i < length; i++) {
    Serial.print((char)payload[i]);
  }
  Serial.println();

  // Adjust internal states, as determined by message.
  String topic_name(topic);
  payload[length] = '\0';

  // dooropen_trigger
  if (topic_name.indexOf(dooropen_CHANNEL) >= 0) {
    if (strcmp((char*)payload, "1") == 0) {
      dooropenTrigger();
    }
  }
  
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

  // Subscribe to all relevant MQTT publishers.
  mqtt_client.subscribe(dooropen_CHANNEL);
  
}

// System function. Create timer value the specified number of millis in the future.
int timerFetch(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}
