#!/bin/bash
echo
echo "==========="
echo "INV CONTROL"
echo "==========="
echo

# make sure the currently used power (in Watt) is provided as input variable or set it to 'off' or 'on' to switch the inverter off/on
if [[ -z $1 ]]; then
	echo "usage: invctrl.sh <current-power-consumption|off|on>"; exit 1
fi

#############
# Variables #
#############


# maximum power output of inverter in Watt (note: inverter can be set to 600W, 750W or 1000W by a register)
# important to specify to get the correct percentage for output change
export OUTPUT_MAX=750

read_output_limit ()
{
	# current output limit in %
	# do until we get a valid value, i is counter and when >5 exit (inverter goes off during the night if not on battery power)
	i=0
	while ! [[ ${OUTPUT_CURR} == ?(-)+([0-9]) ]]
	do
		export OUTPUT_CURR=$(curl -s -d 'reg=03&val=&type=16b&operation=R&registerType=H' http://192.168.74.6/postCommunicationModbus_p | awk '{ print $8 }')
		echo "reading current output limit..."
		i=$(expr $i + 1); if [[ $i -gt 5 ]]; then echo "got no value - inverter probably offline"; logger "invctrl executed with value ${1}W - no reply from inverter (probably offline)"; exit 1; fi
	done
}
# define and initialize vars
# inverter IP Address
export INVERTER_IP_ADDRESS="192.168.74.6"

# inverter output to set in %
export OUTPUT_SET=100

# increase or decrease inverter output (informational)
export OPERATION="none"

# currently used power in watt (input variable)
export POWER_CURR=$1

# factor for reducing or increasing inverter output (how many percent up or down)
export OUTPUT_FACTOR=2

# function to disable inverter e.g. when battery is low
disable_inv ()
{
	RET=$(curl -s -d 'reg=0&val='0'&type=16b&operation=W&registerType=H' http://${INVERTER_IP_ADDRESS}/postCommunicationModbus_p | awk '{ print $9 }' | sed 's/!//')
        echo "switched off"
	echo
	logger "invctrl executed - set inverter off"
}

# function to enable inverter e.g. when battery is fully charged again
enable_inv ()
{
	RET=$(curl -s -d 'reg=0&val='1'&type=16b&operation=W&registerType=H' http://192.168.74.6/postCommunicationModbus_p | awk '{ print $9 }' | sed 's/!//')
        echo "switched on"
	echo
	logger "invctrl executed - set inverter on"
}

# function calculates the value in % to de- or increse from current output related to the maximum output of inverter
calc_factor ()
{
	OUTPUT_FACTOR=$(expr 100 \* ${POWER_CURR} / ${OUTPUT_MAX})
}

# function to set operation increase or decrease power depending of injection (negative) or consumption (positive) of energy
set_operation ()
{
        if [ ${POWER_CURR} -lt 0 ]; then
	       	OPERATION="decrease"
       	else
		OPERATION="increase"
	fi
}

# function to set new output limit after calculation - check final setting if in rage between 2 & 100
set_output_limit ()
{
	OUTPUT_SET=$(expr ${OUTPUT_CURR} + ${OUTPUT_FACTOR})
	if [ ${OUTPUT_SET} -lt 2 ]; then
		OUTPUT_SET=2
	elif [ ${OUTPUT_SET} -gt 100 ]; then
		OUTPUT_SET=100
	fi
	while ! [[ ${RET} == ?(-)+([0-9]) ]]
	do
		RET=$(curl -s -d 'reg=03&val='$OUTPUT_SET'&type=16b&operation=W&registerType=H' http://192.168.74.6/postCommunicationModbus_p | awk '{ print $9 }' | sed 's/!//')
		echo "setting new output limit..."
		logger "invctrl executed - set inverter output limit: ${OUTPUT_SET}%"
	done
}

# call functions
#first check if inverter should be switched off or on - exit if done
if [ $1 == 'off' ];
then
	disable_inv && exit 0 
elif [ $1 == 'on' ];
then
        enable_inv && exit 0
fi
read_output_limit
calc_factor
set_operation
set_output_limit

# info output to console
echo
echo "current output limit:          ${OUTPUT_CURR}%"
echo "current Powerconsumption:      ${POWER_CURR}W"
echo "Operation is:                  ${OPERATION}"
echo "Factor to change output limit: ${OUTPUT_FACTOR}"
echo "new output limit:              ${OUTPUT_SET}%"
echo
