"""Destructive integration tests: disposable Docker container ONLY, no module load."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path("/opt/Linux")
SOURCE = Path("/usr/src/ms912x-1.0.0")
KERNELS = sorted(p.name for p in Path("/lib/modules").glob("*") if (p / "build/Makefile").is_file())


def run(*args, env=None):
    return subprocess.run(args, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, env=env, timeout=180)


def refresh(root):
    manifest = root / "SHA256SUMS"
    paths = [line.split("  ", 1)[1] for line in manifest.read_text().splitlines()]
    manifest.write_text("".join(
        f"{hashlib.sha256((root / path).read_bytes()).hexdigest()}  {path}\n"
        for path in paths))


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="ms912x-test-")
        self.root = Path(self.temp.name) / "Linux"
        shutil.copytree(ROOT, self.root)

    def tearDown(self):
        if (SOURCE / ".linuxusbdisplay").exists():
            result = run("bash", str(ROOT / "uninstall.sh"))
            self.assertEqual(result.returncode, 0, result.stdout)
        self.temp.cleanup()

    def install(self, kernel=None, *extra, env=None):
        return run("bash", str(self.root / "install.sh"), "--no-deps", "--no-load",
                   "--kernel", kernel or KERNELS[0], *extra, env=env)

    def test_lint_and_check_do_not_install(self):
        scripts = [ROOT / "install.sh", ROOT / "uninstall.sh", *sorted((ROOT / "bin").iterdir())]
        result = run("shellcheck", *(str(p) for p in scripts))
        self.assertEqual(result.returncode, 0, result.stdout)
        for script in scripts:
            self.assertEqual(run("bash", "-n", str(script)).returncode, 0)
        result = self.install(None, "--check")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertFalse(SOURCE.exists())

    def test_corrupt_source_rejected_before_install(self):
        with (self.root / "driver/ms912x_drv.c").open("a") as f:
            f.write("\n// unexpected modification\n")
        result = self.install()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("incompletas o modificadas", result.stdout)
        self.assertFalse(SOURCE.exists())

    def test_kernel_and_arguments_rejected(self):
        for kernel in ("5.15.0-1-generic", "7.2.0-1-generic", "../../etc", "6.8.0;id"):
            with self.subTest(kernel=kernel):
                self.assertNotEqual(self.install(kernel).returncode, 0)
        result = self.install(None, "--unknown")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(SOURCE.exists())

    def test_real_dkms_all_kernels_repeat_and_uninstall(self):
        for kernel in KERNELS:
            with self.subTest(kernel=kernel):
                result = self.install(kernel)
                self.assertEqual(result.returncode, 0, result.stdout)
                info = run("modinfo", "-k", kernel, "ms912x")
                self.assertEqual(info.returncode, 0, info.stdout)
                self.assertIn("v534Dp6021", info.stdout)
                self.assertIn(kernel, info.stdout)
                self.assertIn("1.0.0", info.stdout)
                self.assertRegex(info.stdout, r"signer:\s+\S")
                result = self.install(kernel)
                self.assertEqual(result.returncode, 0, result.stdout)
        status = run("dkms", "status", "-m", "ms912x")
        self.assertEqual(status.stdout.count(": installed"), len(KERNELS), status.stdout)
        result = run("bash", "/usr/local/lib/linuxusbdisplay/uninstall.sh")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertFalse(SOURCE.exists())
        self.assertFalse(Path("/usr/local/bin/ms912x-status").exists())
        for kernel in KERNELS:
            self.assertNotEqual(run("modinfo", "-k", kernel, "ms912x").returncode, 0)

    def test_compile_failure_rolls_back_even_exit_two(self):
        with (self.root / "driver/ms912x_drv.c").open("a") as f:
            f.write('\n#error "deliberate compile failure for rollback test"\n')
        refresh(self.root)
        result = self.install()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("Revirtiendo", result.stdout)
        self.assertFalse(SOURCE.exists())
        self.assertEqual(run("dkms", "status", "-m", "ms912x").stdout.strip(), "")
        self.assertIn("deliberate compile failure", Path("/var/log/ms912x-build-failed.log").read_text())

    def test_different_source_same_version_is_preserved(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout)
        original = (SOURCE / "ms912x_drv.c").read_bytes()
        with (self.root / "driver/ms912x_drv.c").open("a") as f:
            f.write("\n// new local revision\n")
        refresh(self.root)
        result = self.install()
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("fuentes diferentes", result.stdout)
        self.assertEqual((SOURCE / "ms912x_drv.c").read_bytes(), original)

    def test_other_version_conflict_is_preserved(self):
        # Mock only the external inventory; no other user's DKMS tree is altered.
        fakebin = Path(self.temp.name) / "bin"
        fakebin.mkdir()
        dkms = fakebin / "dkms"
        dkms.write_text('#!/bin/bash\necho "ms912x/0.1: added"\n')
        dkms.chmod(0o755)
        env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}")
        result = self.install(env=env)
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertIn("otra version", result.stdout)
        self.assertFalse(SOURCE.exists())

    def test_load_rejection_preserves_installed_module(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stdout)
        fakebin = Path(self.temp.name) / "bin"
        fakebin.mkdir()
        wrappers = {
            "uname": f'#!/bin/bash\nif [[ $1 == -r ]]; then echo {KERNELS[0]}; else exec /usr/bin/uname "$@"; fi\n',
            "modprobe": '#!/bin/bash\necho "Key was rejected by service" >&2\nexit 1\n',
            "mokutil": '#!/bin/bash\necho "SecureBoot enabled"\n',
        }
        for name, text in wrappers.items():
            path = fakebin / name
            path.write_text(text)
            path.chmod(0o755)
        env = dict(os.environ, PATH=f"{fakebin}:{os.environ['PATH']}")
        result = run("bash", str(self.root / "install.sh"), "--no-deps", env=env)
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("NO pudo cargarse", result.stdout)
        self.assertTrue(SOURCE.exists())
        self.assertIn(": installed", run("dkms", "status", "-m", "ms912x").stdout)


if __name__ == "__main__":
    if (os.environ.get("LINUXUSBDISPLAY_TEST") != "1" or not Path("/.dockerenv").exists()
            or os.geteuid() != 0 or Path("/sys/module/ms912x").exists()):
        raise SystemExit("Only run in the dedicated, disposable Docker test container.")
    if SOURCE.exists() or run("dkms", "status", "-m", "ms912x").stdout.strip():
        raise SystemExit("Test container must start without an ms912x installation.")
    if not KERNELS:
        raise SystemExit("No target kernel headers installed.")
    print("Target kernels:", ", ".join(KERNELS), flush=True)
    unittest.main(verbosity=2)
