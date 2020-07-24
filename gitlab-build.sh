#!/bin/bash
# CI build for github. Builds various Void Linux based images. See Readme.md

# shellcheck source=lib/functions.sh
source lib/functions.sh # Brings in optparse(), usage(), die(), and bud() functions, and sets default env vars

# Parse command line options
optparse "$@"

export BASEPKG ARCH REPOSITORY author created_by tag
export BUILDAH_FORMAT=docker # Use docker instead of OCI format
export STORAGE_DRIVER=vfs # Use vfs because overlay on overlay in Docker is whack

declare -a published_tags
# Normally would not set this, but we definitely want any error to be fatal in CI
set -e

scan_image() { # {{{
    tag=$1
    [ -d /oci ] || mkdir -p /oci
    oci_path=/oci/${IMAGE_NAME}_${tag}
    buildah push "$IMAGE_NAME:$tag" "oci:/$oci_path"
    ./trivy --exit-code 0 --severity HIGH --no-progress image --input "$oci_path"
    ./trivy --exit-code 1 --severity CRITICAL --no-progress image --input "$oci_path"
} # }}}

build_image() { # {{{
    tag=$1
    shift
    ./buildah.sh -t "$tag" "$@"
    scan_image "$tag" || die 99 "Trivy scan failed!"
    published_tags+=( "$tag" )
} # }}}

build_image_from_builder() { # {{{
    tag=$1
    shift
    ./void-builder.sh -t "$tag" "$@"
    echo "Building final image for $tag" >&2
    ./voidlinux-final.sh -t "$tag" "$@"
    scan_image "$tag" || die 99 "Trivy scan failed!"
    published_tags+=( "$tag" )
} # }}}

# Build standard minimal voidlinux with glibc (no glibc-locales)
tag=${ARCH}_latest
build_image "$tag"

# Various other glibc variants
for tag in ${ARCH}-glibc-locales_latest glibc-locales-tiny glibc-tiny
do
    build_image_from_builder "$tag"
done

# Build tiny voidlinux with tmux, using glibc and busybox, no coreutils. Strip all libs
tag=tmux-tiny
build_image_from_builder "$tag" -b "tmux ncurses-base"

# Build minimal voidlinux with musl (no glibc)
export ARCH=x86_64-musl
tag=x86_64-musl_latest
build_image "$tag"

# Build tiny voidlinux with musl (no glibc) and busybox instead of coreutils
tag=musl-tiny
build_image_from_builder "$tag"

# Build voidlinux with tmux, using musl and coreutils. Unstripped
tag=musl-tmux
build_image_from_builder "$tag" -b "base-minimal tmux ncurses-base" -c "/usr/bin/tmux"

# Build tiny voidlinux with tmux, using musl and busybox, no coreutils. Strip all libs
tag=musl-tmux-tiny
build_image_from_builder "$tag" -b "tmux ncurses-base" -c "/usr/bin/tmux"

# Build tiny voidlinux with ruby, using musl and busybox, no coreutils. Strip all libs
tag=musl-ruby-tiny
build_image_from_builder "$tag" -b "ruby"

# publish images _only_ if we're run in CI. This allows us to mimic the whole
# build locally in the exact manner the CI builder does, without any publishing to registries
if [ -n "$CI_REGISTRY_PASSWORD" ] # {{{
then
    export REGISTRY_AUTH_FILE=${HOME}/auth.json # Set registry file location
    echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY" # Login to registry
    
    : "${FQ_IMAGE_NAME:=docker://${CI_REGISTRY}/bougyman/voidlinux-containers/voidlinux}"

    set +x
    # Push everything to the registry
    for tag in "${published_tags[@]}"
    do
        echo "Publishing $tag"
        podman push "bougyman/voidlinux:${tag}" "$FQ_IMAGE_NAME:${tag}"
    done

    # Push the glibc-tiny image as the :latest tag TODO: find a way to tag this instead of committing a new image signature for it
    echo "Publishing :latest tag for glibc-tiny"
    podman push "bougyman/voidlinux:glibc-tiny" "$FQ_IMAGE_NAME:latest"

    # Trigger Docker Hub builds, "$docker_hook" is supplied by gitlab, defined in this project's CI/CD "variables"
    # shellcheck disable=SC2154
    curl -X POST -H "Content-Type: application/json" --data '{"source_type": "Branch", "source_name": "main"}' "$docker_hook" || \
        die 33 "Failed to trigger docker build"
    echo
    # Show us all the images built
    buildah images
fi # }}}

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
