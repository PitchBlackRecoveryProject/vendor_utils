PATH=~/bin:$PATH
curl --create-dirs -L -o ~/bin/repo -O -L https://github.com/akhilnarang/repo/raw/master/repo
chmod a+x ~/bin/repo

echo "Install ghr binary"
wget -q 'https://github.com/tcnksm/ghr/releases/download/v0.13.0/ghr_v0.13.0_linux_amd64.tar.gz'
tar -xzf ghr_v0.13.0_linux_amd64.tar.gz && rm ghr_v0.13.0_linux_amd64.tar.gz
cp ghr_v0.13.0_linux_amd64/ghr ~/bin && PATH=~/bin:$PATH
rm -rf ghr_v0.13.0_linux_amd64/
which ghr
which repo

echo "Initialize & Sync PBRP repo"
echo $(pwd)
mkdir $(pwd)/work && cd work
repo init --depth=1 -q -u git://github.com/PitchBlackRecoveryProject/manifest_pb.git -b ${MANIFEST_BRANCH}
time repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32

echo "Get the Device Tree on place"
git clone https://PitchBlackRecoveryProect:$GITHUB_TOKEN@github.com/PitchBlackRecoveryProject/${CIRCLE_PROJECT_REPONAME} device/${VENDOR}/${CODENAME}

# Sync again, as Device has Dependencies
repo sync -c -f -q --force-sync --no-clone-bundle --no-tags -j32

# Keep the whole .repo/manifests folder
cp -a .repo/manifests $(pwd)/ && ls manifests/
echo "Clean up the .repo, no use of it now"
rm -rf .repo
mkdir -p .repo && mv manifests .repo/ && ls -la .repo/*

rm -rf bootable/recovery && git clone https://github.com/PitchBlackRecoveryProject/android_bootable_recovery -b ${PBRP_BRANCH} bootable/recovery
rm -rf vendor/pb && git clone https://github.com/PitchBlackRecoveryProject/vendor_pb -b pb vendor/pb

echo "Start the Build Process"
export ALLOW_MISSING_DEPENDENCIES=true
source build/envsetup.sh
lunch ${BUILD_LUNCH}
make -j16 recoveryimage

echo "Deploying"
export BUILDFILE=$(find $(pwd)/out/target/product/${CODENAME}/PitchBlack*-OFFICIAL.zip 2>/dev/null)
if [[ -n $BUILDFILE ]]
then
sudo chmod a+x vendor/pb/pb_deploy.sh && ./vendor/pb/pb_deploy.sh ${CODENAME} ${SFUserName} ${SFPassword} ${GITHUB_TOKEN}
ghr -t ${GITHUB_TOKEN} -u ${CIRCLE_PROJECT_USERNAME} -r ${CIRCLE_PROJECT_REPONAME} -c ${CIRCLE_SHA1} -delete ${VERSION} ${BUILDFILE}
fi
