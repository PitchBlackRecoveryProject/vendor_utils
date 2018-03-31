#!/sbin/sh
# set up extracted files and directories
PB=/tmp/pb/PBTWRP
IMG=/tmp/pb/TWRP/recovery.img
RECOVERY=recovery
ETC=/system/etc/install-recovery.sh
PB1_PATH=/sdcard/Android/PBTWRP
PB2_PATH=/sdcard/TWRP/PBTWRP
UI=/sdcard/TWRP/theme/ui.zip
RES=/sdcard/TWRP/.twrps
red='\033[0;31m'

recovery_partition() {
if [ -f /etc/recovery.fstab ]; then
		# recovery fstab v1
		RECOVERY=$(awk '$1 == "/recovery" {print $3}' /etc/recovery.fstab)
		if [ -z "$RECOVERY" ]; then
				# recovery fstab v2
		RECOVERY=$(awk '$2 == "/recovery" {print $1}' /etc/recovery.fstab)
		fi
	fi
	for fstab in /fstab.*; do
		[ -f "$fstab" ] || continue
		# device fstab v2
		RECOVERY=$(awk '$2 == "/recovery" {print $1}' "$fstab")
		if [ -n "$RECOVERY" ]; then
			break
		else
		# device fstab v1
		RECOVERY=$(awk '$1 == "/recovery" {print $3}' "$fstab")
		fi
		
	done
	if [ -z "`echo $RECOVERY | grep "recovery"`" ]; then
	echo "$redFailed to Fined RECOVERY Partition";
	exit 1;
	fi
}

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
recovery_partition;
flash_image $RECOVERY $IMG

#Copy Specific Files
cp -r $PB/* /sdcard/TWRP/PBTWRP/
