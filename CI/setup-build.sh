#!/bin/bash
# SPDX-License-Identifier: MIT
set -eo pipefail

if [[ ${USE_GITHUB_FORKS:-false} == true ]]; then
    OE_BRANCH=${OE_BRANCH:-$CI_BRANCH}
    OE_URL=https://github.com/ahcbb6/openembedded-core.git
    BITBAKE_URL=https://github.com/ahcbb6/bitbake.git
    BITBAKE_BRANCH=$OE_BRANCH
else
    if [[ -n ${OE_BRANCH:-} && $OE_BRANCH != master && $OE_BRANCH != scarthgap ]]; then
        echo "Upstream oe_branch must be master or scarthgap; enable forks for other branches." >&2
        exit 1
    fi
    case "${OE_BRANCH:-$CI_BRANCH}" in
        scarthgap|scarthgap-next) OE_BRANCH=scarthgap; BITBAKE_BRANCH=2.8 ;;
        *) OE_BRANCH=master; BITBAKE_BRANCH=master ;;
    esac
    OE_URL=https://git.openembedded.org/openembedded-core
    BITBAKE_URL=https://git.openembedded.org/bitbake
fi
cd "$GITHUB_WORKSPACE"
git clone --depth 1 --branch "$OE_BRANCH" "$OE_URL" openembedded-core
git clone --depth 1 --branch "$BITBAKE_BRANCH" "$BITBAKE_URL" bitbake
{
    printf 'Machine: %s\nUpstream branch: %s\nBitBake branch: %s\n' "$MACHINE" "$OE_BRANCH" "$BITBAKE_BRANCH"
    for repository in source openembedded-core bitbake; do
        printf '%s: ' "$repository"
        git -C "$repository" rev-parse HEAD
    done
} | tee "$CI_ARTIFACTS/revisions.txt"

# shellcheck source=/dev/null
source openembedded-core/oe-init-build-env "$CI_BUILD_DIR"
bitbake-layers add-layer "$GITHUB_WORKSPACE/source"
cat >> conf/local.conf <<EOF
MACHINE = "$MACHINE"
DISTRO = "freertos"
DL_DIR = "$CI_DOWNLOADS"
SSTATE_DIR = "$CI_SSTATE"
SSTATE_MIRRORS = "file://.* file://$CI_SSTATE_MIRROR/PATH"
BB_HASHSERVE = ""
BB_SIGNATURE_HANDLER = "OEBasicHash"
INHERIT += "rm_work"
BB_DISKMON_DIRS = "STOPTASKS,\${TMPDIR},5G,100K HALT,\${TMPDIR},1G,1K"
EOF
printf '%s\n' "${EXTRA_LOCALCONF:-}" >> conf/local.conf
bitbake-layers show-layers
