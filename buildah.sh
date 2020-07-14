#!/bin/bash
# This builds all 3 images. See Readme.adoc for details

# shellcheck source=lib/functions.sh
source lib/functions.sh # Brings in optparse(), usage(), die(), and bud() functions, and sets default env vars

# Parse command line options
optparse "$@"

# Export build variables
export BASEPKG ARCH REPOSITORY author created_by tag striptags glibc_tags container_cmd

# Build all 3 images
./alpine-builder.sh && \
./void-builder.sh && \
./voidlinux-final.sh
