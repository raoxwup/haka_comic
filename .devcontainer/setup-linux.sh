#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y \
  build-essential \
  clang \
  cmake \
  curl \
  file \
  git \
  libblkid1 \
  libepoxy0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libgtk-3-dev \
  liblzma5 \
  liblzma-dev \
  libsecret-1-0 \
  libsqlite3-0 \
  libsqlite3-dev \
  libstdc++6 \
  libstdc++-12-dev \
  ninja-build \
  pkg-config \
  ruby \
  ruby-dev \
  unzip \
  xz-utils \
  zip

if ! command -v fpm >/dev/null 2>&1; then
  sudo gem install fpm --no-document
fi
