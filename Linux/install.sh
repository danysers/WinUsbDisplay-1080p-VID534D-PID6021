#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -Eeuo pipefail
export LC_ALL=C
BASE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_VERSION=1.0.0
SOURCE=/usr/src/ms912x-$PACKAGE_VERSION
KERNEL=$(uname -r)
DEPS=1
LOAD=1
CHECK=0
usage() {
    cat <<'EOF'
Instalar LinuxUsbDisplay MS912x para Ubuntu (534d:6021).
Uso: bash install.sh [--check] [--no-deps] [--no-load] [--kernel VERSION]
  --check       Verificar plataforma y fuentes sin modificar el sistema.
  --no-deps     No ejecutar apt; las dependencias deben estar instaladas.
  --no-load     Compilar e instalar sin cargar el modulo (pruebas/offline).
  --kernel      Kernel destino instalado; por defecto, el kernel en ejecucion.
EOF
}
for_arg=("$@")
while (($#)); do
    case "$1" in
        --check) CHECK=1 ;;
        --no-deps) DEPS=0 ;;
        --no-load) LOAD=0 ;;
        --kernel) [[ $# -ge 2 ]] || { usage >&2; exit 1; }; KERNEL=$2; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'Opcion desconocida: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
done
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ $(uname -s) == Linux ]] || die 'Ejecutar en Ubuntu/Linux, no en Windows.'
[[ $KERNEL =~ ^[0-9]+\.[0-9]+\.[0-9]+[-.a-zA-Z0-9+_]*$ ]] || die 'Kernel destino invalido.'
[[ -r /etc/os-release ]] || die 'No se encontro /etc/os-release.'
# shellcheck disable=SC1091
source /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
    *ubuntu*|*debian*) ;;
    *) die 'Este instalador requiere Ubuntu o una distribucion basada en Debian.' ;;
esac
command -v dpkg >/dev/null || die 'Falta dpkg.'
dpkg --compare-versions "${KERNEL%%-*}" ge 6.8 || die 'Requiere kernel 6.8 o posterior. En Ubuntu 22.04 use HWE 6.8.'
dpkg --compare-versions "${KERNEL%%-*}" lt 7.1 || die 'Kernel posterior a 7.0: requiere una nueva validacion del controlador.'
[[ $LOAD == 0 || $KERNEL == "$(uname -r)" ]] || die 'Para otro kernel use --no-load.'
if [[ $LOAD == 1 && $(uname -r) == *[Mm]icrosoft* ]]; then
    die 'WSL no es un escritorio Ubuntu nativo. Use Ubuntu con el adaptador USB conectado.'
fi
(cd "$BASE" && sha256sum --check --quiet SHA256SUMS) || die 'Las fuentes estan incompletas o modificadas. No se instalo nada.'
printf 'Sistema: %s | arquitectura: %s | kernel destino: %s\n' "${PRETTY_NAME:-$ID}" "$(uname -m)" "$KERNEL"
printf 'Fuentes verificadas. Base validada por compilacion en Ubuntu 24.04 amd64.\n'
if [[ $CHECK == 1 ]]; then
    [[ -d /lib/modules/$KERNEL/build ]] && echo 'Headers: disponibles.' || echo "Headers: se instalaran linux-headers-$KERNEL."
    if command -v lsusb >/dev/null; then
        lsusb -d 534d:6021 || echo 'Adaptador 534d:6021 no conectado (no impide instalar).'
    fi
    echo 'Comprobacion completada; no se modifico el sistema.'
    exit 0
fi
if ((EUID != 0)); then
    command -v sudo >/dev/null || die 'Ejecute este comando como root; falta sudo.'
    exec sudo bash "$BASE/install.sh" "${for_arg[@]}"
fi
exec 9>/run/lock/linuxusbdisplay.lock
flock -n 9 || die 'Ya hay una instalacion/desinstalacion en curso.'
[[ ! -L /var/log/ms912x-install.log ]] || die 'El archivo de log es un enlace simbolico.'
touch /var/log/ms912x-install.log
chmod 600 /var/log/ms912x-install.log
exec > >(tee -a /var/log/ms912x-install.log) 2>&1
echo "Inicio: $(date -Is)"
if [[ $DEPS == 1 ]]; then
    apt-get update
    apt-get install -y build-essential dkms kmod usbutils mokutil openssl "linux-headers-$KERNEL"
    if [[ $ID == ubuntu ]] && mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
        apt-get install -y shim-signed
    fi
fi
for cmd in dkms make gcc modprobe modinfo depmod install flock; do
    command -v "$cmd" >/dev/null || die "Falta $cmd. Instale las dependencias o quite --no-deps."
done
[[ -f /lib/modules/$KERNEL/build/Makefile ]] || die "Faltan headers del kernel $KERNEL."
# Some Ubuntu HWE headers require a newer compiler than the distro default.
compiler_header=/lib/modules/$KERNEL/build/include/generated/compile.h
if [[ -r $compiler_header ]]; then
    compiler=$(sed -n 's/.*\bgcc-\([0-9][0-9]*\).*/gcc-\1/p' "$compiler_header" | head -n 1)
    if [[ -n $compiler ]] && ! command -v "$compiler" >/dev/null; then
        [[ $DEPS == 1 ]] || die "Falta $compiler, utilizado por este kernel."
        apt-get install -y "$compiler"
    fi
fi

status=$(dkms status -m ms912x)
while IFS= read -r entry; do
    [[ -z $entry || $entry == "ms912x/$PACKAGE_VERSION,"* || $entry == "ms912x/$PACKAGE_VERSION:"* ]] ||
        die 'Hay otra version de ms912x en DKMS. Desinstalela con su instalador antes de continuar.'
done <<< "$status"
if [[ -z $status ]] && modinfo -k "$KERNEL" ms912x >/dev/null 2>&1; then
    die 'Ya hay un modulo ms912x instalado fuera de DKMS. Retire su instalacion anterior primero.'
fi
[[ ! -L $SOURCE ]] || die "$SOURCE es un enlace simbolico."
created=0
added=0
stage=''
cleanup() {
    code=$?
    trap - EXIT
    if [[ -n $stage && -d $stage ]]; then rm -rf -- "$stage"; fi
    if ((code != 0 && created)); then
        echo 'Fallo la instalacion. Revirtiendo el registro y las fuentes nuevas.'
        if [[ -f /var/lib/dkms/ms912x/$PACKAGE_VERSION/build/make.log ]]; then
            install -m 600 "/var/lib/dkms/ms912x/$PACKAGE_VERSION/build/make.log" /var/log/ms912x-build-failed.log
            echo 'Log de compilacion conservado: /var/log/ms912x-build-failed.log'
        fi
        if ((added)); then
            if ! dkms remove -m ms912x -v "$PACKAGE_VERSION" --all; then
                echo "No se pudo retirar DKMS; se conservan $SOURCE y el log para diagnostico."
                exit "$code"
            fi
        fi
        rm -rf -- "$SOURCE"
    fi
    exit "$code"
}
trap cleanup EXIT
if [[ -e $SOURCE ]]; then
    [[ -f $SOURCE/.linuxusbdisplay ]] || die 'Las fuentes existentes pertenecen a otra instalacion.'
    for file in "$BASE"/driver/*; do
        cmp -s "$file" "$SOURCE/$(basename "$file")" || die 'La misma version contiene fuentes diferentes. Desinstale primero.'
    done
else
    stage=$(mktemp -d /usr/src/.linuxusbdisplay.XXXXXX)
    chmod 755 "$stage"
    install -m 644 "$BASE"/driver/* "$stage/"
    printf '%s\n' "$PACKAGE_VERSION" > "$stage/.linuxusbdisplay"
    mv -- "$stage" "$SOURCE"
    stage=''
    created=1
fi
if [[ -z $status ]]; then
    dkms add -m ms912x -v "$PACKAGE_VERSION"
    added=1
fi
dkms build -m ms912x -v "$PACKAGE_VERSION" -k "$KERNEL"
dkms install -m ms912x -v "$PACKAGE_VERSION" -k "$KERNEL"
depmod "$KERNEL"

# The kernel installation has succeeded; preserve it if installing a helper fails.
created=0
install -d /usr/local/lib/linuxusbdisplay /usr/local/bin /usr/local/share/applications
install -m 755 "$BASE/uninstall.sh" /usr/local/lib/linuxusbdisplay/uninstall.sh
install -m 755 "$BASE/bin/ms912x-status" /usr/local/bin/ms912x-status
install -m 755 "$BASE/bin/ms912x-display" /usr/local/bin/ms912x-display
install -m 644 "$BASE/ms912x-display.desktop" /usr/local/share/applications/ms912x-display.desktop
install -m 644 "$BASE/README.md" /usr/local/lib/linuxusbdisplay/README.md
echo "DKMS instalado para $KERNEL. Se reconstruira en futuras actualizaciones compatibles."
if [[ $LOAD == 0 ]]; then
    echo 'No se cargo el modulo (--no-load).'
    exit 0
fi
if ! modprobe ms912x; then
    echo 'El controlador esta instalado, pero NO pudo cargarse.'
    if command -v mokutil >/dev/null; then
        mokutil --sb-state || true
        echo 'Si Secure Boot esta activo, registre la clave DKMS con mokutil y reinicie.'
        for cert in /var/lib/shim-signed/mok/MOK.der /var/lib/dkms/mok.pub; do
            [[ -f $cert ]] && printf 'Clave disponible (consulte README): sudo mokutil --import %q\n' "$cert"
        done
    fi
    echo 'Ejecute: sudo ms912x-status. Consulte /var/log/ms912x-install.log.'
    exit 2
fi
echo 'Modulo cargado. Conecte el adaptador y abra Configuracion > Pantallas.'
echo 'Seleccione 1920x1080. El modo 60 Hz no garantiza 60 cuadros por segundo por USB.'
echo 'Diagnostico: ms912x-status | Configurar: ms912x-display'
