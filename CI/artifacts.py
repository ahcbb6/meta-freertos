#!/usr/bin/env python3
# SPDX-License-Identifier: MIT

import argparse
import os
from pathlib import Path
import shutil
import subprocess


def archive(root, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["tar", "-I", "zstd -T2 -3", "-cf", str(destination), "-C", str(root), "."],
        check=True,
    )


def images(build, output, machine):
    deploy = build / "tmp/deploy/images" / machine
    patterns = ["freertos-image*.elf"]
    if machine == "stm32f446":
        patterns.append("freertos-image*.hex")
    else:
        patterns.extend(("freertos-image*.bin", f"freertos-image-*{machine}-*.qemuboot.conf"))
    output.mkdir(parents=True, exist_ok=True)
    for pattern in patterns:
        entries = sorted(path for path in deploy.glob(pattern) if path.is_file())
        if not entries:
            raise RuntimeError(f"Missing image artifact: {deploy / pattern}")
        for path in entries:
            # Actions does not upload symlinks; publish their contents under the original names.
            shutil.copy2(path, output / path.name)


def logs(build, output):
    output.mkdir(parents=True, exist_ok=True)
    entries = sorted({
        path for pattern in (
            "conf/**/*.conf", "bitbake-cookerdaemon.log",
            "tmp*/log/**/*", "tmp*/work/**/temp/log.*", "tmp*/work/**/temp/run.*",
            "tmp*/work/**/testimage/**/*",
        )
        for path in build.glob(pattern) if path.is_file()
    })
    if not entries:
        print("No BitBake diagnostics found.")
        return
    subprocess.run(
        ["tar", "-I", "zstd -T2 -3", "-cf", str(output / "diagnostics.tar.zst"),
         "-C", str(build), "--null", "-T", "-"],
        input=b"".join(str(path.relative_to(build)).encode() + b"\0" for path in entries),
        check=True,
    )


def materialize_sstate(root, mirror):
    root = root.resolve(strict=True)
    mirror = mirror.resolve(strict=True)
    if root == mirror or root in mirror.parents or mirror in root.parents:
        raise ValueError("Sstate output and mirror must be separate directories")
    count = 0
    for path in root.rglob("*"):
        if not path.is_symlink():
            continue
        target = path.resolve(strict=True)
        if not target.is_file() or mirror not in target.parents:
            raise ValueError(f"Unexpected sstate mirror link: {path} -> {target}")
        temporary = path.with_name(path.name + ".materialized")
        os.link(target, temporary)
        try:
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)
        count += 1
    print(f"Made {count} fetched sstate files independent of the mirror")


def main():
    parser = argparse.ArgumentParser(description="Collect CI artifacts and sstate.")
    commands = parser.add_subparsers(dest="command", required=True)
    image_parser = commands.add_parser("images")
    image_parser.add_argument("build", type=Path)
    image_parser.add_argument("output", type=Path)
    image_parser.add_argument("machine")
    log_parser = commands.add_parser("logs")
    log_parser.add_argument("build", type=Path)
    log_parser.add_argument("output", type=Path)
    sstate_parser = commands.add_parser("sstate")
    sstate_parser.add_argument("root", type=Path)
    sstate_parser.add_argument("mirror", type=Path)
    archive_parser = commands.add_parser("archive")
    archive_parser.add_argument("root", type=Path)
    archive_parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    if args.command == "images":
        images(args.build, args.output, args.machine)
    elif args.command == "logs":
        logs(args.build, args.output)
    elif args.command == "sstate":
        materialize_sstate(args.root, args.mirror)
    else:
        archive(args.root, args.destination)


if __name__ == "__main__":
    main()
