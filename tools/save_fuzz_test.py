#!/usr/bin/env python3
"""Fuzz one generated save file from outside the production save implementation.

Usage:
  python3 tools/save_fuzz_test.py --save-path /path/to/save --binary /path/to/aftergrid.x86_64

The original save is restored in a finally block. This script reports whether the
headless exported binary crashes, exits, or remains alive until the timeout. It
intentionally does not diagnose or repair save parsing behavior.
"""

from __future__ import annotations

import argparse
import random
import shutil
import subprocess
import tempfile
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--save-path", type=Path, required=True)
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--flips", type=int, default=8)
    parser.add_argument("--seed", type=int, default=1337)
    parser.add_argument("--timeout-seconds", type=float, default=15.0)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.save_path.is_file():
        print(f"FUZZ_SKIPPED missing_save={args.save_path}")
        return 0
    if not args.binary.is_file():
        print(f"FUZZ_SKIPPED missing_binary={args.binary}")
        return 0
    if args.flips < 1:
        raise ValueError("--flips must be positive")

    original_bytes = args.save_path.read_bytes()
    if not original_bytes:
        print("FUZZ_SKIPPED empty_save=true")
        return 0
    backup_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(prefix="aftergrid-save-backup-", delete=False) as backup:
            backup_path = Path(backup.name)
        shutil.copy2(args.save_path, backup_path)

        data = bytearray(original_bytes)
        rng = random.Random(args.seed)
        offsets: list[int] = []
        for _ in range(min(args.flips, len(data))):
            offset = rng.randrange(len(data))
            data[offset] ^= 1 << rng.randrange(8)
            offsets.append(offset)
        args.save_path.write_bytes(data)

        command = [str(args.binary), "--headless", "--audio-driver", "Dummy", "--verbose"]
        try:
            completed = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=args.timeout_seconds,
                check=False,
            )
            combined = (completed.stdout + completed.stderr).strip()
            if completed.returncode < 0:
                outcome = f"crashed_signal={-completed.returncode}"
            else:
                outcome = f"exited_code={completed.returncode}"
            print(f"FUZZ_RESULT outcome={outcome} flips={len(offsets)} bytes={len(data)}")
            print(combined[-4000:])
        except subprocess.TimeoutExpired as error:
            combined = ((error.stdout or "") + (error.stderr or "")).strip()
            print(f"FUZZ_RESULT outcome=timeout_without_crash flips={len(offsets)} bytes={len(data)}")
            print(combined[-4000:])
    finally:
        if backup_path is not None:
            shutil.copy2(backup_path, args.save_path)
            backup_path.unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
