#!/data/data/com.termux/files/usr/bin/bash
# Lightpanda 1.0.3 on Android, through Termux.
#
# Lightpanda is a headless browser (no screen, no tabs): it loads pages, runs their JavaScript and
# either prints the result or speaks the Chrome DevTools Protocol so Puppeteer/Playwright scripts
# and AI agents can drive it. The official Linux build is linked against glibc, which Android does
# not have, so this runs that official binary through Termux's glibc-runner (`grun`).
#
# Lightpanda is AGPL-3.0: https://github.com/lightpanda-io/browser
set -euo pipefail

VERSION="${LIGHTPANDA_VERSION:-1.0.3}"
ASSET="lightpanda-aarch64-linux"
URL="${LIGHTPANDA_URL:-https://github.com/lightpanda-io/browser/releases/download/${VERSION}/${ASSET}}"

# SHA-256 of the official 1.0.3 aarch64 binary (74,485,832 bytes). Checked after download so a
# truncated or altered file is never installed. Other versions are installed unchecked.
PINNED_VERSION="1.0.3"
PINNED_SHA256="20a5348bf3b6f71e41088223b188552ab550c1b9c9a9cbd8f099e6f7f3d78549"

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
DEST_DIR="${HOME:?HOME is not set}/.lightpanda"
REAL="$DEST_DIR/lightpanda-$VERSION"
WRAPPER="$PREFIX/bin/lightpanda"

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname -m)" = "aarch64" ] || die "this build is for 64-bit ARM phones (aarch64); this device reports $(uname -m)"
command -v pkg >/dev/null 2>&1 || die "run this inside Termux (from F-Droid or GitHub, not the Play Store build)"

echo "==> Installing glibc support (glibc-repo, glibc-runner)"
pkg install -y glibc-repo
pkg install -y glibc-runner curl
command -v grun >/dev/null 2>&1 || die "grun is missing after installing glibc-runner"

echo "==> Downloading Lightpanda $VERSION"
mkdir -p "$DEST_DIR"
part="$REAL.part"
rm -f "$part"
curl -fL --retry 3 --retry-delay 2 -o "$part" "$URL" || { rm -f "$part"; die "download failed: $URL"; }

got="$(sha256sum "$part" | cut -d' ' -f1)"
if [ "$VERSION" = "$PINNED_VERSION" ]; then
  if [ "$got" != "$PINNED_SHA256" ]; then
    rm -f "$part"
    die "checksum mismatch (got $got, expected $PINNED_SHA256); the download is damaged or not the official file"
  fi
  echo "    checksum OK"
else
  echo "    version $VERSION is not pinned; its SHA-256 is $got"
fi

chmod 0755 "$part"
mv -f "$part" "$REAL"

echo "==> Creating the lightpanda command"
cat > "$WRAPPER.new" <<EOF
#!$PREFIX/bin/bash
# Runs Lightpanda $VERSION (official glibc build) through Termux's glibc-runner.
# Lightpanda sends usage telemetry unless LIGHTPANDA_DISABLE_TELEMETRY is set (any value);
# this wrapper sets it. To leave telemetry on, run: LIGHTPANDA_KEEP_TELEMETRY=1 lightpanda ...
unset LD_PRELOAD
if [ -z "\${LIGHTPANDA_KEEP_TELEMETRY:-}" ]; then
  export LIGHTPANDA_DISABLE_TELEMETRY=true
fi
exec grun "$REAL" "\$@"
EOF
chmod 0755 "$WRAPPER.new"
mv -f "$WRAPPER.new" "$WRAPPER"

cat > "$PREFIX/bin/lightpanda-serve" <<EOF
#!$PREFIX/bin/bash
# Starts Lightpanda's CDP server on 127.0.0.1:9222 and keeps the phone awake while it runs.
# Point Puppeteer/Playwright at ws://127.0.0.1:9222. Extra arguments are passed through.
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock
trap 'command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock' EXIT
"$WRAPPER" serve --host 127.0.0.1 --port 9222 "\$@"
EOF
chmod 0755 "$PREFIX/bin/lightpanda-serve"

echo "==> Checking that it starts"
if ! "$WRAPPER" version; then
  cat >&2 <<EOF

Lightpanda is installed but did not start. This binary needs glibc 2.38 or newer.
Update Termux's packages (this brings the newest glibc) and run the installer again:
  pkg update && pkg upgrade
EOF
  exit 1
fi

cat <<EOF

Installed. Try:
  lightpanda fetch --dump https://example.com     print a page after its JavaScript has run
  lightpanda-serve                                CDP server on ws://127.0.0.1:9222
  lightpanda mcp                                  MCP server for AI agents
Remove with:  rm "$WRAPPER" "$PREFIX/bin/lightpanda-serve"; rm -rf "$DEST_DIR"
EOF
