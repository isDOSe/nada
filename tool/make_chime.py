"""Create a short, warm two-note chime for the end of a session."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "android" / "app" / "src" / "main" / "res" / "raw" / "nada_chime.wav"

RATE = 44100
DURATION = 1.15


def bell(
    time: float,
    start: float,
    frequency: float,
    amplitude: float,
    decay: float,
    duration: float,
) -> float:
    t = time - start
    if t < 0 or t > duration:
        return 0.0
    attack = min(1.0, t / 0.008)
    envelope = attack * math.exp(-t * decay)
    fundamental = math.sin(2 * math.pi * frequency * t)
    second = math.sin(2 * math.pi * frequency * 2.01 * t) * 0.16
    third = math.sin(2 * math.pi * frequency * 3.02 * t) * 0.06
    shimmer = math.sin(2 * math.pi * (frequency + 0.6) * t) * 0.04
    return amplitude * envelope * (fundamental + second + third + shimmer)


def sample(time: float) -> float:
    value = 0.0
    value += bell(time, 0.0, 523.25, 0.24, 3.4, 0.95)   # C5
    value += bell(time, 0.11, 783.99, 0.20, 4.0, 1.0)   # G5
    value += bell(time, 0.23, 1046.50, 0.08, 5.2, 0.8)  # C6 sparkle
    value += bell(time, 0.0, 261.63, 0.10, 2.4, 0.8)    # C4 body
    # Gentle fade at the edges, no clicks.
    fade_in = min(1.0, time / 0.015)
    fade_out = min(1.0, max(0.0, (DURATION - time) / 0.16))
    return value * fade_in * fade_out


def main() -> None:
    frames = bytearray()
    peak = 0.0
    values: list[float] = []
    for index in range(int(RATE * DURATION)):
        value = sample(index / RATE)
        values.append(value)
        peak = max(peak, abs(value))

    gain = 0.72 / peak if peak else 1.0
    for value in values:
        scaled = max(-1.0, min(1.0, value * gain))
        frames.extend(struct.pack("<h", int(scaled * 32767)))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(bytes(frames))
    print(f"{OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
