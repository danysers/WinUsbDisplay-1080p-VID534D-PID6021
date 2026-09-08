"""Create a Linux-only source release using Python's standard library."""
import gzip
import hashlib
import io
from pathlib import Path
import tarfile
import zipfile

repo = Path(__file__).resolve().parents[1]
root = repo / "Linux"
name = "LinuxUsbDisplay-Ubuntu-1.0.0"
out = repo / "dist"
manifest = (root / "SHA256SUMS").read_text(encoding="utf-8")
paths = []
for line in manifest.splitlines():
    digest, relative = line.split("  ", 1)
    path = root / relative
    if not path.resolve().is_relative_to(root.resolve()):
        raise SystemExit(f"Unsafe manifest path: {relative}")
    if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
        raise SystemExit(f"Manifest mismatch: {relative}")
    paths.append(path)
paths.append(root / "SHA256SUMS")
out.mkdir(exist_ok=True)
with (out / f"{name}.tar.gz").open("wb") as raw:
    with gzip.GzipFile(filename="", mode="wb", fileobj=raw, mtime=0) as gz:
        with tarfile.open(fileobj=gz, mode="w") as tar:
            for path in sorted(paths):
                relative = path.relative_to(root).as_posix()
                info = tarfile.TarInfo(f"{name}/{relative}")
                data = path.read_bytes()
                info.size = len(data)
                info.mode = 0o755 if path.suffix == ".sh" or relative.startswith("bin/") else 0o644
                tar.addfile(info, io.BytesIO(data))
with zipfile.ZipFile(out / f"{name}.zip", "w", zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(paths):
        relative = path.relative_to(root).as_posix()
        info = zipfile.ZipInfo(f"{name}/{relative}", date_time=(2026, 9, 8, 0, 0, 0))
        mode = 0o755 if path.suffix == ".sh" or relative.startswith("bin/") else 0o644
        info.external_attr = (0o100000 | mode) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        archive.writestr(info, path.read_bytes())
checksums = []
for suffix in ("tar.gz", "zip"):
    path = out / f"{name}.{suffix}"
    checksums.append(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n")
    print(path)
(out / "SHA256SUMS").write_text("".join(checksums), encoding="utf-8", newline="\n")
