#!/bin/bash
if [ "$PBTWRP_BUILD_TYPE" == "OFFICIAL" ]; then
read -s -p "Enter SourceForge Server Password: " sf_psd
echo "exit" | sshpass -p "$sf_psd" ssh -tto StrictHostKeyChecking=no pitchblack@shell.sourceforge.net create
echo -e "$cyan****************************************************************************************$nocol"
if rsync -v --rsh="sshpass -p $sf_psd ssh -l pitchblack" ${PB_WORK}/${ZIP_NAME}.zip pitchblack@shell.sourceforge.net:/home/frs/project/pitchblack-twrp/$CURRENT_DEVICE/
then
echo -e "$green BUILD UPLOADED TO SOURCEFORGE SUCCESSFULLY$nocol"
else
echo -e "$red FAILED TO UPLOAD BUILD TO SOURCEFORGE$nocol"
fi
echo -e "$cyan****************************************************************************************$nocol"
fi
