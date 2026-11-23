#!/usr/bin/env bash
# Puts `weft` on the PATH: the prebuilt binary of a release, or, when there is none, a build from source.
set -euo pipefail

version="${WEFT_VERSION:-latest}"
repo="weft-sdk/weft"
dest="${RUNNER_TEMP:-/tmp}/weft-bin"
mkdir -p "$dest"

case "${RUNNER_OS:-$(uname -s)}-${RUNNER_ARCH:-$(uname -m)}" in
  Linux-X64 | Linux-x86_64) target="x86_64-unknown-linux-gnu"; ext="tar.gz" ;;
  Linux-ARM64 | Linux-aarch64) target="aarch64-unknown-linux-gnu"; ext="tar.gz" ;;
  macOS-X64 | Darwin-x86_64) target="x86_64-apple-darwin"; ext="tar.gz" ;;
  macOS-ARM64 | Darwin-arm64) target="aarch64-apple-darwin"; ext="tar.gz" ;;
  Windows-X64 | MINGW*-* | MSYS*-*) target="x86_64-pc-windows-msvc"; ext="zip" ;;
  *) target="" ;;
esac

install_prebuilt() {
  [ -n "$target" ] || return 1
  local base
  if [ "$version" = "latest" ]; then
    base="https://github.com/${repo}/releases/latest/download"
  else
    base="https://github.com/${repo}/releases/download/${version}"
  fi
  local file="weft-${target}.${ext}"
  echo "Downloading ${base}/${file}"
  curl --fail --silent --show-error --location --retry 3 -o "${dest}/${file}" "${base}/${file}" || return 1
  if [ "$ext" = "zip" ]; then
    unzip -q -o "${dest}/${file}" -d "$dest" || return 1
  else
    tar -xzf "${dest}/${file}" -C "$dest" || return 1
  fi
  local bin_dir="${dest}/weft-${target}"
  [ -d "$bin_dir" ] || return 1
  echo "$bin_dir" >> "${GITHUB_PATH:-/dev/null}"
  export PATH="$bin_dir:$PATH"
}

install_from_source() {
  echo "No release to download. Building weft from source (this takes a few minutes)."
  local ref_args=()
  if [ "$version" != "latest" ]; then ref_args=(--tag "$version"); fi
  cargo install --git "https://github.com/${repo}" weft-cli --locked --root "$dest/cargo" "${ref_args[@]}"
  echo "$dest/cargo/bin" >> "${GITHUB_PATH:-/dev/null}"
  export PATH="$dest/cargo/bin:$PATH"
}

install_prebuilt || install_from_source
weft --version
