#!/bin/bash
# author is simply the maintainer tag in image/container metadata
: "${author:=at hey dot com @bougyman}"
# created_by will be the prefix of the images, as well. i.e. bougyman/voidlinux
: "${created_by:=bougyman}"
: "${REPOSITORY:=https://alpha.de.repo.voidlinux.org}"
: "${ARCH:=x86_64}"
: "${BASEPKG:=base-minimal}"

# Build a builder from alpine
alpine=$(buildah from alpine:3.12)
alpine_mount=$(buildah mount "$alpine")
buildah copy "$alpine" void-mklive/keys/* /target/var/db/xbps/keys/
buildah run "$alpine" -- apk add ca-certificates curl
curl "${REPOSITORY}/static/xbps-static-latest.$(uname -m)-musl.tar.xz" | tar Jx -C "$alpine_mount"
XBPS_ARCH=$ARCH
export XBPS_ARCH
buildah run "$alpine" -- xbps-install.static -yMU --repository=${REPOSITORY}/current \
                                             --repository=${REPOSITORY}/current/musl -r /target base-minimal

# Commit alpine-voidbuilder
buildah config --created-by "$created_by" "$alpine" 
buildah config --author "$author" --label name=alpine-voidbuilder "$alpine" 
buildah unmount "$alpine"
buildah commit "$alpine" "$created_by"/alpine-voidbuilder
buildah rm "$alpine"
