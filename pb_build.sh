#!/bin/bash
# Copyright (C) 2018-2020, Mohd Faraz <mohd.faraz.abc@gmail.com>
# PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
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
DATE=$(date +%Y%m%d-%H%M)
VERSION=$(cat $(pwd)/bootable/recovery/variables.h | egrep "define\s+PB_MAIN_VERSION" | awk '{print $3}' | tr -d '"')
PB_VENDOR=vendor/utils
PB_WORK=$OUT
PB_WORK_DIR=$OUT/zip
RECOVERY_IMG=$OUT/recovery.img
RECOVERY_RAM=$OUT/ramdisk-recovery.cpio
CURR_W=$(pwd)
cd ${OUT}/../../../../
RECOVERY_AS_BOOT="false"
RECOVERY_AS_BOOT=$BOARD_USES_RECOVERY_AS_BOOT
AB_OTA="false"
AB_OTA=$AB_OTA_UPDATER
unset BOARD_USES_RECOVERY_AS_BOOT
unset AB_OTA_UPDATER
export PB_DEVICE=$(cut -d'_' -f2-3 <<<$TARGET_PRODUCT)

function get_build_var()
{
  SOONG_BASH_UI=build/soong/soong_ui.bash
  if [ -f $SOONG_BASH_UI ]; then
    (build/soong/soong_ui.bash --dumpvar-mode $1)
    return
  fi
  (CALLED_FROM_SETUP=true BUILD_SYSTEM=build/core \
    command make --no-print-directory -f build/core/config.mk dumpvar-$1)
}

PBRP_BUILD_TYPE=UNOFFICIAL
if [ -z $BETA_BUILD ]; then
	PB_BETA=$(get_build_var BETA_BUILD)
else
	PB_BETA=${BETA_BUILD}
fi
if [ "$PB_OFFICIAL_CH" == "true" ]; then
	PBRP_BUILD_TYPE=OFFICIAL
elif [ "$PB_BETA" == "true" ]; then
	PBRP_BUILD_TYPE=BETA
else
	PBRP_BUILD_TYPE=UNOFFICIAL
fi

if [ "$PBRP_BUILD_TYPE" != "UNOFFICIAL" ]; then
	python3 $PB_VENDOR/pb_devices.py verify all $PB_DEVICE

	if [[ "$?" != "0" ]]; then
		PBRP_BUILD_TYPE=UNOFFICIAL
		echo -e "${red}Error Device is not OFFICIAL${nocol}"
		exit 1;
	fi
fi
cd $CURR_W

if [ "$PB_GO" != "true" ] && [ "$PB_VARIANT" = "default" ]; then
     ZIP_NAME=PBRP-$PB_DEVICE-$VERSION-$DATE-$PBRP_BUILD_TYPE
else 
if [ "$PB_GO" != "true" ]; then
    ZIP_NAME=PBRP-$PB_DEVICE-$VERSION-$PB_VARIANT-$DATE-$PBRP_BUILD_TYPE
else
    echo -e "${red}PitchBlack Go Variant has been depreciated and has been removed. Remove PB_GO flag to build normally.{nocol}"
    exit 1;
fi

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
cp -R "$PB_VENDOR/updater/update-binary" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
cp -R "$PB_VENDOR/updater/awk" "$PB_WORK_DIR/META-INF/"
if [[ -f "$PB_WORK/recovery/root/sbin/keycheck" ]]; then
	cp "$PB_WORK/recovery/root/sbin/keycheck" "$PB_WORK_DIR/META-INF/"
fi

if [[ "$AB_OTA" = "true" ]]; then
	sed -i "s|AB_DEVICE=false|AB_DEVICE=true|g" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
fi
if [[ "$RECOVERY_AS_BOOT" = "true" ]]; then
	sed -i "s|USES_RECOVERY_AS_BOOT=false|USES_RECOVERY_AS_BOOT=true|g" "$PB_WORK_DIR/META-INF/com/google/android/update-binary"
fi

echo -e "${cyan}**** Copying Recovery Image ****${nocol}"
mkdir -p "$PB_WORK_DIR/TWRP"

cp "$PB_VENDOR/updater/magiskboot" "$PB_WORK_DIR"
cp "$RECOVERY_IMG" "$PB_WORK_DIR/TWRP/"

echo -e "${green}**** Compressing Files into ZIP ****${nocol}"
cd $PB_WORK_DIR
zip -r ${ZIP_NAME}.zip *
BUILD_RESULT_STRING="BUILD SUCCESSFUL"
BLINKBLUE="\033[0;5;34m";
echo -e ${BLINKBLUE};
cat ${OUT}/../../../../vendor/utils/.pb.1;
echo -e "${nocol}";
echo
BUILD_END=$(date +"%s")
#DIFF=$(($BUILD_END - $BUILD_START + ( ($HOURS * 60) + ($MINS * 60) + $SECS)))
if [[ "${BUILD_RESULT_STRING}" = "BUILD SUCCESSFUL" ]]; then
mv ${PB_WORK_DIR}/${ZIP_NAME}.zip ${PB_WORK_DIR}/../${ZIP_NAME}.zip
echo -e "$cyan****************************************************************************************$nocol"
echo -e "$cyan*$nocol${green} ${BUILD_RESULT_STRING}$nocol"
echo -e "$cyan*$nocol${green} RECOVERY LOCATION: ${OUT}/recovery.img$nocol"
echo -e "$purple*$nocol${green} RECOVERY SIZE: $(ls -lh ${OUT}/recovery.img | awk '{print $5}')$nocol"
echo -e "$cyan*$nocol${green} ZIP LOCATION: ${PB_WORK}/${ZIP_NAME}.zip$nocol"
echo -e "$purple*$nocol${green} ZIP SIZE: $( du -h ${PB_WORK}/${ZIP_NAME}.zip | awk '{print $1}' )$nocol"
echo -e "$cyan****************************************************************************************$nocol"
fi
