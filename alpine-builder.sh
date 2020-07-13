#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
. lib/functions.sh
optparse "$@"

# Build a builder from alpine
alpine=$(buildah from alpine:3.12) || die 1 "Could not get alpine base image"
# Do not remove build containers if we're debugging
if [ -z "$BUILDAH_DEBUG" ]
then
    trap 'buildah rm "$alpine"' EXIT
fi
alpine_mount=$(buildah mount "$alpine") || die 2 "Could not mount alpine image, you may need a buildah unshare session"

bud copy "$alpine" void-mklive/keys/* /target/var/db/xbps/keys/
bud run "$alpine" -- apk add ca-certificates curl
wget -O- "${REPOSITORY}/static/xbps-static-latest.$(uname -m)-musl.tar.xz" | tar Jx -C "$alpine_mount"
XBPS_ARCH=$ARCH
export XBPS_ARCH
bud run "$alpine" -- xbps-install.static -yMU --repository=${REPOSITORY}/current \
                                             --repository=${REPOSITORY}/current/musl -r /target base-minimal binutils busybox

# Commit alpine-voidbuilder
bud config --created-by "$created_by" "$alpine"
bud config --author "$author" --label name=alpine-voidbuilder "$alpine"
bud unmount "$alpine" || die "$buildah_err"
bud commit --squash "$alpine" "${created_by}/alpine-voidbuilder:${ARCH}_latest"
# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
