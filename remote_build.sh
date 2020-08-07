#!/bin/bash
set -eo pipefail

# SANITY CHECKS
if [[ -z $GitHubMail ]]; then echo -e "You haven't configured GitHub E-Mail Address." && exit 1; fi
if [[ -z $GitHubName ]]; then echo -e "You haven't configured GitHub Username." && exit 1; fi
if [[ -z $GITHUB_TOKEN ]]; then echo -e "You haven't configured GitHub Token.\nWithout it, recovery can't be published." && exit 1; fi
if [[ -z $MANIFEST_BRANCH ]]; then echo -e "You haven't configured PitchBlack Recovery Project Manifest Branch." && exit 1; fi
if [[ -z $VENDOR ]]; then echo -e "You haven't configured Vendor name." && exit 1; fi
if [[ -z $CODENAME ]]; then echo -e "You haven't configured Device Codename." && exit 1; fi
if [[ -z $BUILD_LUNCH && -z $FLAVOR ]]; then echo -e "Set at least one variable. BUILD_LUNCH or FLAVOR." && exit 1; fi

id

cd /home/builder/

( mkdir -p android || true ) && cd android

# Set GitAuth Infos"
git config --global user.email $GitHubMail
git config --global user.name $GitHubName
git config --global credential.helper store
git config --global color.ui true
# Use Google Git Cookies for Smooth repo-sync
git clone -q "https://$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/google-git-cookies.git" &> /dev/null
bash google-git-cookies/setup_cookies.sh
rm -rf google-git-cookies

# threads available = only 2
THREADCOUNT=7

[[ ! -d /tmp ]] && mkdir -p /tmp
curl -sL https://gist.github.com/rokibhasansagar/cf8669411a1a57ba40c3090cd5146cd9/raw/keepalive.sh -o /tmp/keepalive.sh
chmod a+x /tmp/keepalive.sh

# sync
echo -e "Initializing PBRP repo sync..."
repo init -q -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b ${MANIFEST_BRANCH} --depth 1
/tmp/keepalive.sh & repo sync -c -q --force-sync --no-clone-bundle --no-tags -j$THREADCOUNT
kill -s SIGTERM $(cat /tmp/keepalive.pid)

# clean unneeded files
rm -rf development/apps/ development/samples/ packages/apps/
# use pb-10.0
rm -rf vendor/pb && git clone https://github.com/PitchBlackRecoveryProject/vendor_pb -b pb-10.0 --depth 1 vendor/pb

# CLONE VENDOR REPO AGAIN FOR SAFEKEEPING
rm -rf vendor/pb && git clone https://github.com/PitchBlackRecoveryProject/vendor_utils -b pb vendor/utils --depth=1

# Hax for fixing building with less complexity
cp vendor/utils/pb_build.sh vendor/pb/pb_build.sh && chmod +x vendor/pb/pb_build.sh

rm vendor/pb/vendorsetup.sh
if [[ -n ${USE_SECRET_BOOTABLE} ]]; then
  [[ -n ${PBRP_BRANCH} ]] && unset PBRP_BRANCH
  [[ -z ${SECRET_BR} ]] && SECRET_BR="android-9.0"
  rm -rf bootable/recovery
  git clone --quiet --progress https://$GitHubName:$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/pbrp_recovery_secrets -b ${SECRET_BR} --single-branch bootable/recovery
elif [[ -n ${PBRP_BRANCH} ]]; then
  rm -rf bootable/recovery
  git clone --quiet --progress https://github.com/PitchBlackRecoveryProject/android_bootable_recovery -b ${PBRP_BRANCH} --single-branch bootable/recovery
fi
echo -e "\nGetting the Device Tree on place"
if [[ "${CIRCLE_PROJECT_USERNAME}" == "PitchBlackRecoveryProject" ]]; then
  git clone --quiet --progress https://$GitHubName:$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/${CIRCLE_PROJECT_REPONAME} -b ${CIRCLE_BRANCH} device/${VENDOR}/${CODENAME}
else
  git clone https://$GITHUB_TOKEN@github.com/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME} -b ${CIRCLE_BRANCH} device/${VENDOR}/${CODENAME}
fi
ls -lA .
if [[ -n $EXTRA_CMD ]]; then
  eval "$EXTRA_CMD"
  cd /home/builder/android/
fi

echo -e "\nPreparing Delicious Lunch..."
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
if [[ -n $BUILD_LUNCH ]]; then
  lunch ${BUILD_LUNCH}
elif [[ -n $FLAVOR ]]; then
  lunch omni_${CODENAME}-${FLAVOR}
fi

/tmp/keepalive.sh & make -j$THREADCOUNT recoveryimage
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
        cd vendor/utils; python3 telegram.py -c "-1001465331122" -M "$MAINTAINER_MSG" -m "HTML"; cd $DIR/work
    else
        cd vendor/utils; python3 telegram.py -c "-1001228903553" -M "$MAINTAINER_MSG" -m "HTML"; cd $DIR/work
    fi
fi
echo -e "\n\nAll Done Gracefully\n\n"
