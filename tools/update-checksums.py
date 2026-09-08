"""Refresh the Linux distribution's accidental-corruption manifest after edits."""
from hashlib import sha256
from pathlib import Path

root = Path(__file__).resolve().parents[1] / "Linux"
payload = (
    "LICENSE", "README.md", "UPSTREAM.md", "VALIDATION.md",
    "install.sh", "uninstall.sh", "ms912x-display.desktop",
    "bin/ms912x-status", "bin/ms912x-display",
    "driver/LICENSE", "driver/Kbuild", "driver/Makefile", "driver/dkms.conf",
    "driver/ms912x.h", "driver/ms912x_compat.h", "driver/ms912x_drv.c",
    "driver/ms912x_connector.c", "driver/ms912x_registers.c", "driver/ms912x_transfer.c",
)
# Never include a locally built .ko/.o (or normalize bytes inside a binary).
paths = sorted(root / relative for relative in payload)
for path in paths:
    # This distribution contains text sources only. Preserve hashes across Git
    # checkouts on Windows and make shell scripts directly runnable on Ubuntu.
    data = path.read_bytes()
    if b"\r\n" in data:
        path.write_bytes(data.replace(b"\r\n", b"\n"))
(root / "SHA256SUMS").write_text("".join(
    f"{sha256(p.read_bytes()).hexdigest()}  {p.relative_to(root).as_posix()}\n"
    for p in paths), encoding="utf-8", newline="\n")
print(f"Manifest updated: {len(paths)} files")
