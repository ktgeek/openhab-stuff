Configuring Hiome with OpenHAB
==============================

Hiome Door is a small sensor for your door, a giant leap for your
automations. It knows exactly how many people are in each room, even
if you haven't moved for hours. Your lights stay on while you're in
the room, and immediately turn off when you leave. No more waving your
arms around in the dark.

## Configuring the Hiome MQTT Broker
1. Install the MQTT Binding.  
(Do not install the built-in mosquitto server as Hiome provides its own MQTT Server.)
2. In Inbox in PaperUI manually add an MQTT Broker. You will need to provide the hostname/ipaddress of the Hiome hub.  
Do not turn on TLS/SSL.

## Configuring a room occupancy tracker Thing
1. Visit the Hiome API to get a list of the configured rooms and their IDs. (Most likely http://hiome.local/api/1/rooms is the address.)
2. Ensure you have the JSONPath Transformation installed.
3. In Inbox in PaperUI manually add a Generic MQTT Thing and select the Hiome MQTT Broker as the bridge.
4. In the Generic MQTT Thing you created click the `+` button to add a channel
5. For "Channel Type" select `Number`
6. Provide a unique to your open hab Channel Id (if this is your first channel, you can just use 1.)
7. Under MQTT state topic you will need to provide the MQTT path to the Hiome. `hiome/1/sensor/<room_id>:occupancy` substituting the room ID you found in step 1.
8. Set "Absolute Minimum" to `0`
9. Open the "Show More" and put `JSONPATH:$.val` in Incoming value transformations.

## Configuring a door contact Thing
1. Ensure you have the JSONPath Transformation installed.
2. In Inbox in PaperUI manually add a Generic MQTT Thing and select the Hiome MQTT Broker as the bridge.
3. In the Generic MQTT Thing you created click the `+` button to add a channel
4. For "Channel Type" select `Contact`
5. Provide a unique to your open hab Channel Id (if this is your first channel, you can just use 1.)
6. Under MQTT state topic you will need to provide the MQTT path to the Hiome. `hiome/1/sensor/<sensor_id>`. The sensor id can be found on a sticker on top of your Hiome sensor.
7. Set "Custom On/Open value" to "1"
8. Set "Custom Off/Closed value" to "0"
9. Open the "Show More" and put `JSONPATH:$.val` in Incoming value transformations.
