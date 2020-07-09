#!/bin/bash
# author is simply the maintainer tag in image/container metadata
: "${author:=at hey dot com @bougyman}"
# created_by will be the prefix of the images, as well. i.e. bougyman/voidlinux
: "${created_by:=bougyman}"
: "${REPOSITORY:=https://alpha.de.repo.voidlinux.org}"
: "${ARCH:=x86_64}"
: "${BASEPKG:=base-minimal}"
: "${tag:=latest}"

# Import the void-based builder
voidbuild=$(buildah from "$created_by"/void-voidbuilder)
trap 'buildah rm $voidbuild; [ -z "$void" ] || buildah rm $void' EXIT
if ! voidbuild_mount=$(buildah mount "$voidbuild")
then
    echo "Could not mount void-voidbuilder! Bailing" >&2
    exit 1
fi

# Build the final voidlinux container
void=$(buildah from scratch)
buildah mount "$void" >/dev/null

# Perhaps rsync here with a lot of excluded files instead of using buildah copy?
buildah copy "$void" "$voidbuild_mount"/target /

# Standard bootstrapping
buildah run "$void" -- sh -c "rm /var/cache/xbps && \
                              xbps-reconfigure -a && \
                              update-ca-certificates && \
                              xbps-install -Syu"

# Instead of adding this to noextract, just kill all of the possible bloat culprits
# This allows overriding (installing) these things if someone does desire, in a container 
# instance, instead of always excluding them from xbps extraction with noextract.
buildah run "$void" -- sh -c "rm -rvf /usr/share/X11/* && \
                              rm -rvf /usr/share/info/* && \
                              rm -rvf /usr/share/doc/* && \
                              rm -rvf /usr/share/man/*"
# Here's where the current cleanup happens, dirty style.
glibc_tags="^(latest|locales|default)$"
if [[ "${tag}" =~  $glibc_tags ]]
then
    # Retains only en_US, C, and POSIX glibc-locale files/functionality
    buildah run "$void" -- sh -c "sed -i 's/^#en_US/en_US/' /etc/default/libc-locales && \
                                  xbps-reconfigure -f glibc-locales && \
                                  ls -d /usr/share/locale/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -rf && \
                                  ls /usr/share/i18n/locales/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f && \
                                  ls /usr/share/i18n/charmaps/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f && \
                                  rm -rf /usr/lib/gconv/[BCDEFGHIJKLMNOPQRSTVZYZ]* && \
                                  rm -rf /usr/lib/gconv/lib* && \
                                  xbps-remove -y runit-void gawk base-minimal && \
                                  xbps-install -y mawk"
fi

# Make sure everything is up to date, then kill the package cache
buildah run "$void" -- sh -c "xbps-install -Sy mawk && \
                              rm -vfr /var/cache/xbps"

buildah unmount "$voidbuild" >/dev/null

# Set up environment
buildah config --env "TERM=linux" "$void"

# This will be the container's default entrypoint (What it runs)
buildah config --entrypoint '[ "/bin/sh" ]' "$void" 

# Metadata
buildah config --created-by "$created_by" "$void"
buildah config --author "$author" --label name=voidlinux "$void"

# Cleanup
buildah unmount "$void"

# Commit voidlinux container
buildah commit "$void" "$created_by"/voidlinux:${tag}

# NOTE: The trap above will remove the temporary build container ($void).
