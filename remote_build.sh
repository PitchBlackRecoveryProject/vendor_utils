#!/bin/bash
[ ! -d /home/builder/.ccache ] && mkdir -p /home/builder/.ccache
cd /home/builder/
echo "$DOCKERHUB_PASSWORD" | docker login -u $DOCKERHUB_USERNAME --password-stdin
docker run --privileged -i --name worker --user builder \
  -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) \
  -e GitHubMail="${GitHubMail}" -e GitHubName="${GitHubName}" -e GITHUB_TOKEN="${GITHUB_TOKEN}" \
  -e CIRCLE_PROJECT_USERNAME="${CIRCLE_PROJECT_USERNAME}" -e CIRCLE_PROJECT_REPONAME="${CIRCLE_PROJECT_REPONAME}" \
  -e CIRCLE_BRANCH="${CIRCLE_BRANCH}" -e CIRCLE_SHA1="${CIRCLE_SHA1}" \
  -e MANIFEST_BRANCH="${MANIFEST_BRANCH}" -e PBRP_BRANCH="${PBRP_BRANCH}" \
  -e USE_SECRET_BOOTABLE="${USE_SECRET_BOOTABLE}" -e SECRET_BR="${SECRET_BR}" \
  -e VERSION="${VERSION}" -e VENDOR="${VENDOR}" -e CODENAME="${CODENAME}" \
  -e BUILD_LUNCH="${BUILD_LUNCH}" -e FLAVOR="${FLAVOR}" \
  -e MAINTAINER="${MAINTAINER}" -e CHANGELOG="${CHANGELOG}" \
  -e TEST_BUILD="${TEST_BUILD}" -e PB_OFFICIAL="${PB_OFFICIAL}" \
  -e BETA_BUILD="${BETA_BUILD}" \
  -e PB_ENGLISH="${PB_ENGLISH}" -e EXTRA_CMD="${EXTRA_CMD}" -e BOT_API="${BOT_API}" \
  -v "${pwd}:/home/builder/:rw,Z" \
  -v "/home/builder/.ccache:/srv/ccache:rw" \
  --workdir /home/builder/ \
  fr3akyphantom/droid-builder:latest bash << EOF

curl -sL https://raw.githubusercontent.com/PitchBlackRecoveryProject/vendor_utils/pb/build.sh -o build.sh
source build.sh
EOF
