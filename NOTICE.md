# Notices

This repository is a Windows-only optimized distribution and documentation effort for generic USB display adapters identified as `USB\VID_534D&PID_6021&MI_03`.

## Original material

The Windows installer and extracted application/driver files originate from the public `MSDisplay_Windows_V2.0.1.7.3` package distributed by the MindShow/USBDisplay project and related MS/UltraSemi driver stack.

Included third-party/vendor artifacts may include, among others:

- `WinUsbDisplay.exe`;
- Windows driver files such as `.sys`, `.dll`, `.cat` and `.inf`;
- `libusb0.dll` / libusb-win32 components;
- `libyuv.dll`;
- Microsoft indirect display driver/bus components;
- DemoForge Mirage driver components;
- MS/UltraSemi/MindShow installer and support files.

These files are included for compatibility, study, installation convenience and reproducibility. They are not authored by this fork.

## License scope

The MIT license in `LICENSE` applies only to original material created for this repository, including:

- documentation;
- optimized configuration files;
- PowerShell and batch scripts;
- repository metadata.

The MIT license does not relicense third-party installers, drivers, DLLs, SYS files, CAT files, INF files, icons, runtimes or other vendor-provided binaries.

## Signed drivers

This repository intentionally does not modify signed driver binaries or catalog files. Editing signed Windows driver packages can invalidate signatures and prevent Windows from loading the device.

## Portrait rotation

Native Windows portrait mode is documented as unsupported by the original package. Local testing confirmed that forcing portrait can trigger capture/topology failures such as `Can't DuplicateOutput()` and `Can't AcquireNextFrame()`, causing split/inverted output. This repository keeps the stable optimized profile in landscape mode.
