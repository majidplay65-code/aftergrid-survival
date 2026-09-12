#!/usr/bin/env python3
"""تولید افکت‌های WAV پروسیجرال (۱۶-بیت PCM مونو ۲۲٫۰۵ کیلوهرتز) — بدون دارایی خارجی."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def _write(name: str, samples: list[float]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767.0))))
            for s in samples
        )
        w.writeframes(frames)
    print(f"wrote {path} ({len(samples)} samples)")


def _env(i: int, n: int, attack: float = 0.02, release: float = 0.3) -> float:
    a = int(n * attack)
    r = int(n * release)
    if i < a and a > 0:
        return i / a
    if i > n - r and r > 0:
        return max(0.0, (n - i) / r)
    return 1.0


def footstep(run: bool) -> list[float]:
    rng = random.Random(2 if run else 1)
    n = int(RATE * (0.09 if run else 0.12))
    samples: list[float] = []
    for i in range(n):
        noise = rng.uniform(-1.0, 1.0)
        thud = math.sin(2 * math.pi * (90 if run else 70) * i / RATE)
        samples.append((0.35 * noise + 0.45 * thud) * _env(i, n, 0.05, 0.55) * (0.55 if run else 0.4))
    return samples


def craft() -> list[float]:
    n = int(RATE * 0.18)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        s = (
            0.4 * math.sin(2 * math.pi * 880 * t)
            + 0.25 * math.sin(2 * math.pi * 1320 * t)
            + 0.1 * math.sin(2 * math.pi * 220 * t)
        )
        samples.append(s * _env(i, n, 0.01, 0.6) * 0.5)
    return samples


def pickup() -> list[float]:
    n = int(RATE * 0.16)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        freq = 520 + 480 * (i / n)
        samples.append(math.sin(2 * math.pi * freq * t) * _env(i, n, 0.02, 0.5) * 0.4)
    return samples


def ui_click() -> list[float]:
    n = int(RATE * 0.05)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        samples.append(math.sin(2 * math.pi * 1400 * t) * _env(i, n, 0.05, 0.7) * 0.35)
    return samples


def hit() -> list[float]:
    rng = random.Random(7)
    n = int(RATE * 0.22)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        s = 0.5 * math.sin(2 * math.pi * 55 * t) + 0.3 * rng.uniform(-1.0, 1.0)
        samples.append(s * _env(i, n, 0.01, 0.65) * 0.6)
    return samples


def pause_whoosh() -> list[float]:
    n = int(RATE * 0.2)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        freq = 240 - 80 * (i / n)
        samples.append(math.sin(2 * math.pi * freq * t) * _env(i, n, 0.08, 0.5) * 0.3)
    return samples


def ambient_hum() -> list[float]:
    n = int(RATE * 0.4)
    samples: list[float] = []
    for i in range(n):
        t = i / RATE
        s = 0.5 * math.sin(2 * math.pi * 55 * t) + 0.2 * math.sin(2 * math.pi * 110 * t)
        samples.append(s * 0.18)
    return samples


def main() -> None:
    _write("footstep_walk.wav", footstep(False))
    _write("footstep_run.wav", footstep(True))
    _write("craft.wav", craft())
    _write("pickup.wav", pickup())
    _write("ui_click.wav", ui_click())
    _write("hit.wav", hit())
    _write("pause_whoosh.wav", pause_whoosh())


if __name__ == "__main__":
    main()
