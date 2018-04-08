#!/bin/bash
read -s -p "Enter SourceForge Server Password: " sf_psd
echo "exit" | sshpass -p "$sf_psd" ssh -tto StrictHostKeyChecking=no pitchblack@shell.sourceforge.net create
rsync -v --rsh="sshpass -p $sf_psd ssh -l pitchblack" ${PB_WORK}/${ZIP_NAME}.zip pitchblack@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$CURRENT_DEVICE/
