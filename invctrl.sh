#!/bin/bash
echo
echo "==========="
echo "INV CONTROL"
echo "==========="
echo

if [[ -z $1 ]]; then
	echo "usage: invctrl.sh <current-power-consumption>"; exit 1
fi

#############
# Variables #
#############


# maximum power output of inverter in Watt
export OUTPUT_MAX=750

# currently set inverter output in %
# do until we get value, i is counter and when >5 exit
i=0
while ! [[ ${OUTPUT_CURR} == ?(-)+([0-9]) ]]
do
	export OUTPUT_CURR=$(curl -s -d 'reg=03&val=&type=16b&operation=R&registerType=H' http://192.168.74.6/postCommunicationModbus_p | awk '{ print $8 }')
	echo "reading current output limit..."
	i=$(expr $i + 1); if [[ $i -gt 5 ]]; then echo "got no value - inverter probably offline"; logger "invctrl executed with value ${1}W - no reply from inverter (probably offline)"; exit 1; fi
done

# inverter output to set in %
export OUTPUT_SET=100

# increase or decrease inverter output (informational)
export OPERATION="none"

# currently used power in watt (input variable)
export POWER_CURR=$1

# factor for reducing or increasing inverter output
export OUTPUT_FACTOR=5



calc_factor ()
{
	# function calculates the value in % to de- or increse from current output related to the maximum output of inverter
	OUTPUT_FACTOR=$(expr 100 \* ${POWER_CURR} / ${OUTPUT_MAX})
}

set_operation ()
{
	# function to set increase or decrease power depending of injection (negative) or consumption (positive) of energy
        if [ ${POWER_CURR} -lt 0 ]; then
	       	OPERATION="decrease"
       	else
		OPERATION="increase"
	fi
}

set_output_limit ()
{
	# function to set output limit after calculation - check final setting if in rage between 5 & 100
	OUTPUT_SET=$(expr ${OUTPUT_CURR} + ${OUTPUT_FACTOR})
	if [ ${OUTPUT_SET} -lt 5 ]; then
		OUTPUT_SET=5
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

calc_factor
set_operation
set_output_limit

echo
echo "current output limit:          ${OUTPUT_CURR}%"
echo "current Powerconsumption:      ${POWER_CURR}W"
echo "Operation is:                  ${OPERATION}"
echo "Factor to change output limit: ${OUTPUT_FACTOR}"
echo "new output limit:              ${OUTPUT_SET}%"
echo
