# Technical Notes / Notas Técnicas

## Observed device

```txt
USB\VID_534D&PID_6021&MI_03
MS USB Display
MS Idd Device
```

## Stable 1080p profile

The stable profile keeps `pqmode=1`. In local logs this selected the `ARGB -> yuv` conversion path through `libyuv.dll`.

At `1920x1080`, the application was observed sending full-frame payloads of about `4147216` bytes. Lowering resolution reduced payload size, but this repository keeps `1920x1080` because the goal is a usable full-HD landscape profile.

## Applied runtime tweaks

The optimizer script applies only reversible user/system settings:

- copies an optimized `config.ini`;
- backs up the previous installed config;
- sets `WinUsbDisplay.exe` process priority to `High`;
- sets Windows graphics preference for `WinUsbDisplay.exe` to `GpuPreference=2`;
- disables USB selective suspend in the current power scheme.

## Portrait rotation failure

Windows can accept portrait modes for the indirect display, but the closed capture/app stack fails afterward. Observed log errors include:

```txt
Can't DuplicateOutput()
Can't AcquireNextFrame()
```

The visible result can be split output, inverted halves and reversed/crossed pointer mapping. No safe `config.ini` key was found to enable native portrait rotation.

## Driver modification policy

Do not modify signed `.sys`, `.dll`, `.cat` or `.inf` packages as a normal optimization path. Doing so can invalidate driver signatures and make the device fail to load on Windows.
