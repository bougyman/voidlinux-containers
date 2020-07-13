#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
source lib/functions.sh
optparse "$@"

# Import alpine base builder
alpine=$(buildah from "${created_by}/alpine-voidbuilder:${ARCH}_latest") || die 1 "Could not get alpine-builder image"

# Do not reap temp containers when debugging
if [ -z "$BUILDAH_DEBUG" ]
then
    trap 'buildah rm "$alpine"; [ -z "$voidbuild" ] || buildah rm "$voidbuild"' EXIT
fi

alpine_mount=$(buildah mount "$alpine") || die 2 \
    "Could not mount alpine-builder! Bailing (see error above, you probably need to run in a 'buildah unshare' session)"

# Build a void-based builder
voidbuild=$(bud from scratch) || exit 3
voidbuild_mount=$(buildah mount "$voidbuild") || die 4 "Could not mount $voidbuild"
echo "Mount is '$voidbuild_mount'"
bud copy "$voidbuild" "$alpine_mount"/target /
bud copy "$voidbuild" void-mklive/keys/* /target/var/db/xbps/keys/
bud run "$voidbuild" -- sh -c "xbps-reconfigure -a && mkdir -p /target/var/cache && \
                                  ln -s /var/cache/xbps /target/var/cache/xbps && \
                                  mkdir -p /target/etc/xbps.d && \
                                  echo 'noextract=/usr/share/zoneinfo/right*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/locale*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/man*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/bash-completion*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/zsh*' >> /target/etc/xbps.d/noextract.conf && \
                                  echo 'noextract=/usr/share/info*' >> /target/etc/xbps.d/noextract.conf"

bud run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-install -yMU \
                                  --repository=${REPOSITORY}/current \
                                  --repository=${REPOSITORY}/current/musl \
                                  -r /target \
                                  xbps base-files ca-certificates"

if [ -n "$BASEPKG" ]
then
    echo "Installing '$BASEPKG'" >&2
    bud run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-install -yMU \
                                      --repository=${REPOSITORY}/current \
                                      --repository=${REPOSITORY}/current/musl \
                                      ${BASEPKG} -r /target"
fi
# We don't care if the removes fail. Likely they were never insalled on this arch, or can't be
buildah run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-remove -y base-minimal -r /target" &>/dev/null || true
for exclude in $(<excludes)
do
    buildah run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-remove -y ${exclude} -r /target " &>/dev/null || true
done

if [[ "$tag" =~ $striptags ]]
then
    echo "Stripping Binaries" >&2
    buildah run "$voidbuild" -- sh -c 'find /target/usr/lib/ -maxdepth 1 -type f ! -type l -exec strip -v {} \;'
    # Install busybox
    echo "Arch is ${ARCH}"
    bud run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-install -yMU \
                                      --repository=${REPOSITORY}/current \
                                      --repository=${REPOSITORY}/current/musl \
                                      busybox -r /target"
    # Exclude lots of packages
    mapfile -t tiny_excludes < tinyexcludes
    buildah run "$voidbuild" -- sh -c "XBPS_ARCH=${ARCH} xbps-remove -y ${tiny_excludes[*]} -r /target" || true

    # Now use busybox for *
    mapfile -t bbox_commands < busybox-commands
    bud run "$voidbuild" -- sh -c "for cmd in ${bbox_commands[*]}
                                   do
                                       [ -e \"/target/usr/bin/\$cmd\" ] || ln -svf /usr/bin/busybox \"/target/usr/bin/\$cmd\"
                                   done"
fi

bud run "$voidbuild" -- sh -c "rm -rvf /var/xbps/cache/*"

# Commit void-voidbuilder
bud config --created-by "$created_by" "$voidbuild"
bud config --author "$author" --label name=void-voidbuilder "$voidbuild"
bud unmount "$voidbuild"
bud unmount "$alpine"
if [[ "$tag" =~ $striptags ]]
then
    bud commit --squash "$voidbuild" "${created_by}/void-voidbuilder:${tag}"
else
    bud commit --squash "$voidbuild" "${created_by}/void-voidbuilder:${ARCH}_latest"
fi

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
