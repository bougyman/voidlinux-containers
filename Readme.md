Docker containers based on the [Void Linux](http://voidlinux.org) operating system.

## Tags

* `bougyman/voidlinux:x86_64_latest` - The latest glibc (without glibc-locales) image
* `bougyman/voidlinux:latest` - The same as above
* `bougyman/voidlinux:glibc-tiny` - Minimal image with busybox instead of coreutils, and every lib stripped
* `bougyman/voidlinux:x86_64-glibc-locales_latest` - This image adds glibc-locales (only `en_US`, `C`, and `POSIX`)
* `bougyman/voidlinux:x86_64-musl_latest` - This image uses musl instead of glibc (much smaller image)
* `bougyman/voidlinux:musl-tiny` - Minimal musl image with busybox instead of coreutils, and every lib stripped. Smallest image

These are built at least nightly.
