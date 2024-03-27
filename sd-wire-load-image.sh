#!/bin/sh
#NOTE: before calling this script, ensure that your Device-Under-Test is switched OFF

SLEEPTIME=2
if [ -z "$1" ]; then
	echo "missing image file path argument!!!"
	exit 1 
fi
if [ ! -f "$1" ]; then
	echo "invalid or missing image file!"
	exit 1
fi

#check if the given file is .tar.xz/.gz/.zip compressed and healthy
IMG_COMPRESSION="none"
FILEMSG=$(file $1)
echo $FILEMSG | grep "XZ compressed data" > /dev/null
if [ $? = 0 ]; then
	echo -n "Checking xz Health  : "
	xz -t $1 1>/dev/null 2>/dev/null
	if [ $? = 0 ]; then
		echo "ok"
	else
		echo "error! exiting"
		exit 1
	fi
	IMG_COMPRESSION="xz"
fi

echo $FILEMSG | grep "gzip compressed data" > /dev/null
if [ $? = 0 ]; then
	echo -n "Checking gz Health  : "
	gzip -t $1 1>/dev/null 2>/dev/null
	if [ $? = 0 ]; then
		echo "ok"
	else
		echo "error! exiting"
		exit 1
	fi
	IMG_COMPRESSION="gz"
fi

echo $FILEMSG | grep "Zip archive data" > /dev/null
if [ $? = 0 ]; then
	echo -n "Checking zip Health : "
	unzip -t $1 1>/dev/null 2>/dev/null
	if [ $? = 0 ]; then
		echo "ok"
	else
		echo "error! exiting"
		exit 1
	fi
	IMG_COMPRESSION="zip"
fi

if [ $IMG_COMPRESSION = "none" ]; then
        echo "Unsupported file type! only .xz/.gz/.zip are supported types"
        exit 1
fi
#echo "Detected Image      : $IMG_COMPRESSION"

#detect if SDWire hw is connected
SDSERIAL=$(sd-mux-ctrl --list |tail -1 | awk '{print $6}' | sed 's/,//')
if [ -z $SDSERIAL ]; then
        echo "Unable to read SDWire's serial number! exiting..."
        exit 1
else
	echo "SDWire H/W Serial   : $SDSERIAL"
fi

#switch the sdcard from target-device to our test-server
service fstab stop
usb-port-power.sh off
sleep $SLEEPTIME
usb-port-power.sh on
sleep 5
sd-mux-ctrl --device-serial=$SDSERIAL --ts
sleep 5
service fstab boot
echo "Recycle USB port pwr: ok"

#check if /dev/sda or /dev/sdb shows up
if [ ! -b "/dev/sdb" ]; then
	if [ ! -b "/dev/sda" ]; then
		echo "none of the /dev/sda or /dev/sdb are found"
		exit 1
	fi
fi

#check if detected /dev/sdX node is really of type MMC?
SDWIRENODE="none"
if [ -b "/dev/sdb" ]; then
	MODEL=$(cat /sys/block/sdb/device/model)
	if [ "$MODEL" = "Ultra HS-SD/MMC " ]; then
		SDWIRENODE="/dev/sdb"	
	fi
fi
if [ -b "/dev/sda" ]; then
        MODEL=$(cat /sys/block/sda/device/model)
        if [ "$MODEL" = "Ultra HS-SD/MMC " ]; then
                SDWIRENODE="/dev/sda"
        fi
fi
if [ $SDWIRENODE = "none" ]; then
	echo "none of the device nodes are of type MMC"
	exit 1
fi
echo "Detect valid sdcard : ok"

#delete all partitions
dd if=/dev/zero of=$SDWIRENODE bs=512 count=1 conv=notrunc 1>/dev/null 2>/dev/null
if [ $? = 0 ]; then
	echo "Formatting disk     : ok"
else
	echo "Formatting disk     : failed"
	exit 1
fi
sync
sleep 5	

echo -n "Writing img to disk : "
#uncompress file directly to /dev/sdX node
if [ $IMG_COMPRESSION = "xz" ]; then
	xzcat $1 > $SDWIRENODE
elif [ $IMG_COMPRESSION = "gz" ]; then
	zcat $1 > $SDWIRENODE
elif [ $IMG_COMPRESSION = "zip" ]; then
	#gzip -dc $1 > $SDWIRENODE
	unzip -p $1 > $SDWIRENODE
fi
sync
echo "done"

#switch the sdcard to device-under-test
sd-mux-ctrl --device-serial=$SDSERIAL --dut
echo "result              : success"
