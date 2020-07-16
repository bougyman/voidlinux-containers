Docker containers based on the [Void Linux](http://voidlinux.org) operating system.

## Why?

The de-facto container recommendation for docker builds and images is currently alpine linux images.
This limits containers to the musl-C library. While we embrace the musl library (as you can see by our
image selection), there are some cases where glibc is necessary or desired. Void Linux offers the option
of glibc or musl, with the added feature of libressl in place of openssl. Our container sizes are only
slightly larger then alpine (8.12MB vs 5.57MB for alpine), and offer the `xbps` package management system
instead of alpine's `apk`.

## Tags

* `bougyman/voidlinux:glibc-tiny` - Minimal image with busybox instead of coreutils, and every lib stripped
* `bougyman/voidlinux:latest` - The same as glibc-tiny
* `bougyman/voidlinux:tmux-tiny` - Minimal image with tmux, busybox instead of coreutils, and every lib stripped
* `bougyman/voidlinux:glibc-locales` - This image adds glibc-locales (only `en_US`, `C`, and `POSIX`) to the glibc-tiny image
* `bougyman/voidlinux:glibc` - base-minimal Void Linux install with glibc, unstripped, with coreutils. Basically a base Void Linux install
* `bougyman/voidlinux:musl` - This image uses musl instead of glibc (much smaller image). Not stripped, with coreutils
* `bougyman/voidlinux:musl-tiny` - Minimal musl image with busybox instead of coreutils, and every lib stripped. *Smallest image*
* `bougyman/voidlinux:musl-tmux-tiny` - Minimal musl image with tmux, busybox instead of coreutils, and every lib stripped.
* `bougyman/voidlinux:musl-ruby-tiny` - Minimal musl image with ruby 2.7.0, busybox instead of coreutils, and every lib stripped.

## Freshness

Void Linux is a "rolling release" distribution. Packages are updated frequently from upstream versions, and automatially
built at https://build.voidlinux.org. This offers developers the latest versions of popular languages, libraries, and
binaries.

### CI/CD

These images are built at least nightly at https://gitlab.com/bougyman/voidlinux-containers/-/pipelines, and published to
dockerhub via https://hub.docker.com/r/bougyman/voidlinux/builds
