"""Build the original, license-free Nestarium game SFX bank.

The sounds are deterministic procedural Foley. They combine filtered noise,
mechanical transients, inharmonic percussion, and layered impacts instead of
the pure-tone placeholders used by the first prototype.
"""
from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SFX_DIR = ROOT / "assets" / "sounds" / "sfx"
SAMPLE_RATE = 44100


def blank(duration: float) -> list[float]:
    return [0.0] * int(SAMPLE_RATE * duration)


def add(target: list[float], source: list[float], at: float = 0.0, gain: float = 1.0) -> None:
    start = int(at * SAMPLE_RATE)
    for index, sample in enumerate(source):
        destination = start + index
        if destination >= len(target):
            break
        target[destination] += sample * gain


def normalized(samples: list[float], peak: float = 0.9) -> list[float]:
    highest = max((abs(sample) for sample in samples), default=1.0) or 1.0
    scale = min(1.0, peak / highest)
    return [math.tanh(sample * scale * 1.12) / math.tanh(1.12) * peak for sample in samples]


def lowpass(samples: list[float], cutoff: float) -> list[float]:
    coefficient = 1.0 - math.exp(-2.0 * math.pi * cutoff / SAMPLE_RATE)
    output: list[float] = []
    state = 0.0
    for sample in samples:
        state += coefficient * (sample - state)
        output.append(state)
    return output


def highpass(samples: list[float], cutoff: float) -> list[float]:
    lows = lowpass(samples, cutoff)
    return [sample - low for sample, low in zip(samples, lows)]


def noise(duration: float, seed: int, cutoff: float | None = None) -> list[float]:
    rng = random.Random(seed)
    samples = [rng.uniform(-1.0, 1.0) for _ in range(int(duration * SAMPLE_RATE))]
    return lowpass(samples, cutoff) if cutoff else samples


def shaped_noise(
    duration: float,
    seed: int,
    attack: float = 0.003,
    decay: float = 18.0,
    cutoff: float | None = None,
) -> list[float]:
    source = noise(duration, seed, cutoff)
    output = []
    for index, sample in enumerate(source):
        t = index / SAMPLE_RATE
        envelope = min(1.0, t / max(attack, 0.0001)) * math.exp(-decay * t)
        output.append(sample * envelope)
    return output


def struck(
    frequency: float,
    duration: float,
    decay: float = 7.0,
    brightness: float = 0.5,
) -> list[float]:
    partials = ((1.0, 1.0), (2.03, 0.34), (3.91, 0.18), (6.17, 0.09))
    output = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        attack = min(1.0, t / 0.002)
        value = 0.0
        for partial, level in partials:
            value += math.sin(2 * math.pi * frequency * partial * t) * level
        body = math.sin(2 * math.pi * frequency * 0.501 * t) * 0.16
        output.append((value * brightness + body) * attack * math.exp(-decay * t))
    return output


def sweep(
    start_frequency: float,
    end_frequency: float,
    duration: float,
    decay: float = 6.0,
    roughness: float = 0.0,
) -> list[float]:
    output = []
    phase = 0.0
    rng = random.Random(int(start_frequency + end_frequency))
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        progress = t / duration
        frequency = start_frequency * ((end_frequency / start_frequency) ** progress)
        phase += 2 * math.pi * frequency / SAMPLE_RATE
        envelope = min(1.0, t / 0.003) * math.exp(-decay * t)
        texture = rng.uniform(-1.0, 1.0) * roughness
        output.append((math.sin(phase) + texture) * envelope)
    return output


def pulse(duration: float, frequency: float, decay: float, harmonics: float = 0.2) -> list[float]:
    output = []
    for index in range(int(duration * SAMPLE_RATE)):
        t = index / SAMPLE_RATE
        envelope = min(1.0, t / 0.002) * math.exp(-decay * t)
        value = math.sin(2 * math.pi * frequency * t)
        value += math.sin(2 * math.pi * frequency * 2.17 * t) * harmonics
        output.append(value * envelope)
    return output


def impact(seed: int, heavy: bool = False, duration: float = 0.36) -> list[float]:
    output = blank(duration)
    add(output, shaped_noise(0.2, seed, decay=24 if heavy else 34, cutoff=2200), gain=0.75)
    add(output, sweep(150 if heavy else 260, 58 if heavy else 105, 0.3, decay=9), gain=0.8)
    add(output, pulse(0.2, 72 if heavy else 125, 13), at=0.008, gain=0.75)
    if heavy:
        add(output, shaped_noise(0.26, seed + 1, decay=10, cutoff=480), at=0.04, gain=0.5)
    return normalized(output, 0.84)


def mechanical_click(seed: int = 1, weight: float = 1.0) -> list[float]:
    output = blank(0.115)
    add(output, highpass(shaped_noise(0.035, seed, decay=88), 1200), gain=0.75 * weight)
    add(output, pulse(0.07, 420, 48, 0.34), gain=0.36 * weight)
    add(output, highpass(shaped_noise(0.025, seed + 1, decay=100), 1600), at=0.035, gain=0.4)
    add(output, pulse(0.05, 240, 56), at=0.037, gain=0.22)
    return normalized(output, 0.72)


def whoosh(seed: int, duration: float = 0.34, low: bool = False) -> list[float]:
    source = noise(duration, seed)
    source = highpass(lowpass(source, 2600 if low else 6200), 180 if low else 750)
    output = []
    for index, sample in enumerate(source):
        p = index / max(1, len(source) - 1)
        envelope = math.sin(math.pi * p) ** 1.7
        output.append(sample * envelope)
    return normalized(output, 0.7)


def coin_cluster(seed: int = 20, count: int = 5, duration: float = 0.72) -> list[float]:
    output = blank(duration)
    rng = random.Random(seed)
    for index in range(count):
        at = 0.035 * index + rng.uniform(0.0, 0.035)
        frequency = rng.choice((1180, 1360, 1540, 1780, 2050))
        add(output, struck(frequency, 0.35, decay=15, brightness=0.72), at=at, gain=0.54)
        add(output, mechanical_click(seed + index, 0.45), at=at + 0.012, gain=0.32)
    return normalized(output, 0.82)


def ascending_chime(notes: tuple[float, ...], seed: int = 50, duration: float = 1.1) -> list[float]:
    output = blank(duration)
    spacing = min(0.18, duration / (len(notes) + 1))
    for index, note in enumerate(notes):
        at = index * spacing
        add(output, struck(note, duration - at, decay=5.6, brightness=0.5), at=at, gain=0.64)
        add(output, shaped_noise(0.07, seed + index, decay=45, cutoff=5000), at=at, gain=0.08)
    return normalized(output, 0.82)


def crack(seed: int, glassy: bool = False, heavy: bool = False) -> list[float]:
    duration = 0.66 if heavy else 0.46
    output = blank(duration)
    rng = random.Random(seed)
    for index in range(7 if heavy else 5):
        at = rng.uniform(0.0, 0.19 if heavy else 0.12)
        snap = highpass(shaped_noise(0.11, seed + index, decay=48, cutoff=6800), 800)
        add(output, snap, at=at, gain=rng.uniform(0.32, 0.72))
        if glassy:
            add(output, struck(rng.uniform(1500, 3100), 0.3, decay=18, brightness=0.5), at=at, gain=0.24)
    add(output, impact(seed + 20, heavy=heavy, duration=duration), gain=0.48 if heavy else 0.28)
    return normalized(output, 0.86)


def liquid_pop(seed: int, royal: bool = False) -> list[float]:
    output = blank(0.62)
    add(output, sweep(125, 410, 0.19, decay=12, roughness=0.03), gain=0.72)
    add(output, impact(seed, duration=0.24), gain=0.32)
    for index, at in enumerate((0.12, 0.19, 0.27)):
        add(output, sweep(180 + index * 45, 520 + index * 80, 0.12, decay=20), at=at, gain=0.3)
    if royal:
        add(output, struck(980, 0.42, decay=9, brightness=0.5), at=0.2, gain=0.36)
    return normalized(output, 0.82)


def victory() -> list[float]:
    output = ascending_chime((392, 523.25, 659.25, 783.99), duration=1.42)
    add(output, coin_cluster(71, count=6, duration=0.62), at=0.44, gain=0.35)
    return normalized(output, 0.86)


def defeat() -> list[float]:
    output = blank(1.1)
    add(output, impact(80, heavy=True, duration=0.55), gain=0.62)
    add(output, struck(196, 0.9, decay=3.6, brightness=0.24), at=0.08, gain=0.48)
    add(output, struck(146.83, 0.72, decay=3.8, brightness=0.2), at=0.32, gain=0.52)
    return normalized(output, 0.78)


def phoenix_laugh() -> list[float]:
    output = blank(0.9)
    breath = highpass(lowpass(noise(0.82, 94), 3400), 380)
    phase = 0.0
    for index in range(len(breath)):
        t = index / SAMPLE_RATE
        frequency = 235 + 58 * math.sin(2 * math.pi * 5.2 * t) + 24 * math.sin(2 * math.pi * 11 * t)
        phase += 2 * math.pi * frequency / SAMPLE_RATE
        syllables = max(0.0, math.sin(2 * math.pi * 3.6 * t)) ** 1.5
        breath[index] = (math.sin(phase) * 0.52 + breath[index] * 0.44) * syllables * math.exp(-1.2 * t)
    add(output, breath, at=0.03)
    return normalized(output, 0.72)


def rotten_pulse() -> list[float]:
    output = blank(0.72)
    add(output, sweep(92, 48, 0.58, decay=2.8, roughness=0.08), gain=0.76)
    add(output, shaped_noise(0.6, 101, decay=3.2, cutoff=420), gain=0.62)
    add(output, pulse(0.42, 57, 5, 0.42), at=0.06, gain=0.72)
    return normalized(output, 0.8)


def build_sounds() -> dict[str, list[float]]:
    player_shoot = blank(0.34)
    add(player_shoot, whoosh(110, 0.24), gain=0.68)
    add(player_shoot, sweep(520, 135, 0.24, decay=10, roughness=0.05), gain=0.36)

    shield_break = crack(120, glassy=True)
    add(shield_break, sweep(740, 180, 0.42, decay=8), gain=0.26)

    rage = blank(0.9)
    add(rage, impact(130, heavy=True, duration=0.68), gain=0.76)
    add(rage, sweep(64, 118, 0.72, decay=1.5, roughness=0.09), gain=0.68)

    flap = blank(0.52)
    add(flap, whoosh(150, 0.44, low=True), gain=0.76)
    add(flap, impact(151, duration=0.2), at=0.18, gain=0.18)

    collapse = blank(1.15)
    add(collapse, crack(160, heavy=True), gain=0.65)
    add(collapse, whoosh(161, 0.8, low=True), at=0.18, gain=0.48)
    add(collapse, impact(162, heavy=True, duration=0.7), at=0.4, gain=0.72)

    explosion = blank(1.25)
    add(explosion, impact(170, heavy=True, duration=1.0), gain=0.9)
    add(explosion, lowpass(shaped_noise(1.05, 171, decay=3.8), 2200), gain=0.7)
    add(explosion, crack(172, heavy=True), at=0.08, gain=0.46)

    error = blank(0.43)
    add(error, mechanical_click(180, 1.2), gain=0.55)
    add(error, impact(181, duration=0.34), at=0.035, gain=0.52)

    confirm = blank(0.34)
    add(confirm, mechanical_click(190, 0.85), gain=0.55)
    add(confirm, struck(760, 0.25, decay=14, brightness=0.32), at=0.055, gain=0.45)

    hatch = blank(1.15)
    add(hatch, whoosh(200, 0.48), gain=0.28)
    add(hatch, ascending_chime((523.25, 659.25, 783.99), duration=0.95), at=0.14, gain=0.78)

    return {
        "ui_tap": mechanical_click(2, 0.8),
        "confirm": confirm,
        "error_locked": error,
        "hatch_reveal": hatch,
        "rare_chime": ascending_chime((880, 1174.66, 1396.91), duration=1.35),
        "coin_reward": coin_cluster(10, count=7, duration=0.82),
        "token_reward": ascending_chime((440, 659.25, 987.77), duration=0.9),
        "egg_shard_reward": ascending_chime((415.3, 622.25, 932.33, 1244.5), duration=1.45),
        "player_shoot": normalized(player_shoot, 0.72),
        "player_hit": impact(21, duration=0.36),
        "boss_hit": impact(22, heavy=True, duration=0.42),
        "shield_break": normalized(shield_break, 0.86),
        "rage_mode": normalized(rage, 0.86),
        "victory": victory(),
        "defeat": defeat(),
        "finisher_bonus": ascending_chime((698.46, 987.77, 1318.51), duration=0.9),
        "slime_pop": liquid_pop(30),
        "golem_crack": crack(40, heavy=True),
        "feather_burst": whoosh(50, 0.58),
        "royal_pop": liquid_pop(60, royal=True),
        "guardian_shatter": crack(70, glassy=True, heavy=True),
        "phoenix_flap": normalized(flap, 0.74),
        "phoenix_impact": impact(90, heavy=True, duration=0.62),
        "phoenix_laugh": phoenix_laugh(),
        "rotten_pulse": rotten_pulse(),
        "rotten_collapse": normalized(collapse, 0.86),
        "rotten_explosion": normalized(explosion, 0.9),
        "rotten_shard_harvest": ascending_chime((311.13, 622.25, 932.33, 1396.91), duration=1.4),
    }


def write_wave(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    samples = normalized(samples)
    with wave.open(str(path), "w") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(
            b"".join(
                struct.pack("<h", int(max(-1.0, min(1.0, sample)) * 32767))
                for sample in samples
            )
        )


def main() -> None:
    sounds = build_sounds()
    for name, samples in sounds.items():
        write_wave(SFX_DIR / f"{name}.wav", samples)
    print(f"Generated {len(sounds)} layered game SFX in {SFX_DIR}")


if __name__ == "__main__":
    main()
