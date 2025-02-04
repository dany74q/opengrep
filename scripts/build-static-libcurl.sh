#!/usr/bin/env bash

# Libcurl is the library for curl. Semgrep depends on it at runtime because it
# uses an backend relying on curl to send OpenTelemetry traces.
#
# This script is necessary when building Semgrep in Alpine, since installing it
# via apk add causes problems build against some of curl's dependencies. It's
# easier to just download and build it ourselves.
# TODO: is this still true with our switch to Alpine 3.19?

set -eu

CURL_VERSION="8.5.0"

cd /tmp

curl -L "https://curl.se/download/curl-${CURL_VERSION}.tar.gz" | tar xz

cd /tmp/curl-${CURL_VERSION}

CURL_PREFIX_PATH="$1"
if [ -n "$CURL_PREFIX_PATH" ]; then
    mkdir -p "$CURL_PREFIX_PATH"
    CONFIGURE_PREFIX="--prefix=$CURL_PREFIX_PATH"
else
    CONFIGURE_PREFIX=""
fi

./configure --disable-shared --with-ssl --disable-ldap --without-brotli --without-nghttp2 --without-libidn2 --without-librtmp --disable-rtsp --disable-ipv6 $CONFIGURE_PREFIX

make install
