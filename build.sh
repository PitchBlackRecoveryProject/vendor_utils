SFUserName=$1
SFPassword=$2
GITHUB_TOKEN=$3

echo -en "The Whole PATH ENV is - " && echo $PATH
which ghr && which repo

mkdir $(pwd)/work && cd work

echo "Initialize & Sync PBRP repo"
echo $(pwd)
repo init -q -u https://github.com/PitchBlackRecoveryProject/manifest_pb.git -b ${MANIFEST_BRANCH} --depth 1
time repo sync -c -q --force-sync --no-clone-bundle --no-tags -j32

echo "Get the Device Tree on place"
git clone https://$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/${CIRCLE_PROJECT_REPONAME} -b ${CIRCLE_BRANCH} device/${VENDOR}/${CODENAME}

# If any omni.dependencies is placed, roomservice will clone them. No need to repo sync again

# Keep the whole .repo/manifests folder
cp -a .repo/manifests $(pwd)/ && ls manifests/
echo "Clean up the .repo, no use of it now"
rm -rf .repo
mkdir -p .repo && mv manifests .repo/ && ls -la .repo/*

rm -rf bootable/recovery && git clone https://github.com/PitchBlackRecoveryProject/android_bootable_recovery -b ${PBRP_BRANCH} --single-branch bootable/recovery
rm -rf vendor/pb && git clone https://github.com/PitchBlackRecoveryProject/vendor_pb -b pb vendor/pb

echo "Start the Build Process"
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch ${BUILD_LUNCH}
make -j16 recoveryimage

echo "Deploying"
export TEST_BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PitchBlack*-UNOFFICIAL.zip 2>/dev/null)
export BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PitchBlack*-OFFICIAL.zip 2>/dev/null)
export UPLOAD_PATH=$(pwd)/out/target/product/${CODENAME}/upload/
mkdir ${UPLOAD_PATH}
cp $BUILDFILE $UPLOAD_PATH
export BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/recovery.img 2>/dev/null)
cp $BUILDFILE $UPLOAD_PATH
cp $TEST_BUILDFILE $UPLOAD_PATH
if [[ -n $BUILDFILE ]]
then
sudo chmod a+x vendor/pb/pb_deploy.sh && ./vendor/pb/pb_deploy.sh ${CODENAME} ${SFUserName} ${SFPassword} ${GITHUB_TOKEN}
ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "Latest Release for $(echo $CODENAME)" -b "PBRP $(echo $VERSION)" -c ${CIRCLE_SHA1} -delete ${VERSION} ${UPLOAD_PATH}
elif [[ $TEST_BUILD == 'true' ]] && [[ -n $TEST_BUILDFILE ]]
then
ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -n "Test Release for $(echo $CODENAME)" -b "PBRP $(echo $VERSION)" -c ${CIRCLE_SHA1} -delete ${VERSION}-test ${UPLOAD_PATH}
fi
