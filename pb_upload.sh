#!/bin/bash
# Copyright (C) 2018, Manjot Sidhu <manjot.gni@gmail.com>
# Copyright (C) 2018, PitchBlackTWRP <pitchblacktwrp@gmail.com>  
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

read -s -p "Enter File Location to upload:" sf_file
read -s -p "Enter Location where to push the file" sf_dir
read -s -p "Enter SourceForge Server Username:" sf_usr
read -s -p "Enter SourceForge Server Password:" sf_psd
echo "exit" | sshpass -p "$sf_psd" ssh -tto StrictHostKeyChecking=no $sf_usr@shell.sourceforge.net create
echo -e "$cyan****************************************************************************************$nocol"
if rsync -v --rsh="sshpass -p $sf_psd ssh -l $sf_usr" $sf_file $sf_usr@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$sf_dir/
then
echo -e "$green UPLOADED TO SOURCEFORGE SUCCESSFULLY$nocol"
else
echo -e "$red FAILED TO UPLOAD TO SOURCEFORGE$nocol"
fi
echo -e "$cyan****************************************************************************************$nocol"
