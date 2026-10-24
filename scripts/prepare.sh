#!/bin/sh
# Set up build/openwrt: a worktree of the openwrt submodule with our patches,
# the hapcan feed and the configuration applied.
set -eu

REPO=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$REPO/build/openwrt
BASE=$(git -C "$REPO/openwrt" rev-parse HEAD)
VERSION=$(git -C "$REPO" describe --always --dirty --tags 2>/dev/null || echo unknown)

[ -e "$BUILD/.git" ] || git -C "$REPO/openwrt" worktree add --detach "$BUILD" "$BASE"

# Re-apply patches only when the base or the patches changed
STAMP=$(cat "$REPO"/patches/openwrt/*.patch | sha256sum | cut -c1-16)-$BASE
if [ "$(cat "$BUILD/.hapcan-patches" 2>/dev/null)" != "$STAMP" ]; then
	git -C "$BUILD" checkout -q --detach "$BASE"
	git -C "$BUILD" reset -q --hard
	git -C "$BUILD" -c user.name=hapcan-build -c user.email=build@localhost \
		am -q "$REPO"/patches/openwrt/*.patch
	echo "$STAMP" > "$BUILD/.hapcan-patches"
fi

cd "$BUILD"
{ cat feeds.conf.default; echo "src-link hapcan $REPO/feed"; } > feeds.conf
./scripts/feeds update -a >/dev/null
./scripts/feeds install -a >/dev/null

cp "$REPO/config/hapcan.diffconfig" .config
echo "CONFIG_VERSION_CODE=\"hapcan-$VERSION\"" >> .config
make defconfig >/dev/null

# Fail early if a package from the diffconfig did not make it into .config
grep '^CONFIG_.*=y$' "$REPO/config/hapcan.diffconfig" | while read -r opt; do
	grep -qx "$opt" .config || { echo "missing in .config: $opt" >&2; exit 1; }
done
echo "prepared $BUILD (openwrt $(git -C "$REPO/openwrt" describe --tags), hapcan-$VERSION)"
