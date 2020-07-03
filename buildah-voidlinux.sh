#!/bin/bash
# author is simply the maintainer tag in image/container metadata
: "${author:=at hey dot com @bougyman}"
# created_by will be the prefix of the images, as well. i.e. bougyman/voidlinux
: "${created_by:=bougyman}"
: "${REPOSITORY:=https://alpha.de.repo.voidlinux.org}"
: "${ARCH:=x86_64}"
: "${BASEPKG:=base-minimal}"

# Import the void-based builder
voidbuild=$(buildah from "$created_by"/void-voidbuilder)
voidbuild_mount=$(buildah mount "$voidbuild")

# Build the final voidlinux container
void=$(buildah from scratch)
buildah mount "$void" >/dev/null

# Perhaps rsync here with a lot of excluded files instead of using buildah copy?
buildah copy "$void" "$voidbuild_mount"/target /

# Here's where the current cleanup happens
buildah run "$void" -- sh -c "rm /var/cache/xbps && \
                              sed -i 's/^#en_US/en_US/' /etc/default/libc-locales && \
                              xbps-reconfigure -f glibc-locales && \
                              xbps-reconfigure -a && \
                              update-ca-certificates && \
                              xbps-install -Syu && \
                              ls -d /usr/share/locale/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -rf && \
                              ls /usr/share/i18n/locales/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f && \
                              rm -rf /usr/share/X11 && \
                              rm -rf /usr/share/info/* && \
                              rm -rf /usr/share/doc/* && \
                              rm -rf /usr/share/man/* && \
                              rm -rf /usr/lib/gconv/libCNS.so /usr/lib/gconv/IBM* /usr/lib/gconv/BIG5HKSCS.so && \
                              xbps-remove -y runit-void gawk base-minimal && \
                              xbps-install -Sy mawk && \
                              rm -vfr /var/cache/xbps"

buildah unmount "$voidbuild" >/dev/null

# Commit voidlinux
buildah config --cmd /bin/sh "$void" 
buildah config --created-by "$created_by" "$void" 
buildah config --author "$author" --label name=voidlinux "$void" 
buildah unmount "$void"
buildah commit "$void" "$created_by"/voidlinux

# Clean up build containers
buildah rm "$voidbuild"
buildah rm "$void"
