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
blue='\033[0;34m'
cyan='\033[0;36m'
green='\e[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
purple='\e[0;35m'
white='\e[0;37m'

# Install sshpass if not installed
chksspb=$(which sshpass 2>/dev/null)
if [[ "$chksspb" != "/usr/bin/sshpass" ]]; then
    echo
    printf "Sshpass is required but not installed!\n\nInstalling sspass...\n"
    echo
    grep -R ID_LIKE= /etc/os-release
    echo
        if ID_LIKE=arch; then
            sudo pacman -S sshpass --noconfirm
        elif ID_LIKE=debian; then
            sudo apt-get install sshpass -y
        fi
else true;
fi

echo

read -p "Enter device codename : " codename

sf_file=$(find `dirname $0`/../../out/target/product/$codename/PitchBlack*.zip 2>/dev/null)
zipcounter=$(find `dirname $0`/../../out/target/product/$codename/PitchBlack*.zip 2>/dev/null | wc -l)

if [[ "$zipcounter" > "0" ]]; then

  if [[ "$zipcounter" > "1" ]]; then
    echo
    printf "${red}More than one zips dected! Remove old build...\n${nocol}"
    echo

else

pbv=$(echo "$sf_file" | awk -F'[-]' '{print $3}')
build=$(echo "$sf_file" | awk -F'[-]' '{print $4}')

echo
echo "Build detected for :" $codename
echo "PitchBlack version :" $pbv
echo "Build date :" $build
echo "Build location :" $sf_file
echo
printf "${green}Build successfully detected!\n${nocol}"
echo
read -p "Enter SourceForge Server Username:" sf_usr
read -s -p "Enter SourceForge Server Password:" sf_pwd
echo "Please Wait"
echo "exit" | sshpass -p "$sf_pwd" ssh -tto StrictHostKeyChecking=no $sf_usr@shell.sourceforge.net create
if rsync -v --rsh="sshpass -p $sf_pwd ssh -l $sf_usr" $sf_file $sf_usr@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$codename/
then
echo -e "${green} UPLOADED TO SOURCEFORGE SUCCESSFULLY\n${nocol}"
java -jar Release.jar $codename $build
git add pb.releases
git commit --author "PitchBlack-BOT <pitchblackrecovery@gmail.com>" -m "pb.releases: new release $codename-$build"
git push origin pb
else
echo -e "${red} FAILED TO UPLOAD TO SOURCEFORGE\n${nocol}"
fi
fi
else
    echo
    printf "${red}No build found\n${nocol}"
    echo
fi
