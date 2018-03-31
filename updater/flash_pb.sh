#!/sbin/sh
# set up extracted files and directories
PB=/tmp/pb/PBTWRP
IMG=/tmp/pb/TWRP/recovery.img
RECOVERY=/dev/block/bootdevice/by-name/recovery
ETC=/system/etc/install-recovery.sh
PB1_PATH=/sdcard/Android/PBTWRP
PB2_PATH=/sdcard/TWRP/PBTWRP
UI=/sdcard/TWRP/theme/ui.zip
RES=/sdcard/TWRP/.twrps

#Deletion

if [ -f $ETC ]; then
	rm /system/etc/install-recovery.sh
fi
if [ -f $PB1_PATH ]; then
	rm -rf /sdcard/Android/PBTWRP
fi
if [ -f $PB2_PATH ]; then
	rm -rf /sdcard/TWRP/PBTWRP
fi
if [ -f $UI ]; then
	rm /sdcard/TWRP/theme/ui.zip
fi
if [ -f $RES ]; then
	rm -rf /sdcard/TWRP/.twrps
fi

#Flashing
flash_image $RECOVERY $IMG

#Copy Specific Files
cp -r $PB/* /sdcard/TWRP/PBTWRP/
