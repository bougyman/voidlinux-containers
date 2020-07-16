#!/bin/bash
buildah run "$1" sh -c "echo 'gem: --no-document' > /target/etc/gemrc && rm -rvf /usr/lib/ruby/gems/2.7.0/cache/*"
