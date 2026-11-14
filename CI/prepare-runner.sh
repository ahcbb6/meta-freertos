#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

if [[ ${GITHUB_ACTIONS:-} != true || ${RUNNER_ENVIRONMENT:-} != github-hosted ]]; then
    echo "This cleanup is only intended for disposable GitHub-hosted runners." >&2
    exit 1
fi

df -h
sudo rm -rf -- /usr/local/lib/android /usr/share/dotnet /opt/ghc \
    /usr/local/.ghcup /usr/local/share/powershell /opt/hostedtoolcache/CodeQL
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential chrpath cpio debianutils diffstat file gawk git \
    iputils-ping libacl1 locales python3 python3-git python3-jinja2 \
    python3-pexpect python3-pip python3-subunit socat texinfo unzip wget \
    xz-utils zstd
sudo apt-get clean
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
sudo locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" >> "$GITHUB_ENV"
echo "LC_ALL=en_US.UTF-8" >> "$GITHUB_ENV"
mkdir -p "$CI_SSTATE" "$CI_DOWNLOADS" "$CI_ARTIFACTS"
df -h
