#!/bin/bash
# Copyright (C) 2018, Mohd Faraz <mohd.faraz.abc@gmail.com>
# Copyright (C) 2018, PitchBlackTWRP <pitchblacktwrp@gmail.com>
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
VERSION="2.7.1"
DATE=$(date -u +%Y%m%d-%H%M)
PB_VENDOR=vendor/pb
PB_WORK=$OUT
PB_WORK_DIR=$OUT/zip
RECOVERY_IMG=$OUT/recovery.img
PB_DEVICE=$(cut -d'_' -f2 <<<$TARGET_PRODUCT)
ZIP_NAME=PitchBlack-$PB_DEVICE-$VERSION-$DATE
PBTWRP_BUILD_TYPE=UNOFFICIAL

if [ "$PB_OFFICIAL_CH" != "true" ]; then
	PBTWRP_BUILD_TYPE=UNOFFICIAL
else
	PBTWRP_BUILD_TYPE=OFFICIAL
fi

function search() {
for d in $(curl -s https://raw.githubusercontent.com/PitchBlackTWRP/vendor_pb/pb/pb.devices); do
if [ "$d" == "$PB_DEVICE" ]; then
echo "$d";
break;
fi
done
}

if [ "$PBTWRP_BUILD_TYPE" != "UNOFFICIAL" ]; then
	F=$(search);
	if [[ "${F}" ]]; then
		PBTWRP_BUILD_TYPE=OFFICIAL
	else
		PBTWRP_BUILD_TYPE=UNOFFICIAL
		echo -e "${red}Error Device is not OFFICIAL${nocol}"
		exit 1;
	fi
fi

ZIP_NAME=PitchBlack-$PB_DEVICE-$VERSION-$DATE-$PBTWRP_BUILD_TYPE

echo -e "${red}**** Making Zip ****${nocol}"
if [ -d "$PB_WORK_DIR" ]; then
        rm -rf "$PB_WORK_DIR"
	rm -rf "$PB_WORK"/*.zip
fi

if [ ! -d "PB_WORK_DIR" ]; then
        mkdir "$PB_WORK_DIR"
fi

echo -e "${blue}**** Copying Tools ****${nocol}"
cp -R "$PB_VENDOR/PBTWRP" "$PB_WORK_DIR"

echo -e "${green}**** Copying Updater Scripts ****${nocol}"
mkdir -p "$PB_WORK_DIR/META-INF/com/google/android"
cp -R "$PB_VENDOR/updater/"* "$PB_WORK_DIR/META-INF/com/google/android/"

echo -e "${cyan}**** Copying Recovery Image ****${nocol}"
mkdir -p "$PB_WORK_DIR/TWRP"
cp "$RECOVERY_IMG" "$PB_WORK_DIR/TWRP/"

echo -e "${green}**** Compressing Files into ZIP ****${nocol}"
cd $PB_WORK_DIR
zip -r ${ZIP_NAME}.zip *
BUILD_RESULT_STRING="BUILD SUCCESSFUL"
echo -e ""
echo -e "${blue} __________   __    __              __     ${purple} __________   __                       __     "
echo -e "${blue} \______   \ |__| _/  |_    ____   |  |__  ${purple} \______   \ |  |   _____      ____   |  | __ "
echo -e "${blue}  |     ___/ |  | \   __\ _/ ___\  |  |  \ ${purple}  |    |  _/ |  |   \__  \   _/ ___\  |  |/ / "
echo -e "${blue}  |    |     |  |  |  |   \  \___  |   Y  \ ${purple} |    |   \ |  |__  / __ \_ \  \___  |    <  "
echo -e "${blue}  |____|     |__|  |__|    \___  > |___|  /${purple}  |______  / |____/ (____  /  \___  > |__|_ \ "
echo -e "${blue}                               \/       \/ ${purple}         \/              \/       \/       \/ "
echo -e "${green} 		___________  __      __  __________  __________"
echo -e " 		\__    ___/ /  \    /  \ \______   \ \______   \ "
echo -e " 		  |    |    \   \/\/   /  |       _/  |     ___/ "
echo -e " 		  |    |     \        /   |    |   \  |    |     "
echo -e " 		  |____|      \__/\  /    |____|_  /  |____|     "
echo -e " 		                   \/            \/              ${nocol}"
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START + ( ($HOURS * 60) + ($MINS * 60) + $SECS)))
if [[ "${BUILD_RESULT_STRING}" = "BUILD SUCCESSFUL" ]]; then
mv ${PB_WORK_DIR}/${ZIP_NAME}.zip ${PB_WORK_DIR}/../${ZIP_NAME}.zip
echo -e "$cyan****************************************************************************************$nocol"
echo -e "$cyan*$nocol${green} ${BUILD_RESULT_STRING}$nocol"
echo -e "$cyan*$nocol${yellow} Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo -e "$cyan*$nocol${green} RECOVERY LOCATION: ${OUT}/recovery.img$nocol"
echo -e "$purple*$nocol${green} RECOVERY SIZE: $( du -h ${OUT}/recovery.img | awk '{print $1}' )$nocol"
echo -e "$cyan*$nocol${green} ZIP LOCATION: ${PB_WORK}/${ZIP_NAME}.zip$nocol"
echo -e "$purple*$nocol${green} ZIP SIZE: $( du -h ${PB_WORK}/${ZIP_NAME}.zip | awk '{print $1}' )$nocol"
echo -e "$cyan****************************************************************************************$nocol"
fi
