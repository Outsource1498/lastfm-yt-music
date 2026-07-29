#!/usr/bin/env bash
#
# Local WSL/Ubuntu build script for lastfm-yt-music
# Builds the Last.fm YouTube Music tweak and injects it into a clean IPA.
#
# Usage:
#   cd /path/to/lastfm-yt-music
#   CLEAN_IPA_URL="https://.../YouTubeMusic.ipa" ./build.sh
#
#   # Build only the dylib/deb (no injection)
#   ./build.sh --dylib-only
#
# Environment variables:
#   LASTFM_API_KEY   - Last.fm API key (default in script)
#   LASTFM_API_SECRET- Last.fm API secret (default in script)
#   CLEAN_IPA_URL    - URL to a clean decrypted YouTube Music IPA
#   OUTPUT           - Output IPA name (default: YouTubeMusic_LastFM.ipa)
#   THEOS            - Theos install path (default: ~/theos)

set -euo pipefail

DYLIB_ONLY=0

# ── Configuration ─────────────────────────────────────────
LASTFM_API_KEY="${LASTFM_API_KEY:-3a786bb0ba066718c083ab3c316e7585}"
LASTFM_API_SECRET="${LASTFM_API_SECRET:-69dc74de5bb43846ac88573c243e4a0a}"
CLEAN_IPA_URL="${CLEAN_IPA_URL:-}"
OUTPUT="${OUTPUT:-YouTubeMusic_LastFM.ipa}"
THEOS="${THEOS:-$HOME/theos}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TWEAK_DIR="$SCRIPT_DIR/tweak-source"
WORK_DIR="$SCRIPT_DIR/work"

echo "========================================"
echo " Last.fm YouTube Music - Local WSL Build"
echo "========================================"
echo ""

# ── Helper functions ─────────────────────────────────────
command_exists() {
    command -v "$1" &> /dev/null
}

apt_install() {
    if ! command_exists apt-get; then
        echo "[!] This script only supports Debian/Ubuntu/WSL systems with apt."
        exit 1
    fi
    echo "[*] Installing required packages..."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential fakeroot rsync curl perl zip unzip git \
        libxml2-utils python3 python3-pip python3-venv \
        libtinfo6
    # Older Theos toolchain binaries may still link against libtinfo5.
    # Try to install it, but don't fail if the distro doesn't provide it.
    sudo apt-get install -y libtinfo5 || true
}

# ── 1. Dependencies ───────────────────────────────────────
setup_deps() {
    if ! command_exists clang || ! command_exists make || ! command_exists python3 || ! command_exists git; then
        apt_install
    fi
}

# ── 2. Theos setup ────────────────────────────────────────
setup_theos() {
    echo ""
    echo "[*] Setting up Theos at $THEOS..."
    export THEOS

    if [ ! -d "$THEOS/.git" ]; then
        echo "[*] Cloning Theos..."
        git clone --recursive --depth 1 https://github.com/theos/theos.git "$THEOS"
    else
        echo "[*] Theos already cloned."
    fi

    if [ ! -d "$THEOS/sdks/" ] || [ -z "$(ls -A "$THEOS/sdks/" 2>/dev/null | grep -i sdk || true)" ]; then
        echo "[*] Installing iOS SDK..."
        "$THEOS/bin/install-sdk" latest
    else
        echo "[*] iOS SDK already installed."
    fi

    if [ ! -f "$THEOS/toolchain/linux/iphone/bin/clang" ]; then
        echo "[*] Installing iOS toolchain for Linux..."
        mkdir -p "$THEOS/toolchain/linux/iphone"
        local arch
        arch="$(uname -m)"
        curl -sL "https://github.com/L1ghtmann/llvm-project/releases/latest/download/iOSToolchain-${arch}.tar.xz" | \
            tar -xJvf - -C "$THEOS/toolchain/"
    else
        echo "[*] iOS toolchain already installed."
    fi

}

# ── 3. Cyan (injector) setup ─────────────────────────────
setup_cyan() {
    echo ""
    echo "[*] Setting up cyan..."
    if ! command_exists cyan && ! python3 -m cyan --version &>/dev/null; then
        python3 -m pip install --user --upgrade pip
        python3 -m pip install --user --force-reinstall \
            "https://github.com/asdfzxcvbn/pyzule-rw/archive/main.zip"
    fi
    echo "[*] Cyan ready."
}

# ── 4. Build the tweak ────────────────────────────────────
build_tweak() {
    echo ""
    echo "[*] Building LastFMYouTubeMusic.dylib..."

    rm -rf "$TWEAK_DIR"
    git clone --depth 1 https://github.com/marioparaschiv/lastfm-yt-music.git "$TWEAK_DIR"

    echo "[*] Injecting API keys..."
    sed -i "s/LASTFM_API_KEY = xxx/LASTFM_API_KEY = ${LASTFM_API_KEY}/g" "$TWEAK_DIR/Makefile"
    sed -i "s/LASTFM_API_SECRET = xxx/LASTFM_API_SECRET = ${LASTFM_API_SECRET}/g" "$TWEAK_DIR/Makefile"

    echo "[*] Compiling..."
    (
        cd "$TWEAK_DIR"
        make clean package FINALPACKAGE=1
    )

    echo "[*] Extracting dylib..."
    mkdir -p "$WORK_DIR"
    rm -rf "$WORK_DIR/extracted"
    mkdir -p "$WORK_DIR/extracted"
    local deb_file
    deb_file="$(ls "$TWEAK_DIR"/packages/*.deb | head -1)"
    dpkg-deb -x "$deb_file" "$WORK_DIR/extracted/"

    local dylib
    dylib="$(find "$WORK_DIR/extracted" -name "LastFMYouTubeMusic.dylib" | head -1)"
    if [ -z "$dylib" ]; then
        echo "[!] Dylib not found in built .deb package."
        exit 1
    fi
    cp "$dylib" "$SCRIPT_DIR/LastFMYouTubeMusic.dylib"
    echo "[*] Dylib built: $SCRIPT_DIR/LastFMYouTubeMusic.dylib"
}

# ── 5. Obtain clean IPA ──────────────────────────────────
get_ipa() {
    echo ""
    if [ -n "$CLEAN_IPA_URL" ]; then
        echo "[*] Downloading clean IPA from URL..."
        curl -L -o "$WORK_DIR/YouTubeMusic_Clean.ipa" "$CLEAN_IPA_URL"
    elif [ -f "$SCRIPT_DIR/YouTubeMusic.ipa" ]; then
        echo "[*] Using local YouTubeMusic.ipa..."
        cp "$SCRIPT_DIR/YouTubeMusic.ipa" "$WORK_DIR/YouTubeMusic_Clean.ipa"
    else
        echo "[!] No CLEAN_IPA_URL provided and no YouTubeMusic.ipa found."
        echo "    Set CLEAN_IPA_URL or place a clean decrypted IPA at $SCRIPT_DIR/YouTubeMusic.ipa"
        exit 1
    fi

    if ! file "$WORK_DIR/YouTubeMusic_Clean.ipa" | grep -qi "zip"; then
        echo "[!] Downloaded file does not appear to be a valid IPA/ZIP."
        file "$WORK_DIR/YouTubeMusic_Clean.ipa"
        exit 1
    fi
}

# ── 6. Inject dylib ──────────────────────────────────────
inject() {
    echo ""
    echo "[*] Injecting dylib into IPA..."
    rm -f "$SCRIPT_DIR/$OUTPUT"
    python3 -m cyan -i "$WORK_DIR/YouTubeMusic_Clean.ipa" -o "$SCRIPT_DIR/$OUTPUT" \
         -f "$SCRIPT_DIR/LastFMYouTubeMusic.dylib" --overwrite

    if [ ! -f "$SCRIPT_DIR/$OUTPUT" ]; then
        echo "[!] Injection failed: $OUTPUT was not created."
        exit 1
    fi

    echo ""
    echo "========================================"
    echo " ✅ Done! Output: $SCRIPT_DIR/$OUTPUT"
    echo "========================================"
    ls -lh "$SCRIPT_DIR/$OUTPUT"
}

# ── Main ─────────────────────────────────────────────────
main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                echo "Usage: CLEAN_IPA_URL=... ./build.sh [--dylib-only]"
                echo ""
                echo "Options:"
                echo "  --dylib-only  Build and stop after the .dylib/.deb is produced."
                echo ""
                echo "Environment variables:"
                echo "  LASTFM_API_KEY, LASTFM_API_SECRET, CLEAN_IPA_URL, OUTPUT, THEOS"
                exit 0
                ;;
            --dylib-only)
                DYLIB_ONLY=1
                shift
                ;;
            *)
                echo "Unknown argument: $1"
                echo "Use --help for usage."
                exit 1
                ;;
        esac
    done

    mkdir -p "$WORK_DIR"

    setup_deps
    setup_theos
    build_tweak

    if [ "$DYLIB_ONLY" -eq 1 ]; then
        echo ""
        echo "========================================"
        echo " ✅ Dylib-only build complete."
        echo "    Output: $SCRIPT_DIR/LastFMYouTubeMusic.dylib"
        echo "    .deb:   $TWEAK_DIR/packages/*.deb"
        echo "========================================"
        ls -lh "$SCRIPT_DIR/LastFMYouTubeMusic.dylib"
        exit 0
    fi

    setup_cyan
    get_ipa
    inject
}

main "$@"
