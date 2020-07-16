Docker containers based on the [Void Linux](http://voidlinux.org) operating system.

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

These are built at least nightly.
