# Validación de LinuxUsbDisplay 1.0.0

La validación de software se ejecuta en un contenedor **Ubuntu 24.04 amd64** sobre
Docker Desktop en Windows. El contenedor no carga módulos en el kernel anfitrión.

Resultado del 8 de septiembre de 2026: **8 pruebas de integración aprobadas**,
incluido ShellCheck sin incidencias. Ambos módulos se generaron y firmaron con
DKMS; la carga rechazada por Secure Boot se probó con un comando simulado.

## Alcance

- Compilación contra headers oficiales de Ubuntu `6.8.0-139-generic` y `7.0.0-31-generic`.
- Verificación del alias USB `534d:6021`, versión y vermagic del módulo generado.
- Instalación, firma, registro DKMS, instalación repetida y desinstalación con
  `--no-load`; reconstrucción para un kernel diferente al que ejecuta el contenedor.
- Análisis ShellCheck y sintaxis Bash de instalador, desinstalador y herramientas.
- Pruebas de rechazo de fuentes alteradas, kernel incompatible, conflictos de
  versiones y limpieza después de una compilación fallida.
- Extracción de los paquetes y comprobación SHA-256.

## Lo que NO se ha probado

No se ha conectado este adaptador a un kernel Ubuntu ejecutando el módulo.
Por tanto, todavía faltan: imagen física, EDID real, colores, FPS, CPU, desconexión
bajo carga, suspensión/reanudación, múltiples adaptadores, Wayland/Xorg y rotación.
Tampoco se ha completado el registro de una clave MOK en firmware real.

El aviso de BTF por ausencia de `vmlinux` en el contenedor no impide generar el
módulo. El éxito de compilación no demuestra funcionamiento eléctrico/protocolo.
Los avisos de `depmod` sobre `modules.builtin`/`modules.order` corresponden a que
el contenedor tiene headers y no una imagen de kernel arrancable instalada.

## Repetir pruebas

Las herramientas del repositorio `tests/` se ejecutan exclusivamente en un
contenedor desechable: instalan y eliminan archivos de `/usr/src`, `/var/lib/dkms`
y `/usr/local`. No ejecutar el test de integración en su escritorio de uso diario.
La prueba de integración exige una marca de contenedor y no utiliza `modprobe`.

Desde la raíz del repositorio:

```bash
docker build -f tests/Dockerfile -t linuxusbdisplay-test .
docker run --rm linuxusbdisplay-test
```

El Dockerfile instala los metapaquetes de headers GA y HWE disponibles en Ubuntu
24.04; las versiones concretas pueden cambiar. La prueba registra los kernels
encontrados y falla si aparece una incompatibilidad.

## Prueba física pendiente en Ubuntu

1. Instalar con el adaptador desconectado; completar MOK si corresponde.
2. Conectar USB/HDMI y verificar `ms912x-status` y la pantalla de configuración.
3. Probar 1080p, duplicado y extensión; confirmar colores y texto.
4. Mover ventanas y reproducir video; comprobar errores del kernel y uso de CPU.
5. Probar reconexión USB y suspensión/reanudación; guardar el diagnóstico si falla.
6. Probar desinstalación con el adaptador desconectado.

Ante un bloqueo, desconectar el adaptador; no seguir forzando cambios de modo.
