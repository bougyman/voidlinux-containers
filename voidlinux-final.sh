#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
source lib/functions.sh
optparse "$@"

# Import the void-based builder
image_name="${created_by}/void-voidbuilder:${ARCH}_latest"
voidbuild=$(buildah from "$image_name") || die 1 "Unable to build from ${image_name}"
trap 'buildah rm $voidbuild; [ -z "$void" ] || buildah rm $void' EXIT
voidbuild_mount=$(buildah mount "$voidbuild") || die 2 "Could not mount '$voidbuild', you may need to run in a buildah unshare session"

# Build the final voidlinux container
void=$(buildah from scratch) || die 3 "Could not build from scratch!"
bud mount "$void" >/dev/null

# Perhaps rsync here with a lot of excluded files instead of using buildah copy?
bud copy "$void" "$voidbuild_mount"/target /

# Standard bootstrapping
bud run "$void" -- sh -c "rm /var/cache/xbps && \
                              xbps-reconfigure -a && \
                              update-ca-certificates && \
                              xbps-install -Syu"

# Instead of adding this to noextract, just kill all of the possible bloat culprits
# This allows overriding (installing) these things if someone does desire, in a container 
# instance, instead of always excluding them from xbps extraction with noextract.
bud run "$void" -- sh -c "rm -rvf /usr/share/X11/* && \
                              rm -rvf /usr/share/info/* && \
                              rm -rvf /usr/share/doc/* && \
                              rm -rvf /usr/share/man/*"
# Here's where the current cleanup happens, dirty style.
glibc_tags=glibc-locales
if [[ "${tag}" =~  $glibc_tags ]]
then
    # Retains only en_US, C, and POSIX glibc-locale files/functionality
    bud run "$void" -- sh -c "xbps-install -y glibc-locales && \
                                  sed -i 's/^#en_US/en_US/' /etc/default/libc-locales && \
                                  xbps-reconfigure -f glibc-locales && \
                                  ls -d /usr/share/locale/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -rf && \
                                  ls /usr/share/i18n/locales/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f && \
                                  ls /usr/share/i18n/charmaps/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f" || \
                                      die "$buildah_count" "Failure setting up glibc-locales"
fi

bud run "$void" -- sh -c "rm -rvf /usr/lib/gconv/[BCDEFGHIJKLMNOPQRSTVZYZ]* && \
                              rm -rvf /usr/lib/gconv/lib*"
# Make sure everything is up to date, then kill the package cache
bud run "$void" -- sh -c "xbps-install -Sy mawk && \
                              rm -vfr /var/cache/xbps"

bud unmount "$voidbuild" >/dev/null

# Set up environment
bud config --env "TERM=linux" "$void"

# This will be the container's default CMD (What it runs)
bud config --cmd '[ "/bin/sh" ]' "$void"

# Metadata
bud config --created-by "$created_by" "$void"|| die "$buildah_count" "Error setting created-by"
bud config --author "$author" --label name=voidlinux "$void"|| die "$buildah_count" "Error setting author"

# Cleanup
bud unmount "$void"

# Commit voidlinux container
bud commit --squash "$void" "${created_by}/voidlinux:${tag}"

# NOTE: The trap above will remove the temporary build container ($void).
