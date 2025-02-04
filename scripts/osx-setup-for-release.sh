#!/usr/bin/env bash
set -eux

# Setup the environment under MacOS to build and release opengrep-core.

# history: there used to be a separate osx-m1-release.sh script
# that was mostly a copy of this file, but now the
# build steps are identical so we just have one script.

# Note that this script runs from a self-hosted CI runner which
# does not reset the environment between each run, so you may
# need to do more cleanup than usually necessary.

# bugfix: Answer yes to all opam questions. For example, if there is a
# pre-existing opam config from an old version, it will ask if we want to
# upgrade. Without this, that question will bring down the whole run.
export OPAMYES=true
export MACOSX_DEPLOYMENT_TARGET=10.10

HOMEBREW_PATH="$HOME/homebrew"
mkdir -p $HOMEBREW_PATH
curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C $HOMEBREW_PATH
export PATH="$HOMEBREW_PATH/bin:$PATH"

brew install opam
opam init --no-setup --bare

#coupling: this should be the same version than in our Dockerfile
SWITCH_NAME="${1:-5.2.1}"
if opam switch "${SWITCH_NAME}" 2>/dev/null; then
    # This happens because the self-hosted CI runners do not
    # cleanup things between each run.
    echo "Switch ${SWITCH_NAME} exists, continuing"
else
    echo "Switch ${SWITCH_NAME} doesn't yet exist, creating..."
    opam switch create "${SWITCH_NAME}"
    opam switch "${SWITCH_NAME}"
fi
eval "$(opam env)"

make install-deps-MACOS-for-semgrep-core
export LIBRARY_PATH="$(brew --prefix)/lib:${LIBRARY_PATH:-}"
make install-deps-for-semgrep-core

if [ -n "${GITHUB_ENV+set}" ]; then
    echo MACOSX_DEPLOYMENT_TARGET=10.10 >> "$GITHUB_ENV"
    echo "PATH=$PATH" >> "$GITHUB_ENV"
    echo "LIBRARY_PATH=${LIBRARY_PATH}" >> "$GITHUB_ENV"
    echo "PKG_CONFIG_PATH=$(brew --prefix)/lib/pkgconfig:$(brew --prefix)/opt/zlib/lib/pkgconfig:$HOME/curl-static/lib/pkgconfig:$(pwd)/libs/ocaml-tree-sitter-core/tree-sitter/lib/pkgconfig:${PKG_CONFIG_PATH:-}" >> "$GITHUB_ENV"
fi
