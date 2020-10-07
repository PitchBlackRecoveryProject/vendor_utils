#!/bin/bash
#
# Custom Deploy Script for PBRP
#
# Copyright (C) 2019 - 2020, Manjot Sidhu <manjot.techie@gmail.com>
#							 Rokib Hasan Sagar <rokibhasansagar2014@outlook.com>
#							 Mohd Faraz <mohd.faraz.abc@gmail.com>
# 					 		 PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
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
# Required Arguments: BUILD_TYPE(OFFICIAL/BETA/TEST)
DEPLOY_TYPE=$1

blue='\033[0;34m'
cyan='\033[0;36m'
green='\e[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
purple='\e[0;35m'
white='\e[0;37m'

UPLOAD_PATH=$(pwd)/out/target/product/${CODENAME}/upload/
TWRP_V=$(cat $(pwd)/bootable/recovery/variables.h | grep TW_MAIN_VERSION_STR | awk '{print $3}' | head -1)

pb_sticker="https://thumbs.gfycat.com/NauticalMellowAlpineroadguidetigerbeetle-mobile.mp4"


# Validate and Prepare for deploy
if [[ "$DEPLOY_TYPE" == "OFFICIAL" ]]; then
	# Official Deploy = SF + GHR + WP + TG (Main Channel)

	DEPLOY_TYPE_NAME="Official"
	RELEASE_TAG={VERSION}
	BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PBRP*-OFFICIAL.zip 2>/dev/null)

elif [[ "$DEPLOY_TYPE" == "BETA" ]]; then
	# Beta Deploy = SF + GHR + WP + TG (Beta Group)

	DEPLOY_TYPE_NAME="Beta"
	RELEASE_TAG={VERSION}-beta
	BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PBRP*-UNOFFICIAL.zip 2>/dev/null)

elif [[ "$DEPLOY_TYPE" == "TEST" ]]; then
	# Test Deploy = GHR + TG (Device Maintainers Chat)

	DEPLOY_TYPE_NAME="Test"
	RELEASE_TAG={VERSION}-test
	BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PBRP*-UNOFFICIAL.zip 2>/dev/null)

else
	echo -e "Wrong Arguments Given, Required Arguments: BUILD_TYPE(OFFICIAL/BETA/TEST)" && exit 1
fi

# Common Props
BUILD_IMG=$(find $(pwd)/out/target/product/${CODENAME}/recovery.img 2>/dev/null)
MD5=$(md5sum $BUILDFILE | awk '{print $1}')
FILE_SIZE=$( du -h $BUILDFILE | awk '{print $1}' )
BUILD_DATE=$(echo "$BUILDFILE" | awk -F'[-]' '{print $4}')
BUILD_DATETIME="$(echo "$BUILDFILE" | awk -F'[-]' '{print $4}')-$(echo "$BUILDFILE" | awk -F'[-]' '{print $5}')"


# Release Links
gh_link="https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/latest"
sf_link="https://sourceforge.net/projects/pbrp/files/${CODENAME}/$(echo $BUILDFILE | awk -F'[/]' '{print $NF}')"
wp_link="https://pitchblackrecovery.com/$(echo $CODENAME | sed "s:_:-:g")"


# Deploy on SourceForge
function sf_deploy() {
	echo -e "${green}Deploying on SourceForge!\n${nocol}"
	
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

	# Don't know why :/
	export NAME=$CODENAME

	# SF Details
	echo
	echo "Build detected for :" $CODENAME
	echo "PitchBlack version :" $pbv
	echo "Build Date         :" $BUILD_DATE
	echo "Build Location     :" $BUILDFILE
	echo "MD5                :" $MD5
	echo
	
	cd $(pwd)/vendor/utils;

	# Check for Official
	python3 pb_devices.py verify "$VENDOR" "$CODENAME"
	if [[ "$?" == "0" ]]; then
		echo "exit" | sshpass -p "${SFPassword}" ssh -tto StrictHostKeyChecking=no ${SFUserName}@shell.sourceforge.net create
		if rsync -v --rsh="sshpass -p ${SFPassword} ssh -l ${SFUserName}" $BUILDFILE ${SFUserName}@shell.sourceforge.net:/home/frs/project/pbrp/$CODENAME/
		then
			echo -e "${green} Deployed On SOURCEFORGE SUCCESSFULLY\n${nocol}"
			cd ../../
			return 0
		else
			echo -e "${red} FAILED TO UPLOAD TO SOURCEFORGE\n${nocol}"
			cd ../../
			return 1
		fi
	else
		echo -e "${red} Device is not Official\n${nocol}"
		cd ../../
		return 2
	fi
}

# Deploy on GitHub Releases
function gh_deploy() {

	# Prepare Upload directory for Github Releases
	mkdir ${UPLOAD_PATH}

	# Copy Required Files
	cp $BUILDFILE $UPLOAD_PATH
	cp $BUILD_IMG $UPLOAD_PATH

	# If Samsung's Odin TAR available, copy it to our upload dir
	BUILD_FILE_TAR=$(find $(pwd)/out/target/product/${CODENAME}/*.tar 2>/dev/null)
	if [[ ! -z ${BUILD_FILE_TAR} ]]; then
	    echo "Samsung's Odin Tar available: $BUILD_FILE_TAR"
	    cp ${BUILD_FILE_TAR} ${UPLOAD_PATH}
	fi

	# Final Release
	ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "$(echo $DEPLOY_TYPE_NAME) Release for $(echo $CODENAME)" -b "PBRP $(echo $RELEASE_TAG)" -c ${CIRCLE_SHA1} -delete ${RELEASE_TAG} ${UPLOAD_PATH}
	return $?
}


# Deploy Official Build on Official Telegram Channel
function tg_official_deploy() {
	echo -e "${green}Deploying to Telegram!\n${nocol}"

	FORMAT="PitchBlack Recovery for <b>$TARGET_DEVICE</b> (<code>${NAME}</code>)\n\n<b>Info</b>\n\nPitchBlack V${VERSION} ${DEPLOY_TYPE_NAME}\nBased on TWRP ${TWRP_V}\n<b>Build Date</b>: <code>${BUILD_DATE:0:4}/${BUILD_DATE:4:2}/${BUILD_DATE:6}</code>\n\n<b>Maintainer</b>: ${maintainer}\n"
	if [[ ! -z $CHANGELOG ]]; then
		FORMAT=${FORMAT}"\n<b>Changelog</b>:\n"${CHANGELOG}"\n"
	fi
	FORMAT=${FORMAT}"\n<b>MD5</b>: <code>$MD5</code>\n"
	python3 vendor/utils/scripts/telegram.py -c @pitchblackrecovery -AN "$pb_sticker" -C "$FORMAT" -D "Download|$link" -m "HTML"	

	echo -e "${green}Deployed to Telegram SUCCESSFULLY!\n${nocol}"
	return 0
}


# Deploy Beta Build on Official PBRP Testing Group
function tg_beta_deploy() {
	echo -e "${green}Deploying to Telegram!\n${nocol}"

	FORMAT="PitchBlack Recovery for <b>$TARGET_DEVICE</b> (<code>${NAME}</code>)\n\n<b>Info</b>\n\nPitchBlack V${VERSION} ${DEPLOY_TYPE_NAME}\nBased on TWRP ${TWRP_V}\n<b>Build Date</b>: <code>${BUILD_DATE:0:4}/${BUILD_DATE:4:2}/${BUILD_DATE:6}</code>\n\n<b>Maintainer</b>: ${maintainer}\n"
	if [[ ! -z $CHANGELOG ]]; then
		FORMAT=${FORMAT}"\n<b>Changelog</b>:\n"${CHANGELOG}"\n"
	fi
	FORMAT=${FORMAT}"\n<b>MD5</b>: <code>$MD5</code>\n"
	python3 vendor/utils/scripts/telegram.py -c @pbrp_testers -AN "$pb_sticker" -C "$FORMAT" -D "Download|$link" -m "HTML"	

	echo -e "${green}Deployed to Telegram SUCCESSFULLY!\n${nocol}"
	return 0
}

# Deploy Test Build on Official PBRP Device Maintainers Group
function tg_test_deploy() {
	echo -e "${green}Deploying to Telegram Device Maintainers Chat!\n${nocol}"

    if [[ $USE_SECRET_BOOTABLE == 'true' ]]; then
    	cp $BUILD_IMG recovery.img
        TEST_LINK=$(curl -F'file=@recovery.img' https://0x0.st)
    else
        TEST_LINK="https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/download/${RELEASE_TAG}/$(echo $BUILDFILE | awk -F'[/]' '{print $NF}')"
    fi
    
    MAINTAINER_MSG="PitchBlack Recovery for \`${VENDOR}\` \`${CODENAME}\` is available Only For Testing Purpose\n\n"
    if [[ ! -z $MAINTAINER ]]; then MAINTAINER_MSG=${MAINTAINER_MSG}"Maintainer: ${MAINTAINER}\n\n"; fi
    if [[ ! -z $CHANGELOG ]]; then MAINTAINER_MSG=${MAINTAINER_MSG}"Changelog:\n"${CHANGELOG}"\n\n"; fi
    
    MAINTAINER_MSG=${MAINTAINER_MSG}"Go to ${TEST_LINK} to download it."
    if [[ $USE_SECRET_BOOTABLE == 'true' ]]; then
        python3 vendor/utils/scripts/telegram.py -c "-1001465331122" -M "$MAINTAINER_MSG" -m "HTML"
    else
        python3 vendor/utils/scripts/telegram.py -c "-1001228903553" -M "$MAINTAINER_MSG" -m "HTML"
    fi

    echo -e "${green}Deployed to Telegram SUCCESSFULLY!\n${nocol}"
	return 0
}

# Deploy on PBRP Database for WP
# NOTE: Must be called after sf_deploy
function wp_deploy() {
	echo -e "${green}Deploying to PBRP Database!\n${nocol}"

	curl -i -X POST 'https://us-central1-pbrp-prod.cloudfunctions.net/release' -H "Authorization: Bearer ${GCF_AUTH_KEY}" -H "Content-Type: application/json" --data "{\"CODENAME\": \"$CODENAME\", \"vendor\":\"$VENDOR\", \"md5\": \"$MD5\", \"size\": \"$FILE_SIZE\", \"sf_link\": \"$sf_link\", \"gh_link\": \"$gh_link\",\"version\": \"$VERSION\", \"build_type\": \"$DEPLOY_TYPE\"}"

	echo -e "${green}Deployed to PBRP Database SUCCESSFULLY!\n${nocol}"
	return 0 
}

if [[ "$DEPLOY_TYPE" == "OFFICIAL" ]]; then
	zipcounter=$(find $(pwd)/out/target/product/$CODENAME/PBRP*-OFFICIAL.zip 2>/dev/null | wc -l)
else
	zipcounter=$(find $(pwd)/out/target/product/$CODENAME/PBRP*-UNOFFICIAL.zip 2>/dev/null | wc -l)
fi

if [[ "$zipcounter" > "0" ]]; then
	if [[ "$zipcounter" > "1" ]]; then
		printf "${red}More than one zips dected! Remove old build...\n${nocol}"
	else
		# Time for Deployment!
		if [[ "$DEPLOY_TYPE" == "OFFICIAL" ]]; then
			# Official Deploy = SF + GHR + WP + TG (Main Channel)

			[ sf_deploy != "0" ] && echo -e "Error in SourceForge Deployment." || exit 1
			[ gh_deploy != "0" ] && echo -e "Error in GitHub Releases Deployment." || exit 1
			[ wp_deploy != "0" ] && echo -e "Error in PBRP Website Deployment." || exit 1
			[ tg_official_deploy != "0" ] && echo -e "Error in Telegram Official Deployment." || exit 1
		elif [[ "$DEPLOY_TYPE" == "BETA" ]]; then
			# Beta Deploy = SF + GHR + WP + TG (Beta Group)

			[ sf_deploy != "0" ] && echo -e "Error in SourceForge Deployment." || exit 1
			[ gh_deploy != "0" ] && echo -e "Error in GitHub Releases Deployment." || exit 1
			[ wp_deploy != "0" ] && echo -e "Error in PBRP Website Deployment." || exit 1
			[ tg_beta_deploy != "0" ] && echo -e "Error in Telegram Beta Deployment." || exit 1
		elif [[ "$DEPLOY_TYPE" == "TEST" ]]; then
			# Test Deploy = GHR + TG (Device Maintainers Chat)

			[ gh_deploy != "0" ] && echo -e "Error in GitHub Releases Deployment." || exit 1
			[ tg_test_deploy != "0" ] && echo -e "Error in Telegram Test Deployment." || exit 1
		else
			echo -e "Wrong Arguments Given, Required Arguments: BUILD_TYPE(OFFICIAL/BETA/TEST)" && exit 1
		fi
	fi
else
	echo
	printf "${red}No build found\n${nocol}"
	echo
fi