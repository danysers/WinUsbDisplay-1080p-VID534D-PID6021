# LinuxUsbDisplay 1080p para Ubuntu

Controlador Linux para el adaptador USB a HDMI **MacroSilicon `534d:6021`**.
Incluye fuentes C, instalación DKMS, diagnóstico y desinstalación. Versión **1.0.0**.

Desarrollado a partir del controlador abierto [rhgndf/ms912x](https://github.com/rhgndf/ms912x),
con una capa de compatibilidad para kernels de Ubuntu. No usa Wine ni los binarios
Windows. El código del controlador conserva su licencia **GPL-2.0-only**;
los scripts propios son MIT. Consulte [UPSTREAM.md](UPSTREAM.md).

**Estado:** compilación y pruebas de instalación en contenedor Ubuntu verificadas;
la salida de video con el adaptador físico todavía no está validada. No se promete
una tasa de cuadros ni compatibilidad de todas las revisiones del chip.

## Instalación rápida

Puede instalar directamente desde una terminal Ubuntu, sin descargar el ZIP:

```bash
wget -qO- https://raw.githubusercontent.com/danysers/WinUsbDisplay-1080p-VID534D-PID6021/main/install-ubuntu.sh | bash
```

El script descarga el paquete 1.0.0 y verifica un SHA-256 fijado antes de ejecutarlo.
Requiere Internet y solicitará su contraseña con `sudo`. Si usa `curl`, sustituya
`wget -qO-` por `curl -fsSL`. Secure Boot puede requerir el registro de MOK y un
reinicio; ese paso físico no puede completarlo el comando.

Para instalar desde un archivo descargado:

1. Copie y extraiga `LinuxUsbDisplay-Ubuntu-1.0.0.tar.gz` en su equipo Ubuntu.
2. Abra una terminal dentro de la carpeta extraída y ejecute:

   ```bash
   bash install.sh
   ```

   Si usa el repositorio completo, ejecute `bash Linux/install.sh` desde su raíz.
   Se solicitará la contraseña de administrador mediante `sudo`. Hace falta Internet
   para descargar dependencias de los repositorios de Ubuntu, pero las fuentes del
   controlador ya están incluidas; no se descarga código de una rama cambiante.

3. Conecte el adaptador con el cable HDMI y el monitor encendido. Abra
   **Configuración → Pantallas**, o busque **Pantalla USB MS912x** en las aplicaciones.
4. Active la pantalla, elija **1920 × 1080** y seleccione extender o duplicar.
   Si la sesión no descubre la nueva tarjeta DRM, cierre sesión y vuelva a entrar.

No necesita instalar el software Windows ni un controlador DisplayLink.

## Sistemas y funciones

| Entorno | Estado |
| --- | --- |
| Ubuntu 24.04, amd64, kernel GA 6.8 | Compilación y ciclo DKMS comprobados; falta prueba física |
| Ubuntu 24.04, amd64, kernel HWE 7.0 disponible al preparar el paquete | Compilación y ciclo DKMS comprobados; falta prueba física |
| Kernels intermedios de la serie 6.x posteriores a 6.8 | Capa de compatibilidad incluida; no todos comprobados |
| Ubuntu 22.04 con HWE 6.8; derivados Debian/Ubuntu | Candidatos compatibles; instalación completa no validada en esas distribuciones |
| Kernel 5.15 y anteriores a 6.8; posteriores a 7.0 | El instalador los rechaza |
| ARM64 u otras arquitecturas | Fuentes disponibles; compilación no validada |
| WSL o máquina virtual sin acceso USB directo | No sirven para validar el monitor físico |

El módulo se integra mediante **DRM/KMS**. La detección, disposición, duplicado y
rotación dependen del compositor (GNOME/Wayland, Xorg, etc.) y de su GPU. Si Wayland
no muestra la pantalla, pruebe una sesión Xorg si su Ubuntu la ofrece. No se modifica
automáticamente GDM, Xorg, la orientación, el monitor principal ni el plan de energía.

El driver transmite regiones modificadas del framebuffer, convierte XRGB8888 a
UYVY y mantiene dos buffers de transferencia. El enlace del adaptador `534d:6021`
es USB 2.0: **60 Hz de señal HDMI no equivalen a 60 FPS reales**. Bajar a 1280 × 720
puede reducir el tráfico para contenidos con mucho movimiento. No hay mediciones
locales de FPS de esta versión Linux. El perfil Windows `config.ini` no se aplica aquí.

La tabla de modos incluye 1080p; solo se ofrecen los modos que el controlador y el
monitor admitan. La lectura EDID fallida utiliza modos de respaldo de upstream.
El audio de interfaces USB separadas queda a cargo del sistema; este proyecto no
implementa un controlador de audio nuevo. Otros IDs de upstream se conservan,
pero este paquete se enfoca en `534d:6021`.

## Secure Boot

DKMS utiliza la configuración de firma de su distribución. Si la clave ya está
registrada, no necesita pasos adicionales. Si `modprobe` informa `Key was rejected
by service`, el código está instalado pero el firmware todavía no confía en su firma.
El instalador finaliza con **código 2**, conserva la instalación y muestra diagnóstico.

En Ubuntu normalmente la clave está en `/var/lib/shim-signed/mok/MOK.der`. En otras
configuraciones DKMS puede usar `/var/lib/dkms/mok.pub`. Confirme la ruta en la salida
de la compilación DKMS (`Public certificate (MOK)`) y registre **esa** clave:

```bash
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
```

Si DKMS indicó otra ruta, sustitúyala. Defina la contraseña temporal solicitada,
reinicie y, en la pantalla de MOK Manager, elija **Enroll MOK → Continue → Yes** e
introduzca esa contraseña. Luego:

```bash
sudo modprobe ms912x
ms912x-status
```

No se desactiva Secure Boot y el instalador no modifica claves del firmware. Esa
confirmación al reiniciar debe realizarse físicamente en Ubuntu. Referencia:
[documentación oficial de Ubuntu](https://documentation.ubuntu.com/security/security-features/platform-protections/secure-boot/).

## Diagnóstico

```bash
ms912x-status
sudo ms912x-status     # añade mensajes del kernel
```

Desde la carpeta descargada, sin instalar: `bash bin/ms912x-status`.

El informe muestra el kernel, el estado de DKMS, la firma del módulo, si está
cargado, el puerto USB, la velocidad negociada y los conectores DRM de ms912x.
No adjunta automáticamente nada ni envía información por Internet.

| Síntoma | Qué revisar |
| --- | --- |
| No aparece `534d:6021` | Cable/puerto USB; conectar directamente sin hub |
| Faltan `linux-headers-...` | Arranque un kernel oficial de Ubuntu con headers disponibles; actualice y reinicie si el kernel antiguo ya no está en los repositorios |
| La compilación falla | `/var/log/ms912x-build-failed.log` tras rollback; si se conservó DKMS: `/var/lib/dkms/ms912x/1.0.0/build/make.log`; log general: `/var/log/ms912x-install.log` |
| Instalado pero no cargado | `sudo modprobe ms912x`; revise Secure Boot y `sudo ms912x-status` |
| Interfaz USB usa otro driver | Retire el otro paquete ms912x/ms91xx antes de instalar; no se fuerza el reemplazo |
| Módulo cargado y pantalla ausente | Monitor encendido, HDMI bien conectado, cerrar sesión/reconectar; revisar detección/EDID en el diagnóstico |
| Cortes bajo carga | USB directo, probar 720p; recopilar errores del kernel |
| Imagen dividida, colores incorrectos o bloqueo | Desconectar el adaptador y recopilar el diagnóstico; esa revisión de hardware puede requerir adaptar el protocolo |

## Desinstalación

Desconecte primero el adaptador y ejecute:

```bash
sudo bash uninstall.sh
```

También puede desinstalar sin la carpeta descargada:

```bash
sudo bash /usr/local/lib/linuxusbdisplay/uninstall.sh
```

Se retira esta versión de DKMS, sus fuentes y sus herramientas. Se conservan
dependencias, claves MOK y logs. Si el módulo está en uso, la operación se detiene
antes de retirar los archivos. No se eliminan otras versiones de DKMS.

## Instalación avanzada y desarrollo

```bash
bash install.sh --check                       # no modifica el sistema
sudo bash install.sh --no-deps                # dependencias preinstaladas
sudo bash install.sh --kernel 6.8.0-139-generic --no-load
make -C driver KVER=6.8.0-139-generic          # compilar sin instalar
```

Sustituya la versión de kernel por una instalada en `/lib/modules`. La opción
`--kernel` se pasa hasta Kbuild: no compila accidentalmente contra `uname -r`.
DKMS puede reconstruir el módulo para nuevos kernels, pero cambios futuros en la
API pueden exigir una actualización de este código.

Una segunda instalación idéntica reutiliza las fuentes. Si ya hay otra versión
o el mismo número de versión tiene otro contenido, se detiene sin reemplazarla.
Los fallos de compilación de una instalación nueva retiran su registro y sus
fuentes; un fallo de carga conserva el módulo para resolver Secure Boot.

`SHA256SUMS` detecta archivos corruptos o modificados accidentalmente; no es una
firma de autenticidad. Al modificar fuentes, regenérelo conscientemente desde el
repositorio con `python tools/update-checksums.py`.

Pruebas y límites exactos: [VALIDATION.md](VALIDATION.md).
