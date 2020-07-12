#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
. lib/functions.sh
optparse "$@"

export BASEPKG ARCH REPOSITORY author created_by tag
export BUILDAH_FORMAT=docker # Use docker instead of OCI format
export STORAGE_DRIVER=vfs # Use vfs because overlay on overlay in Docker is whack

export REGISTRY_AUTH_FILE=${HOME}/auth.json # Set registry file location
echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY" # Login to registry

: "${FQ_IMAGE_NAME:=docker://${CI_REGISTRY}/bougyman/voidlinux-containers/voidlinux}"

./buildah.sh
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"

export tag=${ARCH}-glibc-locales_latest
./buildah.sh -t x86_64-glibc-locales_latest
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"

export ARCH=x86_64-musl
export tag=x86_64-musl_latest
./buildah.sh -a x86_64-musl
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
echo "Pushing to ${FQ_IMAGE_NAME}:${tag}"
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
