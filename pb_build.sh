#!/bin/bash
# Copyright (C) 2018, Mohd Faraz <mohd.faraz.abc@gmail.com>
# Copyright (C) 2018, PitchBlack-Recovery <pitchblackrecovery@gmail.com>
# Copyright (C) 2018 ATG Droid  
#
# Custom build script
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it
#
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
green='\e[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
purple='\e[0;35m'
white='\e[0;37m'
VERSION="2.9.0"
DATE=$(date +%Y%m%d-%H%M)
PB_VENDOR=vendor/pb
PB_WORK=$OUT
PB_WORK_DIR=$OUT/zip
RECOVERY_IMG=$OUT/recovery.img
RECOVERY_RAM=$OUT/ramdisk-recovery.cpio
AB_OTA="false"
AB_OTA=$AB_OTA_UPDATER
unset AB_OTA_UPDATER
export PB_DEVICE=$(cut -d'_' -f2-3 <<<$TARGET_PRODUCT)
if [ "$PB_GO" != "true" ]; then
	ZIP_NAME=PitchBlack-$PB_DEVICE-$VERSION-$DATE
else
	ZIP_NAME=PitchBlack-Go-$PB_DEVICE-$VERSION-$DATE
fi
PBRP_BUILD_TYPE=UNOFFICIAL

if [ "$PB_OFFICIAL_CH" != "true" ]; then
	PBRP_BUILD_TYPE=UNOFFICIAL
else
	PBRP_BUILD_TYPE=OFFICIAL
fi

function search() {
for d in $(curl -s https://raw.githubusercontent.com/PitchBlackRecoveryProject/vendor_pb/pb/pb.devices); do
if [ "$d" == "$PB_DEVICE" ]; then
echo "$d";
break;
fi
done
}

if [ "$PBRP_BUILD_TYPE" != "UNOFFICIAL" ]; then
	F=$(search);
	if [[ "${F}" ]]; then
		PBRP_BUILD_TYPE=OFFICIAL
	else
		PBRP_BUILD_TYPE=UNOFFICIAL
		echo -e "${red}Error Device is not OFFICIAL${nocol}"
		exit 1;
	fi
fi

ZIP_NAME=PitchBlack-$PB_DEVICE-$VERSION-$DATE-$PBRP_BUILD_TYPE

echo -e "${red}**** Making Zip ****${nocol}"
if [ -d "$PB_WORK_DIR" ]; then
        rm -rf "$PB_WORK_DIR"
	rm -rf "$PB_WORK"/*.zip
fi

if [ ! -d "PB_WORK_DIR" ]; then
        mkdir "$PB_WORK_DIR"
fi

echo -e "${blue}**** Copying Tools ****${nocol}"
cp -R "$PB_VENDOR/PBRP" "$PB_WORK_DIR"

echo -e "${green}**** Copying Updater Scripts ****${nocol}"
mkdir -p "$PB_WORK_DIR/META-INF/com/google/android"
cp -R "$PB_VENDOR/updater/update-script" "$PB_WORK_DIR/META-INF/com/google/android/"
if [[ "$PB_FORCE_DD_FLASH" = "true" ]]; then
	cp -R "$PB_VENDOR/updater/update-binary-dd" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
else
	cp -R "$PB_VENDOR/updater/update-binary" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
fi
cp -R "$PB_VENDOR/updater/awk" "$PB_WORK_DIR/META-INF/"

if [[ "$AB_OTA" = "true" ]]; then
	sed -i "s|AB_DEVICE=false|AB_DEVICE=true|g" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
fi


echo -e "${cyan}**** Copying Recovery Image ****${nocol}"
mkdir -p "$PB_WORK_DIR/TWRP"

if [[ "$AB_OTA" = "true" ]]; then
	cp "$RECOVERY_RAM" "$PB_WORK_DIR/TWRP/"
	cp "$PB_VENDOR/updater/magiskboot" "$PB_WORK_DIR"
else
	cp "$RECOVERY_IMG" "$PB_WORK_DIR/TWRP/"
fi

echo -e "${green}**** Compressing Files into ZIP ****${nocol}"
cd $PB_WORK_DIR
zip -r ${ZIP_NAME}.zip *
BUILD_RESULT_STRING="BUILD SUCCESSFUL"
echo
echo -e "${red} ██████╗ ██╗████████╗ ██████╗██╗  ██╗ ${white} ██████╗ ██╗      █████╗  ██████╗██╗  ██╗ "
echo -e "${red} ██╔══██╗██║╚══██╔══╝██╔════╝██║  ██║ ${white} ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝ "
echo -e "${red} ██████╔╝██║   ██║   ██║     ███████║ ${white} ██████╔╝██║     ███████║██║     █████╔╝  "
echo -e "${red} ██╔═══╝ ██║   ██║   ██║     ██╔══██║ ${white} ██╔══██╗██║     ██╔══██║██║     ██╔═██╗  "
echo -e "${red} ██║     ██║   ██║   ╚██████╗██║  ██║ ${white} ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗ "
echo -e "${red} ╚═╝     ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝ ${white} ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝ "
echo                                                                               
echo -e "${cyan}     ██████╗ ███████╗ ██████╗ ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗      "        
echo -e "${cyan}     ██╔══██╗██╔════╝██╔════╝██╔═══██╗██║   ██║██╔════╝██╔══██╗╚██╗ ██╔╝      "       
echo -e "${cyan}     ██████╔╝█████╗  ██║     ██║   ██║██║   ██║█████╗  ██████╔╝ ╚████╔╝       "       
echo -e "${cyan}     ██╔══██╗██╔══╝  ██║     ██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗  ╚██╔╝        "        
echo -e "${cyan}     ██║  ██║███████╗╚██████╗╚██████╔╝ ╚████╔╝ ███████╗██║  ██║   ██║         "        
echo -e "${cyan}     ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝   ╚═╝ ${nocol}"
echo
BUILD_END=$(date +"%s")
#DIFF=$(($BUILD_END - $BUILD_START + ( ($HOURS * 60) + ($MINS * 60) + $SECS)))
if [[ "${BUILD_RESULT_STRING}" = "BUILD SUCCESSFUL" ]]; then
mv ${PB_WORK_DIR}/${ZIP_NAME}.zip ${PB_WORK_DIR}/../${ZIP_NAME}.zip
echo -e "$cyan****************************************************************************************$nocol"
echo -e "$cyan*$nocol${green} ${BUILD_RESULT_STRING}$nocol"
echo -e "$cyan*$nocol${green} RECOVERY LOCATION: ${OUT}/recovery.img$nocol"
echo -e "$purple*$nocol${green} RECOVERY SIZE: $( du -h ${OUT}/recovery.img | awk '{print $1}' )$nocol"
echo -e "$cyan*$nocol${green} ZIP LOCATION: ${PB_WORK}/${ZIP_NAME}.zip$nocol"
echo -e "$purple*$nocol${green} ZIP SIZE: $( du -h ${PB_WORK}/${ZIP_NAME}.zip | awk '{print $1}' )$nocol"
echo -e "$cyan****************************************************************************************$nocol"
fi
