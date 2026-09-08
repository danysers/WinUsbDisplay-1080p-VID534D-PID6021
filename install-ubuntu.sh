#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Download and verify a fixed source release before invoking its installer.
set -Eeuo pipefail
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    echo 'Instalar LinuxUsbDisplay para Ubuntu: descarga verificada + instalacion DKMS.'
    echo 'Opciones: --check, --no-deps, --no-load, --kernel VERSION.'
    exit 0
fi
[[ $(uname -s) == Linux ]] || { echo 'Ejecute este comando en Ubuntu/Linux.' >&2; exit 1; }
RELEASE=LinuxUsbDisplay-Ubuntu-1.0.0
ARCHIVE_SHA256=ef4d52c70e88414bac1041fbfde50e8019844dc65ebaf3b85c64f09d48c1aba5
URL="https://raw.githubusercontent.com/danysers/WinUsbDisplay-1080p-VID534D-PID6021/main/releases/ubuntu-1.0.0/$RELEASE.tar.gz"
for command_name in mktemp sha256sum tar; do
    command -v "$command_name" >/dev/null || { echo "Falta $command_name." >&2; exit 1; }
done
WORK=$(mktemp -d -t linuxusbdisplay.XXXXXXXX)
trap 'rm -rf -- "$WORK"' EXIT
echo "Descargando $RELEASE..."
if command -v curl >/dev/null; then
    curl --fail --show-error --silent --location --proto '=https' --proto-redir '=https' \
        --connect-timeout 20 --max-time 180 --retry 2 "$URL" -o "$WORK/release.tar.gz"
elif command -v wget >/dev/null; then
    wget --https-only --timeout=30 --tries=3 -q "$URL" -O "$WORK/release.tar.gz"
else
    echo 'Falta curl o wget. Instale uno de ellos antes de continuar.' >&2
    exit 1
fi
printf '%s  %s\n' "$ARCHIVE_SHA256" "$WORK/release.tar.gz" | sha256sum --check --status || {
    echo 'ERROR: el paquete no coincide con la version publicada. No se ejecuto el instalador.' >&2
    exit 1
}
tar --extract --gzip --file "$WORK/release.tar.gz" --directory "$WORK" --no-same-owner
bash "$WORK/$RELEASE/install.sh" "$@"
