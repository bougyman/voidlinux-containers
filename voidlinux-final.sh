#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
source lib/functions.sh
optparse "$@"

# Import the void-based builder
if [[ "$tag" =~ $striptags ]]
then
    image_name="${created_by}/void-voidbuilder:${tag}"
else
    image_name="${created_by}/void-voidbuilder:${ARCH}_latest"
fi
voidbuild=$(buildah from "$image_name") || die 1 "Unable to build from ${image_name}"
# Do not remove build containers if we're debugging
if [ -z "$BUILDAH_DEBUG" ]
then
    trap 'buildah rm $voidbuild; [ -z "$void" ] || buildah rm $void' EXIT
fi

voidbuild_mount=$(buildah mount "$voidbuild") || die 2 "Could not mount '$voidbuild', you may need to run in a buildah unshare session"

# Build the final voidlinux container
void=$(buildah from scratch) || die 3 "Could not build from scratch!"
void_mount=$(buildah mount "$void") || die 4 "Cloud not mount '$void'"
echo "Void mount is '$void_mount'"

# Copy the base build to / of the container
bud copy "$void" "$voidbuild_mount"/target /


# Standard bootstrapping
bud run "$void" -- /usr/bin/sh -c "/usr/bin/rm /usr/share/man/* -rvf && \
                                   /usr/bin/rm -rvf /var/cache/xbps && \
                                   xbps-reconfigure -a"

if [[ "${tag}" =~ $glibc_locale_tags ]]
then
    # No need for this on musl
    if [[ ! "${ARCH}" =~ musl ]]
    then
        bud run "$void" -- /usr/bin/sh -c "xbps-reconfigure -f glibc-locales && \
                                           ls -d /usr/share/locale/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -rf && \
                                           ls /usr/share/i18n/locales/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f && \
                                           ls /usr/share/i18n/charmaps/* | egrep -v 'en_US|locale.alias|C|POSIX' | xargs rm -f"
    fi
fi
                                       
bud run "$void" -- sh -c "rm -rvf /usr/lib/gconv/[BCDEFGHIJKLMNOPQRSTVZYZ]* && \
                              rm -rvf /usr/lib/gconv/lib* && \
                              rm -vfr /var/cache/xbps"

bud unmount "$voidbuild" >/dev/null

# Set up environment
bud config --env "TERM=linux" "$void"

# This will be the container's default CMD (What it runs)
bud config --entrypoint '[]' "$void"
bud config --cmd "$container_cmd" "$void"

# Metadata
bud config --created-by "$created_by" "$void"
bud config --author "$author" --label name=voidlinux "$void"

# Cleanup
bud unmount "$void"

# Commit voidlinux container
bud commit --squash "$void" "${created_by}/voidlinux:${tag}"

# NOTE: The trap above will remove the temporary build container ($void).
