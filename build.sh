#!/bin/bash
set -eo pipefail
###
#
#  Semi-AIO Script for Building PitchBlack Recovery in CircleCI
#
#  Copyright (C) 2019-2020, Rokib Hasan Sagar <rokibhasansagar2014@outlook.com>
#                           PitchBlack Recovery Project <pitchblackrecovery@gmail.com>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
###

# SANITY CHECKS
if [[ -z $GitHubMail ]]; then echo -e "You haven't configured GitHub E-Mail Address." && exit 1; fi
if [[ -z $GitHubName ]]; then echo -e "You haven't configured GitHub Username." && exit 1; fi
if [[ -z $GITHUB_TOKEN ]]; then echo -e "You haven't configured GitHub Token.\nWithout it, recovery can't be published." && exit 1; fi
if [[ -z $MANIFEST_BRANCH ]]; then echo -e "You haven't configured PitchBlack Recovery Project Manifest Branch." && exit 1; fi
if [[ -z $VENDOR ]]; then echo -e "You haven't configured Vendor name." && exit 1; fi
if [[ -z $CODENAME ]]; then echo -e "You haven't configured Device Codename." && exit 1; fi
if [[ -z $BUILD_LUNCH ]] && [[ -z $FLAVOR ]]; then echo -e "Set at least one variable. BUILD_LUNCH or FLAVOR." && exit 1; fi

# Set GitAuth Infos"
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global credential.helper store
git config --global color.ui true

if [[ "${CIRCLE_PROJECT_USERNAME}" == "PitchBlackRecoveryProject" ]]; then
# Use Google Git Cookies for Smooth repo-sync
git clone -q "https://$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/google-git-cookies.git" &> /dev/null
bash google-git-cookies/setup_cookies.sh
rm -rf google-git-cookies
fi

echo -e "Starting the CI Build Process...\n"
[[ ! -d /tmp ]] && mkdir -p /tmp
# Make a keepalive shell so that it can bypass CI Termination on output freeze
curl -sL https://gist.github.com/rokibhasansagar/cf8669411a1a57ba40c3090cd5146cd9/raw/keepalive.sh -o /tmp/keepalive.sh
chmod a+x /tmp/keepalive.sh

DIR=$(pwd)
mkdir $(pwd)/android && cd android

# sync
echo -e "Initializing PBRP repo sync..."
repo init -q -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b ${MANIFEST_BRANCH} --depth 1
/tmp/keepalive.sh & repo sync -c -q --force-sync --no-clone-bundle --no-tags -j6 #THREADCOUNT is only 2 in remote docker
kill -s SIGTERM $(cat /tmp/keepalive.pid)

# clean unneeded files
rm -rf development/apps/ development/samples/ packages/apps/

# Hax for fixing building with less complexity
cp vendor/utils/pb_build.sh vendor/pb/pb_build.sh && chmod +x vendor/pb/pb_build.sh

echo -e "\nGetting the Device Tree on place"
if [[ "${CIRCLE_PROJECT_USERNAME}" == "PitchBlackRecoveryProject" ]]; then
    git clone --quiet --progress https://$GitHubName:$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/${CIRCLE_PROJECT_REPONAME} -b ${CIRCLE_BRANCH} device/${VENDOR}/${CODENAME}
else
    git clone --quiet --progress https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} -b ${CIRCLE_BRANCH} device/${VENDOR}/${CODENAME}
fi

if [[ -n ${USE_SECRET_BOOTABLE} ]]; then
    # ONLY FOR CORE DEVS
    if [[ -n ${PBRP_BRANCH} ]]; then
        unset PBRP_BRANCH
    fi
    if [[ -z ${SECRET_BR} ]]; then
        SECRET_BR="android-9.0"
    fi
    rm -rf bootable/recovery
    git clone --quiet --progress https://$GitHubName:$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/pbrp_recovery_secrets -b ${SECRET_BR} --single-branch bootable/recovery
elif [[ -n ${PBRP_BRANCH} ]]; then
    # FOR EVERYBODY
    rm -rf bootable/recovery
    git clone --quiet --progress https://github.com/PitchBlackRecoveryProject/android_bootable_recovery -b ${PBRP_BRANCH} --single-branch bootable/recovery
fi

if [[ -n $EXTRA_CMD ]]; then
  eval "$EXTRA_CMD"
  cd ${DIR}/android/
fi

echo -e "\nPreparing Delicious Lunch..."
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
if [[ -n $BUILD_LUNCH ]]; then
  lunch ${BUILD_LUNCH}
elif [[ -n $FLAVOR ]]; then
  lunch omni_${CODENAME}-${FLAVOR}
fi

# Keep the whole .repo/manifests folder
cp -a .repo/manifests $(pwd)/
echo "Cleaning up the .repo, no use of it now"
rm -rf .repo
mkdir -p .repo && mv manifests .repo/ && ln -s .repo/manifests/default.xml .repo/manifest.xml

/tmp/keepalive.sh & make -j6 recoveryimage
kill -s SIGTERM $(cat /tmp/keepalive.pid)
echo -e "\nYummy Recovery is Served.\n"

echo "Ready to Deploy"
export TEST_BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PBRP*-UNOFFICIAL.zip 2>/dev/null)
export BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PBRP*-OFFICIAL.zip 2>/dev/null)
export BUILD_FILE_TAR=$(find $(pwd)/out/target/product/${CODENAME}/*.tar 2>/dev/null)
export UPLOAD_PATH=$(pwd)/out/target/product/${CODENAME}/upload/

mkdir ${UPLOAD_PATH}

if [[ -n ${BUILD_FILE_TAR} ]]; then
    echo "Samsung's Odin Tar available: $BUILD_FILE_TAR"
    cp ${BUILD_FILE_TAR} ${UPLOAD_PATH}
fi

if [[ "${CIRCLE_PROJECT_USERNAME}" == "PitchBlackRecoveryProject" ]] && [[ -n $BUILDFILE ]]; then
    echo "Got the Official Build: $BUILDFILE"
    sudo chmod a+x vendor/utils/pb_deploy.sh
    ./vendor/utils/pb_deploy.sh ${CODENAME} ${SFUserName} ${SFPassword} ${GITHUB_TOKEN} ${VERSION} ${MAINTAINER}
    cp $BUILDFILE $UPLOAD_PATH
    export BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/recovery.img 2>/dev/null)
    cp $BUILDFILE $UPLOAD_PATH
    ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "Latest Release for $(echo $CODENAME)" -b "PBRP $(echo $VERSION)" -c ${CIRCLE_SHA1} -delete ${VERSION} ${UPLOAD_PATH}
elif [[ $TEST_BUILD == 'true' ]] && [[ -n $TEST_BUILDFILE ]]; then
    echo "Got the Unofficial Build: $TEST_BUILDFILE"
    export TEST_BUILDIMG=$(find $(pwd)/out/target/product/${CODENAME}/recovery.img 2>/dev/null)
    if [[ $USE_SECRET_BOOTABLE == 'true' ]]; then
    cp $TEST_BUILDIMG recovery.img
    TEST_IT=$(curl -F'file=@recovery.img' https://0x0.st)
    else
    cp $TEST_BUILDFILE $UPLOAD_PATH
    cp $TEST_BUILDIMG $UPLOAD_PATH
    ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "Test Release for $(echo $CODENAME)" -b "PBRP $(echo $VERSION)" -c ${CIRCLE_SHA1} -delete ${VERSION}-test ${UPLOAD_PATH}
    fi
else
    echo -e "Something Wrong with your build system.\nPlease fix it." && exit 1
fi

# SEND NOTIFICATION TO MAINTAINERS, AVAILABLE FOR TEAM DEVS ONLY
if [[ "${CIRCLE_PROJECT_USERNAME}" == "PitchBlackRecoveryProject" ]] && [[ ! -z $TEST_BUILDFILE ]]; then
    echo -e "\nSending the Test build info in Maintainer Group\n"
    if [[ $USE_SECRET_BOOTABLE == 'true' ]]; then
    TEST_LINK="${TEST_IT}"
    else
    TEST_LINK="https://github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/releases/download/${VERSION}-test/$(echo $TEST_BUILDFILE | awk -F'[/]' '{print $NF}')"
    fi
    MAINTAINER_MSG="PitchBlack Recovery for \`${VENDOR}\` \`${CODENAME}\` is available Only For Testing Purpose\n\n"
    if [[ ! -z $MAINTAINER ]]; then MAINTAINER_MSG=${MAINTAINER_MSG}"Maintainer: ${MAINTAINER}\n\n"; fi
    if [[ ! -z $CHANGELOG ]]; then MAINTAINER_MSG=${MAINTAINER_MSG}"Changelog:\n"${CHANGELOG}"\n\n"; fi
    MAINTAINER_MSG=${MAINTAINER_MSG}"Go to ${TEST_LINK} to download it."
    if [[ $USE_SECRET_BOOTABLE == 'true' ]]; then
        python3 vendor/utils/telegram.py -c "-1001465331122" -M "$MAINTAINER_MSG" -m "HTML"
    else
        python3 vendor/utils/telegram.py -c "-1001228903553" -M "$MAINTAINER_MSG" -m "HTML"
    fi
fi

echo -e "\n\nAll Done Gracefully\n\n"

