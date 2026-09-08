"""Exercise the piped installer with a local download fixture, without root actions."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path('/opt/install-ubuntu.sh')
ARCHIVE = Path('/opt/releases/ubuntu-1.0.0/LinuxUsbDisplay-Ubuntu-1.0.0.tar.gz')
KERNEL = next(p.name for p in Path('/lib/modules').iterdir() if (p / 'build/Makefile').is_file())


class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        base = Path(self.temp.name)
        self.work = base / 'temporary files'
        self.work.mkdir()
        self.fixture = base / 'release.tar.gz'
        self.fixture.write_bytes(ARCHIVE.read_bytes())
        fakebin = base / 'bin'
        fakebin.mkdir()
        curl = fakebin / 'curl'
        curl.write_text('''#!/bin/bash
[[ ${DOWNLOAD_FAIL:-0} == 0 ]] || exit 22
while (($#)); do
    if [[ $1 == -o ]]; then cp "$FIXTURE" "$2"; exit 0; fi
    shift
done
exit 1
''')
        curl.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{fakebin}:{os.environ["PATH"]}',
                        FIXTURE=str(self.fixture), TMPDIR=str(self.work))

    def tearDown(self):
        self.assertEqual(list(self.work.iterdir()), [], 'Temporary download was not cleaned')
        self.temp.cleanup()

    def pipe(self, *args):
        return subprocess.run(['bash', '-s', '--', *args], input=SCRIPT.read_text(),
                              text=True, capture_output=True, env=self.env, timeout=30)

    def test_verified_package_check_from_pipe(self):
        result = self.pipe('--check', '--kernel', KERNEL, '--no-load')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('no se modifico el sistema', result.stdout)

    def test_corrupt_download_never_reaches_installer(self):
        self.fixture.write_bytes(b'corrupted archive')
        result = self.pipe('--check', '--kernel', KERNEL, '--no-load')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No se ejecuto el instalador', result.stderr)
        self.assertNotIn('Sistema:', result.stdout)

    def test_download_error_stops(self):
        self.env['DOWNLOAD_FAIL'] = '1'
        result = self.pipe('--check', '--kernel', KERNEL, '--no-load')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('Sistema:', result.stdout)

    def test_help_needs_no_download(self):
        self.env['DOWNLOAD_FAIL'] = '1'
        self.assertEqual(self.pipe('--help').returncode, 0)

    def test_shellcheck(self):
        result = subprocess.run(['shellcheck', str(SCRIPT)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
