#!/bin/bash

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
. lib/functions.sh
optparse "$@"

export BASEPKG ARCH REPOSITORY author created_by tag
# export BUILDAH_FORMAT=docker If we want docker format
export STORAGE_DRIVER=vfs # Use vfs because overlay on overlay in Docker is whack

export REGISTRY_AUTH_FILE=${HOME}/auth.json # Set registry file location
echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY" # Login to registry
xbps-install -y buildah bash

./buildah.sh
