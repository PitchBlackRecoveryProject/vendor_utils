#!/bin/bash
# Copyright (C) 2018, Manjot Sidhu <manjot.gni@gmail.com>
# Copyright (C) 2018, PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
#
# Custom Deploy Script for PBRP
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

codename=$1
sf_usr=$2
sf_pwd=$3
github_token=$4
version=$5
maintainer=$6

blue='\033[0;34m'
cyan='\033[0;36m'
green='\e[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
purple='\e[0;35m'
white='\e[0;37m'
pb_sticker="CgACAgUAAxkBAAEGz4JfH71DYT14IAaZ2LrTeShELhP2PgACzQADyrxgVybiOK2DvhIWGgQ"
TWRP_V=$(cat $(pwd)/bootable/recovery/variables.h | grep TW_MAIN_VERSION_STR | awk '{print $3}' | head -1)

gh="https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/latest"

# Install sshpass if not installed
chksspb=$(which sshpass 2>/dev/null)
if [[ "$chksspb" != "/usr/bin/sshpass" ]]; then
    echo
    printf "Sshpass is required but not installed!\n\nInstalling sspass...\n"
    echo
    ID_LIKE="$(cut -d'=' -f2 <<<$(grep ID_LIKE= /etc/os-release))"
    echo
        if [ "$ID_LIKE" == "arch" ]; then
            sudo pacman -S sshpass --noconfirm
        elif [ "$ID_LIKE" = "debian" ]; then
            sudo apt-get install sshpass -y
        fi
else true;
fi

echo

export NAME=$codename

sf_file=$(find $(pwd)/out/target/product/$codename/PBRP*-OFFICIAL.zip 2>/dev/null)
zipcounter=$(find $(pwd)/out/target/product/$codename/PBRP*-OFFICIAL.zip 2>/dev/null | wc -l)
file_size=$( du -h $sf_file | awk '{print $1}' )

if [[ "$zipcounter" > "0" ]]; then
	if [[ "$zipcounter" > "1" ]]; then
		printf "${red}More than one zips dected! Remove old build...\n${nocol}"
	else
		pbv=$(echo "$sf_file" | awk -F'[-]' '{print $3}')
		build=$(echo "$sf_file" | awk -F'[-]' '{print $4}')
		build_with_time="$(echo "$sf_file" | awk -F'[-]' '{print $4}')-$(echo "$sf_file" | awk -F'[-]' '{print $5}')"
		echo
		echo "Build detected for :" $codename
		echo "PitchBlack version :" $pbv
		echo "Build date         :" $build
		echo "Build location     :" $sf_file
		echo
		printf "${green}Build successfully detected!\n${nocol}"
		echo
		MD5=$(md5sum $sf_file | awk '{print $1}')
		echo "Please Wait"
		cd $(pwd)/vendor/utils;
		python3 pb_devices.py verify "$VENDOR" "$codename"
		if [[ "$?" == "0" ]]; then
			echo "exit" | sshpass -p "$sf_pwd" ssh -tto StrictHostKeyChecking=no $sf_usr@shell.sourceforge.net create
			if rsync -v --rsh="sshpass -p $sf_pwd ssh -l $sf_usr" $sf_file $sf_usr@shell.sourceforge.net:/home/frs/project/pbrp/$codename/
			then
				echo -e "${green} UPLOADED TO SOURCEFORGE SUCCESSFULLY\n${nocol}"
				link="https://sourceforge.net/projects/pbrp/files/${NAME}/$(echo $sf_file | awk -F'[/]' '{print $NF}')"
				curl -i -X POST 'https://us-central1-pbrp-prod.cloudfunctions.net/release' -H "Authorization: Bearer ${GCF_AUTH_KEY}" -H "Content-Type: application/json" --data "{\"codename\": \"$codename\", \"vendor\":\"$VENDOR\", \"md5\": \"$MD5\", \"size\": \"$file_size\", \"sf_link\": \"$link\", \"gh_link\": \"$gh\",\"version\": \"$pbv\"}"
				link="https://pitchblackrecovery.com/$(echo $codename | sed "s:_:-:g")"
				FORMAT="PitchBlack Recovery for <b>$VENDOR $TARGET_DEVICE</b> (<code>${NAME}</code>)

<b>Info</b>

PitchBlack V${pbv} Official
Based on TWRP ${TWRP_V}
<b>Build Date</b>: <code>${build:0:4}/${build:4:2}/${build:6}</code>

<b>Maintainer</b>: ${maintainer}

"
				if [[ ! -z $CHANGELOG ]]; then
					FORMAT=${FORMAT}"
<b>Changelog</b>:
"${CHANGELOG}"
"
				fi
				FORMAT=${FORMAT}"
<b>MD5</b>: <code>$MD5</code>
"
				python3 telegram.py -c @pitchblackrecovery -AN "$pb_sticker" -C "$FORMAT" -D "Download|$link" -m "HTML"
			else
				echo -e "${red} FAILED TO UPLOAD TO SOURCEFORGE\n${nocol}"
			fi
		else
			echo -e "${red} Device is not Official\n${nocol}"
		fi
		cd ../../
	fi
else
	echo
	printf "${red}No build found\n${nocol}"
	echo
fi
