# Procedencia y modificaciones

- Repositorio original Windows: https://github.com/danysers/WinUsbDisplay-1080p-VID534D-PID6021
- Controlador Linux: https://github.com/rhgndf/ms912x
- Commit Linux fijado: `a780baacf46712464ed18c60d5223f2d6d34624e`
- Archivos importados: `ms912x.h`, `ms912x_drv.c`, `ms912x_connector.c`,
  `ms912x_registers.c`, `ms912x_transfer.c`, `LICENSE`.
- Licencia del controlador y derivados: GPL-2.0-only, texto completo en `driver/LICENSE`.
- Licencia de scripts, documentación y herramientas originales: MIT, `LICENSE`.

Se conservan los créditos y la licencia originales. No se atribuye la ingeniería
inversa ni el protocolo USB a este proyecto. No se incluyen binarios Windows en
el paquete Linux.

Cambios locales respecto a ese commit:

1. `Kbuild` sondea headers del kernel destino para las APIs DRM/USB/timer, lo que
   permite compilar el mismo código en Ubuntu GA y HWE. `ms912x_compat.h` adapta
   el nombre del estado atómico y los helpers de timers.
2. Ruta anterior de importación DMA y setup fbdev cuando las APIs nuevas no están
   presentes; liberación administrada de la referencia DMA y de la workqueue.
3. Inicialización/finalización explícita del sondeo DRM para kernels anteriores;
   callback de apagado USB condicionado a su disponibilidad.
4. Include de unaligned compatible con ambas ubicaciones del kernel.
5. DKMS versión 1.0.0 con kernel/headers destino explícitos y autoinstalación.
6. Instalación con verificación de integridad, control de conflictos, rollback de
   fallos iniciales, diagnóstico Secure Boot y desinstalación.

No se han añadido comandos USB deducidos sin referencia ni se ha copiado el
perfil Windows a Linux. La compatibilidad de compilación no sustituye las pruebas
físicas de protocolo, suspensión, hotplug, video y rotación.
