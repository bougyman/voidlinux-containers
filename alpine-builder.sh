#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
. lib/functions.sh
optparse "$@"

# Build a builder from alpine
alpine=$(bud from alpine:3.12) || die "$buildah_count"
trap 'buildah rm "$alpine"' EXIT
alpine_mount=$(bud mount "$alpine") || die "$buildah_count" "Could not mount $alpine"

bud copy "$alpine" void-mklive/keys/* /target/var/db/xbps/keys/ || die "$buildah_count"
bud run "$alpine" -- apk add ca-certificates curl || die "$buildah_count"
wget -O- "${REPOSITORY}/static/xbps-static-latest.$(uname -m)-musl.tar.xz" | tar Jx -C "$alpine_mount" || die 55 "Failed to download xbps"
XBPS_ARCH=$ARCH
export XBPS_ARCH
bud run "$alpine" -- xbps-install.static -yMU --repository=${REPOSITORY}/current \
                                             --repository=${REPOSITORY}/current/musl -r /target base-minimal || die "$buildah_count"

# Commit alpine-voidbuilder
bud config --created-by "$created_by" "$alpine" || die "$buildah_count"
bud config --author "$author" --label name=alpine-voidbuilder "$alpine" || die "$buildah_count"
bud unmount "$alpine" || die "$buildah_count"
bud commit --squash "$alpine" "${created_by}/alpine-voidbuilder:${tag}" || die "$buildah_count"
# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
