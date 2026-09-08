#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail
export LC_ALL=C
VERSION=1.0.0
SOURCE=/usr/src/ms912x-$VERSION
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    echo 'Uso: sudo bash uninstall.sh (desconecte antes el adaptador USB).'
    exit 0
fi
[[ $# == 0 ]] || { echo 'Opcion desconocida.' >&2; exit 1; }
if ((EUID != 0)); then exec sudo bash "$0"; fi
exec 9>/run/lock/linuxusbdisplay.lock
flock -n 9 || { echo 'Otra operacion esta en curso.' >&2; exit 1; }
[[ ! -L $SOURCE && -f $SOURCE/.linuxusbdisplay ]] || {
    echo 'No hay fuentes de esta distribucion instaladas; no se elimina nada.' >&2
    exit 1
}
if [[ -d /sys/module/ms912x ]]; then
    modprobe -r ms912x || {
        echo 'Modulo en uso. Desconecte el adaptador y cierre su sesion grafica antes de reintentar.' >&2
        exit 1
    }
fi
if command -v dkms >/dev/null && [[ -n $(dkms status -m ms912x -v "$VERSION") ]]; then
    dkms remove -m ms912x -v "$VERSION" --all
fi
rm -rf -- "$SOURCE"
rm -f /usr/local/bin/ms912x-status /usr/local/bin/ms912x-display
rm -f /usr/local/share/applications/ms912x-display.desktop
rm -f /usr/local/lib/linuxusbdisplay/README.md /usr/local/lib/linuxusbdisplay/uninstall.sh
rmdir /usr/local/lib/linuxusbdisplay 2>/dev/null || true
echo 'LinuxUsbDisplay desinstalado. Se conservan las dependencias, claves MOK y logs.'
