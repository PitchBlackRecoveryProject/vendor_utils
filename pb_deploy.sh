#!/bin/bash
# Copyright (C) 2018, Manjot Sidhu <manjot.gni@gmail.com>
# Copyright (C) 2018, PitchBlackTWRP <pitchblacktwrp@gmail.com>  
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
grep -R ID= /etc/os-release
if ID=arch; then
sudo pacman -S sshpass --noconfirm
elif ID=ubuntu; then
sudo apt-get install sshpass -y
fi

read -p "Enter build device codename:" codename
read -p "Enter build date(YYYYMMDD):" build
read -p "Enter location of the build to upload:" sf_file

read -p "Enter SourceForge Server Username:" sf_usr
read -s -p "Enter SourceForge Server Password:" sf_pwd
echo "Please Wait"
echo "exit" | sshpass -p "$sf_pwd" ssh -tto StrictHostKeyChecking=no $sf_usr@shell.sourceforge.net create
if rsync -v --rsh="sshpass -p $sf_pwd ssh -l $sf_usr" $sf_file $sf_usr@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$codename/
then
echo -e "$green UPLOADED TO SOURCEFORGE SUCCESSFULLY$nocol"
java -jar Release.jar $codename $build
git add pb.releases
git commit --author "PitchBlack-BOT <pitchblackrecovery@gmail.com>" -m "pb.releases: new release $codename-$build"
git push origin pb
else
echo -e "$red FAILED TO UPLOAD TO SOURCEFORGE$nocol"
fi
