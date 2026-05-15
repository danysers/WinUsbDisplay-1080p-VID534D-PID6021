# WinUsbDisplay 1080p Optimized for VID_534D PID_6021

> Distribución Windows-only optimizada y documentada para adaptadores USB genéricos a HDMI basados en `USB\VID_534D&PID_6021&MI_03`.
>
> Windows-only optimized and documented distribution for generic USB-to-HDMI display adapters based on `USB\VID_534D&PID_6021&MI_03`.

---

## Español

### Qué es

Este repositorio publica una versión Windows-only de `MSDisplay_Windows_V2.0.1.7.3` enfocada en mejorar la fluidez a `1920x1080`.

No es un driver reescrito desde cero. Es una distribución técnica y colaborativa basada en los binarios Windows existentes del paquete MS/UltraSemi/MindShow, más:

- perfil `config.ini` optimizado para 1080p;
- script de instalación/aplicación reversible;
- documentación técnica del comportamiento observado;
- avisos claros sobre licencias, binarios cerrados y limitaciones.

### Hardware soportado

Objetivo principal probado:

```txt
USB\VID_534D&PID_6021&MI_03
MS USB Display
MS Idd Device
```

Puede funcionar en dispositivos compatibles, pero este repositorio está documentado alrededor del hardware anterior.

### Instalación rápida

1. Conectar el adaptador USB a HDMI.
2. Ejecutar `Windows/MSDisplay_Windows_V2.0.1.7.3.exe` como administrador, si todavía no está instalado.
3. Ejecutar como administrador:

```bat
Windows\optimized-1080p\INSTALAR_OPTIMIZADO_COMO_ADMIN.bat
```

El script:

- crea backup de `config.ini`, estado PnP y drivers enumerados;
- copia el perfil 1080p optimizado;
- reinicia `WinUsbDisplay.exe`;
- pone `WinUsbDisplay.exe` en prioridad `High`;
- registra `GpuPreference=2`;
- desactiva la suspensión selectiva USB en el plan de energía actual.

### Detalles técnicos

Stack observado en Windows:

- aplicación principal: `WinUsbDisplay.exe`;
- transferencia USB: `libusb0` / `libusb-win32`;
- dispositivo USB: `MS USB Display`;
- pantalla indirecta: `MS Idd Device`;
- bus/display virtual: `IndirectDisplayBus`;
- conversión de color: `libyuv.dll`.

El perfil estable usa:

```ini
[picture_quality]
pqmode=1

[frame_swtich]
frame_switch_enable=3
frame_avg_fre_0=30
frame_avg_fre_1=12
frame_time=2
```

En las pruebas locales, `pqmode=1` mantuvo el camino `ARGB -> yuv`, que resultó más liviano que forzar caminos RGB más pesados.

### Rendimiento observado

El modo `1920x1080@60Hz` queda perceptiblemente más fluido después de aplicar:

- `ARGB -> YUV`;
- prioridad alta del proceso;
- preferencia gráfica de alto rendimiento;
- suspensión selectiva USB desactivada.

Aun así, el FPS real sigue limitado por el diseño cerrado del stack: se observan envíos de frames completos de aproximadamente `4.1 MB` por transferencia a 1080p. Esto sugiere cuello de botella en USB/bulk transfer/captura completa, no solamente CPU.

### Limitaciones conocidas

La rotación vertical nativa en Windows no queda corregida.

Windows acepta aplicar orientación portrait, pero el driver/app cerrado falla durante la captura con errores observados como:

```txt
Can't DuplicateOutput()
Can't AcquireNextFrame()
```

El síntoma visual es pantalla dividida, mitades invertidas o ejes del mouse cruzados. Por eso el perfil de este repositorio mantiene landscape `1920x1080`.

Alternativas prácticas:

- rotar el contenido dentro de la aplicación que se muestra;
- usar hardware/driver que soporte portrait nativo;
- colaborar en investigación del binario, sin modificar drivers firmados.

### Cómo colaborar

Se aceptan aportes para:

- documentar más hardware compatible;
- medir FPS/logs con distintos equipos;
- mejorar scripts reversibles;
- analizar `WinUsbDisplay.log`;
- proponer workarounds de rotación a nivel aplicación.

No se recomienda modificar `.sys`, `.dll`, `.cat` o `.inf` firmados: romper la firma puede impedir que Windows cargue el driver.

### Licencia y avisos

Los scripts, configs optimizados y documentación creados en este repositorio se publican bajo MIT.

Los binarios, drivers y librerías de terceros incluidos para compatibilidad no quedan relicenciados bajo MIT. Ver `NOTICE.md`.

---

## English

### What this is

This repository publishes a Windows-only `MSDisplay_Windows_V2.0.1.7.3` distribution focused on improving responsiveness at `1920x1080`.

It is not a driver rewritten from scratch. It is a technical and collaborative distribution based on the existing MS/UltraSemi/MindShow Windows binaries, plus:

- an optimized 1080p `config.ini` profile;
- a reversible installation/tuning script;
- technical notes about the observed behavior;
- clear license, binary and limitation notices.

### Supported hardware

Main tested target:

```txt
USB\VID_534D&PID_6021&MI_03
MS USB Display
MS Idd Device
```

Compatible devices may work, but this repository is documented around the hardware above.

### Quick install

1. Plug in the USB-to-HDMI adapter.
2. Run `Windows/MSDisplay_Windows_V2.0.1.7.3.exe` as administrator if the driver is not installed yet.
3. Run as administrator:

```bat
Windows\optimized-1080p\INSTALAR_OPTIMIZADO_COMO_ADMIN.bat
```

The script:

- backs up `config.ini`, PnP state and enumerated drivers;
- copies the optimized 1080p profile;
- restarts `WinUsbDisplay.exe`;
- sets `WinUsbDisplay.exe` priority to `High`;
- registers `GpuPreference=2`;
- disables USB selective suspend in the current power plan.

### Technical details

Observed Windows stack:

- main application: `WinUsbDisplay.exe`;
- USB transfer layer: `libusb0` / `libusb-win32`;
- USB device: `MS USB Display`;
- indirect display: `MS Idd Device`;
- virtual display bus: `IndirectDisplayBus`;
- color conversion: `libyuv.dll`.

The stable profile uses:

```ini
[picture_quality]
pqmode=1

[frame_swtich]
frame_switch_enable=3
frame_avg_fre_0=30
frame_avg_fre_1=12
frame_time=2
```

In local tests, `pqmode=1` kept the `ARGB -> yuv` path, which was lighter than forcing heavier RGB paths.

### Observed performance

The `1920x1080@60Hz` mode becomes noticeably more responsive after applying:

- `ARGB -> YUV`;
- high process priority;
- high performance graphics preference;
- disabled USB selective suspend.

Still, real FPS remains limited by the closed stack design: logs show full-frame transfers of about `4.1 MB` at 1080p. This suggests a bottleneck in USB/bulk transfer/full-frame capture, not CPU alone.

### Known limitations

Native portrait rotation on Windows is not fixed.

Windows accepts portrait orientation, but the closed driver/app fails during capture with observed errors such as:

```txt
Can't DuplicateOutput()
Can't AcquireNextFrame()
```

The visible symptom is split screen, inverted halves or crossed mouse axes. For that reason, this repository keeps the profile in landscape `1920x1080`.

Practical alternatives:

- rotate content inside the displayed application;
- use hardware/driver with native portrait support;
- collaborate on binary research without modifying signed drivers.

### Contributing

Contributions are welcome for:

- documenting compatible hardware;
- measuring FPS/logs on different systems;
- improving reversible scripts;
- analyzing `WinUsbDisplay.log`;
- proposing application-level rotation workarounds.

Editing signed `.sys`, `.dll`, `.cat` or `.inf` files is not recommended: breaking the signature can prevent Windows from loading the driver.

### License and notices

Scripts, optimized configs and documentation created in this repository are released under MIT.

Third-party binaries, drivers and libraries included for compatibility are not relicensed under MIT. See `NOTICE.md`.
