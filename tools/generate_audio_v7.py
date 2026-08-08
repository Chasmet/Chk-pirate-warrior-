#!/usr/bin/env python3
"""Banque audio originale et déterministe de CHK Pirate Warrior V7."""
from __future__ import annotations

import argparse
import math
import wave
from pathlib import Path

import numpy as np

RATE = 32_000
SEED = 19_820_415


def tone(t: np.ndarray, hz: float, phase: float = 0.0) -> np.ndarray:
    return np.sin(2.0 * np.pi * hz * t + phase, dtype=np.float32)


def stereo(left: np.ndarray, right: np.ndarray) -> np.ndarray:
    return np.stack((left, right), axis=1).astype(np.float32, copy=False)


def fade(signal: np.ndarray, seconds: float = 1.0) -> None:
    length = min(int(RATE * seconds), signal.shape[0] // 3)
    if length <= 0:
        return
    ramp = np.linspace(0.0, 1.0, length, dtype=np.float32)
    signal[:length] *= ramp[:, None]
    signal[-length:] *= ramp[::-1, None]


def write(path: Path, signal: np.ndarray) -> None:
    signal = np.nan_to_num(signal, nan=0.0, posinf=0.0, neginf=0.0)
    peak = float(np.max(np.abs(signal))) if signal.size else 1.0
    if peak > 0.95:
        signal *= 0.95 / peak
    pcm = (np.clip(signal, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(pcm.tobytes())


def music(duration: float, style: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * RATE)
    out = np.zeros((frames, 2), dtype=np.float32)
    settings = {
        "exploration": (92.0, [146.83, 174.61, 196.0, 130.81], 0.16),
        "combat": (148.0, [110.0, 123.47, 146.83, 98.0], 0.19),
        "boss": (132.0, [73.42, 82.41, 87.31, 65.41], 0.22),
        "victory": (106.0, [196.0, 220.0, 246.94, 174.61], 0.18),
    }
    bpm, roots, level = settings[style]
    beat = 60.0 / bpm
    bar = beat * 4.0
    for bar_index in range(int(math.ceil(duration / bar))):
        start = int(bar_index * bar * RATE)
        end = min(frames, int((bar_index + 1) * bar * RATE))
        if end <= start:
            continue
        local = np.arange(end - start, dtype=np.float32) / RATE
        root = roots[bar_index % len(roots)]
        chord = tone(local, root) + 0.58 * tone(local, root * 1.25, 0.3) + 0.42 * tone(local, root * 1.5, 0.8)
        shape = np.clip(np.sin(np.linspace(0.0, np.pi, end - start, dtype=np.float32)), 0.0, 1.0)
        env = shape ** 0.7
        out[start:end, 0] += chord * env * level
        out[start:end, 1] += np.roll(chord, 31) * env * level * 0.92
    for beat_index in range(int(duration / beat)):
        start = int(beat_index * beat * RATE)
        length = min(int(beat * 0.55 * RATE), frames - start)
        if length <= 0:
            continue
        local = np.arange(length, dtype=np.float32) / RATE
        if beat_index % 4 in (0, 2):
            kick = tone(local, 72.0 - 28.0 * local) * np.exp(-local * 13.0, dtype=np.float32) * 0.35
            out[start:start + length] += stereo(kick, kick * 0.94)
        if beat_index % 4 in (1, 3):
            hit = rng.standard_normal(length, dtype=np.float32) * np.exp(-local * 18.0, dtype=np.float32) * 0.16
            out[start:start + length] += stereo(hit, np.roll(hit, 43) * 0.86)
    out += rng.standard_normal(out.shape, dtype=np.float32) * 0.0035
    fade(out)
    return out


def ambience(duration: float, style: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * RATE)
    t = np.arange(frames, dtype=np.float32) / RATE
    nl = rng.standard_normal(frames, dtype=np.float32)
    nr = rng.standard_normal(frames, dtype=np.float32)
    slow = 0.5 + 0.5 * tone(t, 0.07, 0.4)
    wave_motion = 0.55 * tone(t, 0.12) + 0.28 * tone(t, 0.23, 1.2)
    left = nl * 0.024
    right = nr * 0.024

    if style == "ocean":
        left += wave_motion * 0.060 + nl * slow * 0.030 + tone(t, 58.0) * 0.012
        right += np.roll(wave_motion, 900) * 0.056 + nr * (1.0 - slow) * 0.030 + tone(t, 61.0, 0.7) * 0.012
    elif style == "storm":
        left += nl * 0.105 + tone(t, 39.0) * 0.045
        right += nr * 0.105 + tone(t, 43.0, 0.5) * 0.045
    elif style == "boat":
        creak = tone(t, 1.45) * tone(t, 72.0) * 0.028
        left += wave_motion * 0.070 + creak
        right += np.roll(wave_motion, 1300) * 0.066 + np.roll(creak, 470)
    elif style == "deep_ocean":
        left += tone(t, 31.0) * 0.054 + tone(t, 48.0) * 0.027
        right += tone(t, 29.0, 0.8) * 0.052 + tone(t, 52.0, 1.5) * 0.026
    elif style in ("night", "jungle"):
        insects = tone(t, 3120.0) * (0.5 + 0.5 * tone(t, 7.0)) * (0.012 if style == "night" else 0.018)
        left += insects + tone(t, 174.61) * 0.015
        right += np.roll(insects, 220) + tone(t, 220.0, 0.8) * 0.014
    elif style == "port":
        bell = tone(t, 392.0) * (np.maximum(0.0, tone(t, 0.11)) ** 12) * 0.030
        wood = tone(t, 2.1) * tone(t, 84.0) * 0.018
        left += wave_motion * 0.038 + bell + wood
        right += np.roll(wave_motion, 700) * 0.035 + np.roll(bell, 180) + np.roll(wood, 310)
    elif style == "snow":
        left += nl * (0.045 + 0.026 * slow) + tone(t, 880.0) * 0.006
        right += nr * (0.045 + 0.026 * (1.0 - slow)) + tone(t, 932.0, 0.8) * 0.006
    elif style == "desert":
        gust = nl * (0.036 + 0.050 * np.maximum(0.0, tone(t, 0.045)))
        left += gust + tone(t, 196.0) * 0.011
        right += np.roll(gust, 1200) * 0.94 + tone(t, 220.0, 0.7) * 0.010
    elif style == "volcano":
        rumble = tone(t, 32.0) * 0.052 + tone(t, 47.0, 0.8) * 0.025
        crackle = nl * (np.maximum(0.0, tone(t, 3.7)) ** 18) * 0.11
        left += rumble + crackle
        right += np.roll(rumble, 500) * 0.94 + np.roll(crackle, 77)
    elif style == "fortress":
        drone = tone(t, 73.42) * 0.025 + tone(t, 110.0, 0.4) * 0.014
        pulse = (np.maximum(0.0, tone(t, 0.18)) ** 8) * tone(t, 220.0) * 0.025
        left += drone + pulse + nl * 0.032
        right += np.roll(drone, 120) + np.roll(pulse, 250) + nr * 0.032
    else:
        birds = tone(t, 1450.0 + 300.0 * tone(t, 0.31)) * (np.maximum(0.0, tone(t, 0.13)) ** 20) * 0.022
        left += birds + tone(t, 96.0) * 0.012
        right += np.roll(birds, 350) * 0.88 + tone(t, 103.0, 0.7) * 0.012

    out = stereo(left, right)
    out += rng.standard_normal(out.shape, dtype=np.float32) * 0.0032
    fade(out)
    return out


def sfx(duration: float, kind: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * RATE)
    t = np.arange(frames, dtype=np.float32) / RATE
    env = np.exp(-t * (7.0 if kind != "thunder" else 1.0), dtype=np.float32)
    noise = rng.standard_normal(frames, dtype=np.float32)
    if kind == "attack":
        mono = (tone(t, 540.0 - 260.0 * t) + noise * 0.45) * env * 0.42
    elif kind == "skill":
        mono = (tone(t, 180.0 + 980.0 * t) + 0.55 * tone(t, 360.0 + 1500.0 * t)) * env * 0.42
    elif kind == "dodge":
        mono = noise * env * 0.30 + tone(t, 210.0) * env * 0.12
    elif kind == "hurt":
        mono = (tone(t, 92.0) + noise * 0.30) * env * 0.40
    elif kind == "dock":
        mono = (tone(t, 128.0) + 0.65 * tone(t, 192.0)) * env * 0.34
    else:
        mono = noise * np.exp(-t * 0.9, dtype=np.float32) * 0.35 + tone(t, 38.0) * env * 0.35
    return stereo(mono, np.roll(mono, 41) * 0.93)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)

    specs = [
        ("music_exploration.wav", 82.0, "music", "exploration"),
        ("music_combat.wav", 72.0, "music", "combat"),
        ("music_boss.wav", 66.0, "music", "boss"),
        ("music_victory.wav", 48.0, "music", "victory"),
        ("ambience_ocean.wav", 92.0, "ambience", "ocean"),
        ("ambience_storm.wav", 78.0, "ambience", "storm"),
        ("ambience_island_day.wav", 78.0, "ambience", "day"),
        ("ambience_island_night.wav", 78.0, "ambience", "night"),
        ("ambience_boat.wav", 92.0, "ambience", "boat"),
        ("ambience_deep_ocean.wav", 78.0, "ambience", "deep_ocean"),
        ("ambience_port.wav", 55.0, "ambience", "port"),
        ("ambience_jungle.wav", 55.0, "ambience", "jungle"),
        ("ambience_snow.wav", 55.0, "ambience", "snow"),
        ("ambience_desert.wav", 55.0, "ambience", "desert"),
        ("ambience_volcano.wav", 55.0, "ambience", "volcano"),
        ("ambience_fortress.wav", 55.0, "ambience", "fortress"),
    ]
    for index, (filename, duration, family, style) in enumerate(specs):
        signal = music(duration, style, SEED + index * 1013) if family == "music" else ambience(duration, style, SEED + index * 1013)
        write(args.output / filename, signal)
        print(f"generated {filename}: {(args.output / filename).stat().st_size} bytes")

    effects = {"attack": 0.62, "skill": 1.35, "dodge": 0.72, "hurt": 0.78, "dock": 1.20, "thunder": 4.40}
    for index, (kind, duration) in enumerate(effects.items()):
        write(args.output / f"sfx_{kind}.wav", sfx(duration, kind, SEED + 8000 + index * 97))

    files = list(args.output.glob("*.wav"))
    total = sum(path.stat().st_size for path in files)
    print(f"CHK_AUDIO_V7_GENERATED files={len(files)} bytes={total}")
    if total < 135_000_000:
        raise SystemExit(f"audio bank too small: {total}")


if __name__ == "__main__":
    main()
