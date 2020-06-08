#!/bin/bash
# Copyright (C) 2018, Manjot Sidhu <manjot.gni@gmail.com>
# Copyright (C) 2018, PitchBlack Recovery Project <pitchblacktwrp@gmail.com>
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
pb_sticker="CAACAgUAAx0CTgmBKwACAyde3OvBCdhSaw92OKfd-pl-LxNM3wACAQADRAdYGB8AAUtGlOKw8RoE"
TWRP_V=$(cat $(pwd)/bootable/recovery/variables.h | grep TW_MAIN_VERSION_STR | awk '{print $3}' | head -1)
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

sf_file=$(find $(pwd)/out/target/product/$codename/PitchBlack*-OFFICIAL.zip 2>/dev/null)
zipcounter=$(find $(pwd)/out/target/product/$codename/PitchBlack*-OFFICIAL.zip 2>/dev/null | wc -l)

if [[ "$zipcounter" > "0" ]]; then

  if [[ "$zipcounter" > "1" ]]; then
    echo
    printf "${red}More than one zips dected! Remove old build...\n${nocol}"
    echo

else

export ZIP_NAME=$sf_file;

pbv=$(echo "$sf_file" | awk -F'[-]' '{print $3}')
build=$(echo "$sf_file" | awk -F'[-]' '{print $4}')
build_with_time="$(echo "$sf_file" | awk -F'[-]' '{print $4}')-$(echo "$sf_file" | awk -F'[-]' '{print $5}')"

echo
echo "Build detected for :" $codename
echo "PitchBlack version :" $pbv
echo "Build date :" $build
echo "Build location :" $sf_file
echo
printf "${green}Build successfully detected!\n${nocol}"
echo
MD5=$(md5sum $sf_file | awk '{print $1}')
echo "Please Wait"
echo "exit" | sshpass -p "$sf_pwd" ssh -tto StrictHostKeyChecking=no $sf_usr@shell.sourceforge.net create
if rsync -v --rsh="sshpass -p $sf_pwd ssh -l $sf_usr" $sf_file $sf_usr@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$codename/
then
	echo -e "${green} UPLOADED TO SOURCEFORGE SUCCESSFULLY\n${nocol}"
	cd $(pwd)/vendor/pb;
	java -jar Release.jar $codename $build_with_time
	git add pb.releases
	git commit --author "PitchBlack-BOT <pitchblackrecovery@gmail.com>" -m "pb.releases: new release $codename-$build"
	git push -q https://${github_token}@github.com/PitchBlackRecoveryProject/vendor_pb pb
	link="https://sourceforge.net/projects/pitchblack-twrp/files/${NAME}/$(echo $sf_file | awk -F'[/]' '{print $NF}')"
	FORMAT="PitchBlack Recovery for $TARGET_VENDOR $TARGET_DEVICE (\`${NAME}\`)\n\nInfo\n\n"
	FORMAT=${FORMAT}"PitchBlack V${pbv} Official\nBased on TWRP ${TWRP_V}\n"
	FORMAT=${FORMAT}"*Build Date*: \`${build:0:4}/${build:4:2}/${build:6}\`\n\n"
	FORMAT=${FORMAT}"*Maintainer*: ${maintainer}\n"
	if [[ ! -z $CHANGELOG ]]; then
		FORMAT=${FORMAT}"\n*Changelog*:\n"${CHANGELOG}"\n"
	fi
	FORMAT=${FORMAT}"\n*MD5*: \`$MD5\`\n\n*Download*: [Link]($link)\n\nChannel: @pbtwrp\nchat: @pbrpcom"
	python3 telegram.py -c @pbtwrp -M "$FORMAT"
	python3 telegram.py -c @pbtwrp -S "$pb_sticker"
	cd ../../
else
	echo -e "${red} FAILED TO UPLOAD TO SOURCEFORGE\n${nocol}"
fi
fi
else
    echo
    printf "${red}No build found\n${nocol}"
    echo
fi
