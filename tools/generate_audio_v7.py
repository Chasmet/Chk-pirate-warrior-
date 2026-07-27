#!/usr/bin/env python3
"""Génère la banque audio originale de CHK Pirate Warrior V7.

Aucune musique tierce n'est utilisée. Les pistes sont synthétisées de façon
reproductible pour le jeu puis importées par Godot pendant GitHub Actions.
"""
from __future__ import annotations

import argparse
import math
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 32_000
MASTER_SEED = 19820415


def _fade_edges(signal: np.ndarray, seconds: float = 1.2) -> None:
    count = min(int(SAMPLE_RATE * seconds), signal.shape[0] // 3)
    if count <= 0:
        return
    fade = np.linspace(0.0, 1.0, count, dtype=np.float32)
    signal[:count] *= fade[:, None]
    signal[-count:] *= fade[::-1, None]


def _write_wav(path: Path, stereo: np.ndarray) -> None:
    stereo = np.nan_to_num(stereo, nan=0.0, posinf=0.0, neginf=0.0)
    peak = float(np.max(np.abs(stereo))) if stereo.size else 1.0
    if peak > 0.96:
        stereo = stereo * (0.96 / peak)
    pcm = np.asarray(np.clip(stereo, -1.0, 1.0) * 32767.0, dtype="<i2")
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(pcm.tobytes())


def _tone(t: np.ndarray, frequency: float, phase: float = 0.0) -> np.ndarray:
    return np.sin((2.0 * np.pi * frequency * t) + phase, dtype=np.float32)


def _kick(track: np.ndarray, start: int, strength: float = 1.0) -> None:
    length = min(int(SAMPLE_RATE * 0.34), track.shape[0] - start)
    if length <= 0:
        return
    local_t = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    phase = 2.0 * np.pi * (82.0 * local_t - 46.0 * local_t * local_t)
    env = np.exp(-local_t * 14.0, dtype=np.float32)
    sample = np.sin(phase, dtype=np.float32) * env * 0.42 * strength
    track[start : start + length, 0] += sample
    track[start : start + length, 1] += sample * 0.94


def _snare(track: np.ndarray, start: int, rng: np.random.Generator, strength: float = 1.0) -> None:
    length = min(int(SAMPLE_RATE * 0.22), track.shape[0] - start)
    if length <= 0:
        return
    local_t = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    noise = rng.standard_normal(length, dtype=np.float32)
    body = _tone(local_t, 188.0) * 0.18
    env = np.exp(-local_t * 19.0, dtype=np.float32)
    sample = (noise * 0.20 + body) * env * strength
    track[start : start + length, 0] += sample
    track[start : start + length, 1] += sample * 0.84


def _thunder(track: np.ndarray, start: int, rng: np.random.Generator, strength: float = 1.0) -> None:
    length = min(int(SAMPLE_RATE * 4.2), track.shape[0] - start)
    if length <= 0:
        return
    local_t = np.arange(length, dtype=np.float32) / SAMPLE_RATE
    noise = rng.standard_normal(length, dtype=np.float32)
    rumble = (_tone(local_t, 34.0) + 0.55 * _tone(local_t, 51.0, 1.3)) * 0.22
    crack = noise * np.exp(-local_t * 7.5, dtype=np.float32) * 0.42
    tail = noise * np.exp(-local_t * 0.82, dtype=np.float32) * 0.045
    sample = (rumble * np.exp(-local_t * 0.74, dtype=np.float32) + crack + tail) * strength
    track[start : start + length, 0] += sample
    track[start : start + length, 1] += np.roll(sample, 73) * 0.92


def _music_track(duration: float, style: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * SAMPLE_RATE)
    t = np.arange(frames, dtype=np.float32) / SAMPLE_RATE
    left = np.zeros(frames, dtype=np.float32)
    right = np.zeros(frames, dtype=np.float32)

    if style == "exploration":
        bpm = 92.0
        roots = [146.83, 174.61, 196.00, 130.81]
        melody = [293.66, 349.23, 392.00, 440.00, 392.00, 349.23, 329.63, 293.66]
        pad_level, drum_level = 0.17, 0.55
    elif style == "combat":
        bpm = 148.0
        roots = [110.00, 123.47, 146.83, 98.00]
        melody = [440.00, 493.88, 523.25, 587.33, 523.25, 493.88, 440.00, 392.00]
        pad_level, drum_level = 0.15, 1.0
    elif style == "boss":
        bpm = 132.0
        roots = [73.42, 82.41, 87.31, 65.41]
        melody = [220.00, 233.08, 261.63, 293.66, 261.63, 246.94, 220.00, 196.00]
        pad_level, drum_level = 0.22, 1.18
    else:
        bpm = 106.0
        roots = [196.00, 220.00, 246.94, 174.61]
        melody = [392.00, 440.00, 493.88, 523.25, 493.88, 440.00, 392.00, 349.23]
        pad_level, drum_level = 0.18, 0.62

    bar_seconds = 240.0 / bpm
    bars = int(math.ceil(duration / bar_seconds))
    for bar in range(bars):
        start = int(bar * bar_seconds * SAMPLE_RATE)
        end = min(frames, int((bar + 1) * bar_seconds * SAMPLE_RATE))
        if end <= start:
            continue
        local_t = np.arange(end - start, dtype=np.float32) / SAMPLE_RATE
        root = roots[bar % len(roots)]
        chord = (
            _tone(local_t, root)
            + 0.62 * _tone(local_t, root * 1.25, 0.3)
            + 0.48 * _tone(local_t, root * 1.5, 0.8)
        )
        slow_env = np.sin(np.linspace(0.0, np.pi, end - start, dtype=np.float32)) ** 0.7
        left[start:end] += chord * slow_env * pad_level
        right[start:end] += np.roll(chord, 27) * slow_env * pad_level * 0.94

    beat_seconds = 60.0 / bpm
    beats = int(duration / beat_seconds)
    track = np.stack([left, right], axis=1)
    for beat in range(beats):
        start = int(beat * beat_seconds * SAMPLE_RATE)
        if beat % 4 in (0, 2):
            _kick(track, start, drum_level)
        if beat % 4 in (1, 3):
            _snare(track, start, rng, drum_level * 0.75)
        note = melody[(beat // 2) % len(melody)]
        note_len = min(int(beat_seconds * 0.72 * SAMPLE_RATE), frames - start)
        if note_len > 0:
            local_t = np.arange(note_len, dtype=np.float32) / SAMPLE_RATE
            env = np.exp(-local_t * (3.0 if style == "exploration" else 5.0), dtype=np.float32)
            lead = (_tone(local_t, note) + 0.28 * _tone(local_t, note * 2.0, 0.4)) * env
            pan = 0.30 + 0.40 * ((beat % 8) / 7.0)
            track[start : start + note_len, 0] += lead * (1.0 - pan) * 0.26
            track[start : start + note_len, 1] += lead * pan * 0.26

    # Texture très légère : évite un rendu numérique stérile et rend chaque piste unique.
    texture = rng.standard_normal((frames, 2), dtype=np.float32) * 0.0028
    track += texture
    _fade_edges(track)
    return track


def _ambience_track(duration: float, style: str, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * SAMPLE_RATE)
    t = np.arange(frames, dtype=np.float32) / SAMPLE_RATE
    noise_l = rng.standard_normal(frames, dtype=np.float32)
    noise_r = rng.standard_normal(frames, dtype=np.float32)
    slow = 0.5 + 0.5 * _tone(t, 0.07, 0.4)
    waves = _tone(t, 0.12) * 0.5 + _tone(t, 0.23, 1.2) * 0.3

    if style == "ocean":
        left = noise_l * (0.030 + slow * 0.025) + waves * 0.055 + _tone(t, 58.0) * 0.012
        right = noise_r * (0.030 + (1.0 - slow) * 0.025) + np.roll(waves, 900) * 0.052 + _tone(t, 61.0, 0.7) * 0.012
    elif style == "storm":
        left = noise_l * (0.095 + slow * 0.045) + _tone(t, 39.0) * 0.042
        right = noise_r * (0.095 + (1.0 - slow) * 0.045) + _tone(t, 43.0, 0.5) * 0.042
    elif style == "boat":
        creak = _tone(t, 1.45) * _tone(t, 72.0) * 0.026
        left = noise_l * 0.034 + waves * 0.065 + creak
        right = noise_r * 0.034 + np.roll(waves, 1300) * 0.060 + np.roll(creak, 470)
    elif style == "night":
        insects = (_tone(t, 3120.0) * (0.5 + 0.5 * _tone(t, 7.0))) * 0.011
        left = noise_l * 0.018 + insects + _tone(t, 174.61) * 0.018
        right = noise_r * 0.018 + np.roll(insects, 220) + _tone(t, 220.0, 0.8) * 0.016
    elif style == "deep_ocean":
        left = noise_l * 0.024 + _tone(t, 31.0) * 0.052 + _tone(t, 48.0) * 0.025
        right = noise_r * 0.024 + _tone(t, 29.0, 0.8) * 0.050 + _tone(t, 52.0, 1.5) * 0.024
    else:
        birds = np.zeros(frames, dtype=np.float32)
        for second in range(2, int(duration), 7):
            start = second * SAMPLE_RATE
            length = min(int(0.58 * SAMPLE_RATE), frames - start)
            local_t = np.arange(length, dtype=np.float32) / SAMPLE_RATE
            chirp = np.sin(2.0 * np.pi * (1450.0 * local_t + 1050.0 * local_t * local_t), dtype=np.float32)
            birds[start : start + length] += chirp * np.exp(-local_t * 5.2, dtype=np.float32) * 0.045
        left = noise_l * 0.022 + birds + _tone(t, 96.0) * 0.014
        right = noise_r * 0.022 + np.roll(birds, 350) * 0.88 + _tone(t, 103.0, 0.7) * 0.014

    track = np.stack([left, right], axis=1)
    if style == "storm":
        for second in range(8, int(duration), 19):
            _thunder(track, second * SAMPLE_RATE, rng, 0.72 + 0.18 * (second % 3))
    track += rng.standard_normal(track.shape, dtype=np.float32) * 0.0022
    _fade_edges(track)
    return track


def _sfx(name: str, duration: float, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    frames = int(duration * SAMPLE_RATE)
    t = np.arange(frames, dtype=np.float32) / SAMPLE_RATE
    env = np.exp(-t * (7.0 if name != "thunder" else 1.1), dtype=np.float32)
    if name == "attack":
        mono = (_tone(t, 540.0 - 260.0 * t) + rng.standard_normal(frames, dtype=np.float32) * 0.45) * env * 0.42
    elif name == "skill":
        mono = (_tone(t, 180.0 + 980.0 * t) + 0.55 * _tone(t, 360.0 + 1500.0 * t)) * env * 0.42
    elif name == "dodge":
        mono = rng.standard_normal(frames, dtype=np.float32) * env * 0.30 + _tone(t, 210.0) * env * 0.12
    elif name == "hurt":
        mono = (_tone(t, 92.0) + rng.standard_normal(frames, dtype=np.float32) * 0.30) * env * 0.40
    elif name == "dock":
        mono = (_tone(t, 128.0) + 0.65 * _tone(t, 192.0)) * env * 0.34
    else:
        mono = rng.standard_normal(frames, dtype=np.float32) * np.exp(-t * 0.9, dtype=np.float32) * 0.35 + _tone(t, 38.0) * env * 0.35
    return np.stack([mono, np.roll(mono, 41) * 0.93], axis=1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output
    output.mkdir(parents=True, exist_ok=True)

    tracks = [
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
    ]
    for index, (filename, duration, family, style) in enumerate(tracks):
        seed = MASTER_SEED + index * 1013
        signal = _music_track(duration, style, seed) if family == "music" else _ambience_track(duration, style, seed)
        _write_wav(output / filename, signal)
        print(f"generated {filename}: {(output / filename).stat().st_size} bytes")

    effects = {
        "attack": 0.62,
        "skill": 1.35,
        "dodge": 0.72,
        "hurt": 0.78,
        "dock": 1.20,
        "thunder": 4.40,
    }
    for index, (name, duration) in enumerate(effects.items()):
        _write_wav(output / f"sfx_{name}.wav", _sfx(name, duration, MASTER_SEED + 8000 + index * 97))

    total = sum(path.stat().st_size for path in output.glob("*.wav"))
    print(f"CHK_AUDIO_V7_GENERATED files={len(list(output.glob('*.wav')))} bytes={total}")
    if total < 95_000_000:
        raise SystemExit(f"audio bank too small: {total}")


if __name__ == "__main__":
    main()
