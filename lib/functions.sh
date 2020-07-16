#!/bin/bash

# author is simply the maintainer tag in image/container metadata
: "${author:=at hey dot com @bougyman}"
# created_by will be the prefix of the images, as well. i.e. bougyman/voidlinux
: "${created_by:=bougyman}"

: "${REPOSITORY:=https://alpha.us.repo.voidlinux.org}"
: "${ARCH:=x86_64}"
: "${BASEPKG:=base-minimal}"

: "${container_cmd:=/bin/sh}"
: "${striptags:=stripped|tiny}"
: "${glibc_locale_tags=glibc-locales|tmux}"

usage() { # {{{
    cat <<-EOT
    Usage: $0 <options>
        Options:
           -a ARCH - ARCH to use, (Default: x86_64)
                     See http://build.voidlinux.org for archs available
           -t TAG  - The name of the image. Defaults to ${ARCH}-latest
           -b PKG  - The name of the "base" package to install. Default: 'base-minimal'. Set to '' to not install base at all
           -c CMD  - The command to use for the default container command (Default: /bin/sh)
EOT
} # }}}

die() { # {{{
    local -i code
    code=$1
    shift
    if [ -n "$*" ]
    then
        echo "Error! => $*" >&2
    else
        echo "Error! => Exit code: ${code}"
    fi
    echo >&2
    usage >&2
    # shellcheck disable=SC2086
    exit $code
} # }}}

bud() { # {{{
    : "${buildah_count:=0}"
    ((buildah_count++))
    buildah "$@"
    buildah_err=$?
    if [ $buildah_err -ne 0 ]
    then
        echo "Buildah command #${buildah_count} failed, Bailing" >&2
        die $buildah_err
    fi
} # }}}

optparse() { # {{{
    while getopts :ha:t:b:c: opt # {{{
    do
        case $opt in
            a)
                ARCH=$OPTARG
                ;;
            t)
                tag=$OPTARG
                ;;
            b)
                BASEPKG=$OPTARG
                ;;
            c)
                container_cmd=$OPTARG
                ;;
            h)
                usage
                exit
                ;;
            \?)
                echo "Invalid option '${OPTARG}'" >&2
                usage >&2
                exit 27
                ;;
            :)
                echo "Option ${OPTARG} requires an argument" >&2
                usage >&2
                exit 28
                ;;
        esac
    done # }}}
    shift $((OPTIND-1))
    : "${tag:=${ARCH}_latest}"
    export tag author created_by REPOSITORY ARCH BASEPKG striptags glibc_locale_tags container_cmd
} # }}}
# vim: set foldmethod=marker et ts=4 sts=4 sw=4 :

