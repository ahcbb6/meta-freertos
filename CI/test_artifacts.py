# SPDX-License-Identifier: MIT

from pathlib import Path
import subprocess
import tempfile
import unittest

import artifacts


class ArtifactsTest(unittest.TestCase):
    def test_stm32_excludes_oversized_binary(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            deploy = root / "tmp/deploy/images/stm32f446"
            deploy.mkdir(parents=True)
            for suffix in (".elf", ".hex", ".bin"):
                (deploy / f"freertos-image-stm32f446{suffix}").write_text(suffix)
            artifacts.images(root, root / "images", "stm32f446")
            self.assertEqual(
                {path.suffix for path in (root / "images").iterdir()}, {".elf", ".hex"},
            )
            (deploy / "freertos-image-stm32f446.hex").unlink()
            with self.assertRaises(RuntimeError):
                artifacts.images(root, root / "missing", "stm32f446")

    def test_qemu_publishes_link_contents_and_configuration(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            deploy = root / "tmp/deploy/images/qemuarmv5"
            deploy.mkdir(parents=True)
            for suffix in (".elf", ".bin", ".qemuboot.conf"):
                name = f"freertos-image-qemuarmv5-20260101{suffix}"
                (deploy / name).write_text(suffix)
                if suffix != ".qemuboot.conf":
                    (deploy / f"freertos-image-qemuarmv5{suffix}").symlink_to(name)
            artifacts.images(root, root / "images", "qemuarmv5")
            self.assertEqual(len(list((root / "images").iterdir())), 5)
            self.assertFalse((root / "images/freertos-image-qemuarmv5.elf").is_symlink())
            self.assertEqual((root / "images/freertos-image-qemuarmv5.elf").read_text(), ".elf")

    def test_sstate_snapshot_survives_removal_of_mirror(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sstate, mirror = root / "sstate", root / "mirror"
            sstate.mkdir()
            mirror.mkdir()
            (mirror / "fetched").write_bytes(b"cached task")
            (sstate / "fetched").symlink_to(mirror / "fetched")
            artifacts.materialize_sstate(sstate, mirror)
            (mirror / "fetched").unlink()
            mirror.rmdir()
            archive = root / "sstate.tar.zst"
            artifacts.archive(sstate, archive)
            restored = root / "restored"
            restored.mkdir()
            subprocess.run(["tar", "--zstd", "-xf", str(archive), "-C", str(restored)], check=True)
            self.assertFalse((restored / "fetched").is_symlink())
            self.assertEqual((restored / "fetched").read_bytes(), b"cached task")

    def test_sstate_rejects_links_outside_mirror(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sstate, mirror = root / "sstate", root / "mirror"
            sstate.mkdir()
            mirror.mkdir()
            (root / "unexpected").write_text("not sstate")
            (sstate / "link").symlink_to(root / "unexpected")
            with self.assertRaises(ValueError):
                artifacts.materialize_sstate(sstate, mirror)

    def test_runtime_diagnostics(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            log = root / "tmp/work/recipe/testimage/qemu_boot_log"
            log.parent.mkdir(parents=True)
            log.write_text("runtime failure")
            artifacts.logs(root, root / "output")
            contents = subprocess.check_output(
                ["tar", "--zstd", "-tf", str(root / "output/diagnostics.tar.zst")],
                text=True,
            )
            self.assertIn(str(log.relative_to(root)), contents)


if __name__ == "__main__":
    unittest.main()
