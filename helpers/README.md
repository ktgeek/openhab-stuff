# OpenHAB helper scripts

## mqtt_thing_generator

Aimed at devices who are exposed via mqtt as by [zwave-js-ui](https://zwave-js.github.io/zwave-js-ui/) or
[zigbee2mqtt](https://www.zigbee2mqtt.io/). This script generates OpenHAB things from yaml templates. It uses erb to
process the files in the _templates_ directory. It's a simple way to generate a lot of things quickly.  Once generated parts or all of the yaml can be copied into the OpenHAB UI code section for a Thing.
