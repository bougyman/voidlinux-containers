#!/bin/bash
# author is simply the maintainer tag in image/container metadata
: "${author:=at hey dot com @bougyman}"
# created_by will be the prefix of the images, as well. i.e. bougyman/voidlinux
: "${created_by:=bougyman}"
: "${REPOSITORY:=https://alpha.de.repo.voidlinux.org}"
: "${ARCH:=x86_64}"
: "${BASEPKG:=base-minimal}"

# Import alpine base builder
alpine=$(buildah from "$created_by"/alpine-voidbuilder)
trap 'buildah rm "$alpine"; [ -z "$voidbuild" ] || buildah rm "$voidbuild"' EXIT
if ! alpine_mount=$(buildah mount "$alpine")
then
    echo "Could not mount alpine! Bailing (see error above, you probably need to run in a 'buildah unshare' session)" >&2
    exit 1
fi

# Build a void-based builder
voidbuild=$(buildah from scratch)
buildah mount "$voidbuild"
buildah copy "$voidbuild" "$alpine_mount"/target /
buildah copy "$voidbuild" void-mklive/keys/* /target/var/db/xbps/keys/
buildah run "$voidbuild" -- sh -c "xbps-reconfigure -a && mkdir -p /target/var/cache && \
                                  ln -s /var/cache/xbps /target/var/cache/xbps && \
                                  mkdir -p /target/etc/xbps.d
                                  echo 'noextract=/usr/share/man*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/info*' >> /target/etc/xbps.d/noextract.conf && \
                                  XBPS_ARCH=${ARCH} xbps-install -yMU \
                                    --repository=${REPOSITORY}/current \
                                    --repository=${REPOSITORY}/current/musl \
                                    -r /target \
                                    ${BASEPKG} ca-certificates && \
                                  XBPS_ARCH=${ARCH} xbps-remove -y base-minimal -r /target && rm -rvf /var/xbps/cache/*"
set -e
for exclude in $(<excludes)
do
    buildah run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-remove -y ${exclude} -r /target "
done

# Commit void-voidbuilder
buildah config --created-by "$created_by" "$voidbuild" 
buildah config --author "$author" --label name=void-voidbuilder "$voidbuild" 
buildah unmount "$voidbuild"
buildah commit "$voidbuild" "$created_by"/void-voidbuilder
