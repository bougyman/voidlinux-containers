#!/bin/bash
# This builds all 3 images

# Brings in optparse(), die(), and bud()
# shellcheck source=lib/functions.sh
source lib/functions.sh
optparse "$@"
export BASEPKG ARCH REPOSITORY author created_by tag

./alpine-builder.sh && \
./void-builder.sh && \
./voidlinux-final.sh

