# invctrl
This is a bash script to control the output limit of Growatt 600 TL-X Inverter. This can be  used for 'near zero' power injection to public grid. It will adapt the maximum power output of the inverter, related to current power usage by changing register 3 of the inverter. This is useful if you don't want to inject too much electric power to public grid, especially if you have a battery connected and use it during dark time.

**Use the script only on your own risk. The author will not take any responsibility for damaged/bricked devices, damages on your solar power devices and installation nor for the functionality of the script! It has been tested and is used on my own hardware without any problems.**

### Prerequisites
* 2-way electric meter (optional: just for measuring current power usage what can be done on other ways as well)
* hichi read head for meter (optional: just for measuring current power usage what can be done on other ways as well)
* Home Assistant Installation (optional: just for controlling script execution)
* Shine WiFi-X WLAN Adapter with otti firmware connected to inverter (https://github.com/otti/Growatt_ShineWiFi-S/tree/master)
