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
const char* mqtt_NAME = "home/garage/port1/stoplight";
const int serial_FREQ = 115200;
const int net_DELAY = 5000;
WiFiClient wifi_client;
WiFiManager wifi_manager;
PubSubClient mqtt_client(wifi_client);

// Global variables: battery.
const char* pwrsv_CHANNEL = "home/garage/port1/door";
bool pwrsv_state = false;

// Global varibles: stoplight.
const char* stoplight_CHANNEL = "home/garage/port1/car_position";
const int stoplight_RED_PIN = 2;
const int stoplight_YELLOW_PIN = 0;
const int stoplight_GREEN_PIN = 4;
const int stoplight_DELAY = 500;
int stoplight_state = 0;
bool stoplight_flash_on = false;
unsigned long stoplight_timer = 0;

// Initialization.
void setup() {

  // Network setup.
  Serial.begin(serial_FREQ);

  wifi_manager.autoConnect(mqtt_NAME);
  
  mqtt_client.setServer(mqtt_HOST, 1883);
  mqtt_client.setCallback(mqttCallback);
  mqttConnect();

  // Stoplight setup.
  pinMode(stoplight_RED_PIN, OUTPUT);
  pinMode(stoplight_YELLOW_PIN, OUTPUT);
  pinMode(stoplight_GREEN_PIN, OUTPUT);
}

// Main.
void loop() {

  // Network. Reconnect MQTT, if needed.
  while (!mqtt_client.connected()) {
    mqttConnect();
  }

  // Network. Check for MQTT messages.
  mqtt_client.loop();

  // Battery. Only perform the following functions if power save is off.
  if (pwrsv_state == false) {
  
    // Stoplight. Update light that is displayed.
    if (millis() > stoplight_timer) {
      stoplightUpdate();
      stoplight_timer = timerFetch(stoplight_DELAY);
    }

  }

}

// Stoplight function. Update the current light.
void stoplightUpdate() {

  // Turn all lights off.
  digitalWrite(stoplight_RED_PIN, LOW);
  digitalWrite(stoplight_YELLOW_PIN, LOW);
  digitalWrite(stoplight_GREEN_PIN, LOW);

  // Turn on specified light.
  if (stoplight_state == -1) {
    if (stoplight_flash_on) {
      digitalWrite(stoplight_RED_PIN, HIGH);
      stoplight_flash_on = false;
    }
    else {
      stoplight_flash_on = true;
    }
  }
  else if (stoplight_state == 0) {
    digitalWrite(stoplight_RED_PIN, HIGH);
  }
  else if (stoplight_state == 1) {
    digitalWrite(stoplight_YELLOW_PIN, HIGH);
  }
  else if (stoplight_state == 2) {
    digitalWrite(stoplight_GREEN_PIN, HIGH);
  }

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

  // pwrsv_state
  if (topic_name.indexOf(pwrsv_CHANNEL) >= 0) {
    if (strcmp((char*)payload, "0") == 0) {
      pwrsv_state = false;
    }
    else if (strcmp((char*)payload, "1") == 0) {
      pwrsv_state = true;
      stoplight_state = -2;
      stoplightUpdate();
    }
  }

  // stoplight_state
  else if (topic_name.indexOf(stoplight_CHANNEL) >= 0) {
    if (strcmp((char*)payload, "flash") == 0) {
      stoplight_state = -1;
    }
    else if (strcmp((char*)payload, "red") == 0) {
      stoplight_state = 0;
    }
    else if (strcmp((char*)payload, "yellow") == 0) {
      stoplight_state = 1;
    }
    else if (strcmp((char*)payload, "green") == 0) {
      stoplight_state = 2;
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
  mqtt_client.subscribe(pwrsv_CHANNEL);
  mqtt_client.subscribe(stoplight_CHANNEL);
  
}

// System function. Create timer value the specified number of millis in the future.
int timerFetch(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}
