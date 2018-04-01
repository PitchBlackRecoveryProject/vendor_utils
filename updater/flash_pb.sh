#!/sbin/sh
# set up extracted files and directories
PB=/tmp/pb/PBTWRP
IMG=/tmp/pb/TWRP/recovery.img
ETC=/system/etc/install-recovery.sh
PB1_PATH=/sdcard/Android/PBTWRP
PB2_PATH=/sdcard/TWRP/PBTWRP
UI=/sdcard/TWRP/theme/ui.zip
RES=/sdcard/TWRP/.twrps
red='\033[0;31m'
RECOVERY=/dev/recovery

recovery_partition() {
	chk_syml() {
		RECOVERY=$(readlink -f "$RECOVERY")
		# symlink
		if [ -f "$RECOVERY" ]; then
			DD=true
		elif [ -b "$RECOVERY" ]; then
			case "$RECOVERY" in
				/dev/block/bml*|/dev/block/mtd*|/dev/block/mmc*)
					DD=false ;;
				*)
					DD=true ;;
			esac
		# otherwise we have to keep trying other locations
		else
			return 1
		fi
		echo "- Found recovery partition at: $RECOVERY"
	}
	# if we already have recovery block set then verify and use it
	if [-z [ "$RECOVERY" ] && chk_syml && return]; then
	# otherwise, time to go hunting!
	if [ -f /etc/recovery.fstab ]; then
		# recovery fstab v1
		RECOVERY=$(awk '$1 == "/recovery" {print $3}' /etc/recovery.fstab)
		[ "$RECOVERY" ] && chk_syml && return
		# recovery fstab v2
		RECOVERY=$(awk '$2 == "/recovery" {print $1}' /etc/recovery.fstab)
		[ "$RECOVERY" ] && chk_syml && return
	fi
	for fstab in /fstab.*; do
		[ -f "$fstab" ] || continue
		# device fstab v2
		RECOVERY=$(awk '$2 == "/recovery" {print $1}' "$fstab")
		[ "$RECOVERY" ] && chk_syml && return
		# device fstab v1
		RECOVERY=$(awk '$1 == "/recovery" {print $3}' "$fstab")
		[ "$RECOVERY" ] && chk_syml && return
	done
	if [ -f /proc/emmc ]; then
		# emmc layout
		RECOVERY=$(awk '$4 == "\"recovery\"" {print $1}' /proc/emmc)
		[ "$RECOVERY" ] && RECOVERY=/dev/block/$(echo "$RECOVERY" | cut -f1 -d:) && chk_syml && return
	fi
	if [ -f /proc/mtd ]; then
		# mtd layout
		RECOVERY=$(awk '$4 == "\"recovery\"" {print $1}' /proc/mtd)
		[ "$RECOVERY" ] && RECOVERY=/dev/block/$(echo "$RECOVERY" | cut -f1 -d:) && chk_syml && return
	fi
	if [ -f /proc/dumchar_info ]; then
		# mtk layout
		RECOVERY=$(awk '$1 == "/recovery" {print $5}' /proc/dumchar_info)
		[ "$RECOVERY" ] && chk_syml && return
	fi
	if [ -z "`echo $RECOVERY | grep "recovery"`" ]; then
	echo "$red Failed to Find RECOVERY Partition";
	exit 1;
	fi
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
if $DD; then
dd if=$IMG of="$RECOVERY"
else
flash_image $RECOVERY $IMG
fi

#Copy Specific Files
cp -r $PB/* /sdcard/TWRP/PBTWRP/

