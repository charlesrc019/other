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
#include <NewPing.h>

// Global varibles: network.
const char* mqtt_HOST = "";
const char* mqtt_NAME = "home/garage/port1/car_position";
const int serial_FREQ = 115200;
const int net_DELAY = 5000;
WiFiClient wifi_client;
WiFiManager wifi_manager;
PubSubClient mqtt_client(wifi_client);
unsigned long mqtt_timer = 0;

// Global variables: battery.
const char* pwrsv_CHANNEL = "home/garage/port1/door";
bool pwrsv_state = false;

// Global varibles: measurements.
const int measure_TRIG_PIN = 13;
const int measure_ECHO_PIN = 15;
const int measure_DELAY = 750;
const int measure_BACKcm = 10;
const int measure_STOPcm = 20;
const int measure_SLOWcm = 30;
NewPing measure_sonar(measure_TRIG_PIN, measure_ECHO_PIN, 500);
char* measure_state = "red";
unsigned long measure_timer = 0;

// Initialization.
void setup() {

  // Network setup.
  Serial.begin(serial_FREQ);

  wifi_manager.autoConnect(mqtt_NAME);
  
  mqtt_client.setServer(mqtt_HOST, 1883);
  mqtt_client.setCallback(mqttCallback);
  mqttConnect();

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
  
    // Network. Publish periodric MQTT info.
    if (millis() > mqtt_timer) {
      mqttPublish();
      mqtt_timer = timerFetch(net_DELAY);
    }
  
    // Measure. Update the car position measurement.
    if (millis() > measure_timer) {
      measureUpdate();
      measure_timer = timerFetch(measure_DELAY);
    }

  }

}

// Measure function. Update the current measurement.
void measureUpdate() {

  // Get new sonar distance.
  int distance = 0;
  do {
    distance = measure_sonar.ping_cm();
  } while (distance == 0);

  // Determine new state from distance.
  char* state = "";
  if (distance < measure_BACKcm) {
    state = "flash";
  }
  else if (distance < measure_STOPcm) {
    state = "red";
  }
  else if (distance < measure_SLOWcm) {
    state = "yellow";
  }
  else {
    state = "green";
  }

  // Update state, if different.
  if (strcmp(state, measure_state) != 0) {
    measure_state = state;
    mqttPublish();

    // Print state change to serial.
    Serial.print("Measure: ");
    Serial.println(state);
  }
  
}

// Network function. Publish a brief update of relevant state information.
void mqttPublish() {

  // measure_state
  mqtt_client.publish(mqtt_NAME, measure_state);
  
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

  // pwrsv_state
  if (topic_name.indexOf(pwrsv_CHANNEL) >= 0) {
    if ((char)payload[0] == '0') {
      pwrsv_state = false;
    }
    else if ((char)payload[0] == '1') {
      pwrsv_state = true;
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
  
}

// System function. Create timer value the specified number of millis in the future.
int timerFetch(int millisecs) {
  if ( (millis() + millisecs) > 4294967294 )
    return millisecs - (4294967294-millis());
  else
    return millisecs + millis();
}
