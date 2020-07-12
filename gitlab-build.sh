#!/bin/bash
# CI build for github. Builds voidlinux images for x86_64, x84_64 with glibc-locales, and x86_64-musl.

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

# Build standard minimal voidlinux with glibc (no glibc-locales)
./buildah.sh
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
echo "Pushing to ${FQ_IMAGE_NAME}:${tag}"
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"
echo "Pushing to ${FQ_IMAGE_NAME}:latest"
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:latest"

# Build standard minimal voidlinux with glibc and glibc-locales
export tag=${ARCH}-glibc-locales_latest
./voidlinux.sh -t x86_64-glibc-locales_latest
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
echo "Pushing to ${FQ_IMAGE_NAME}:${tag}"
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"

# Build minimal voidlinux with musl (no glibc)
export ARCH=x86_64-musl
export tag=x86_64-musl_latest
./buildah.sh -a x86_64-musl
image_name="${created_by}/voidlinux:${tag}"
CONTAINER_ID=$(buildah from "${image_name}")
echo "Pushing to ${FQ_IMAGE_NAME}:${tag}"
buildah commit --squash "$CONTAINER_ID" "$FQ_IMAGE_NAME:${tag}"

# Trigger Docker Hub builds
curl -X POST -H "Content-Type: application/json" --data '{"source_type": "Branch", "source_name": "main"}' "$docker_hook"

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :
