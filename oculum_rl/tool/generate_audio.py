"""Render the original Oculum Lite piano score and combat sounds as PCM WAV."""

from array import array
from functools import lru_cache
from math import exp, pi, sin, tanh
from pathlib import Path
from random import Random
import wave


RATE = 22050
TAU = 2 * pi
OUTPUT = Path(__file__).resolve().parents[1] / "assets/oculum/lite/audio"

# Each row is one bar of chord tones and a melody in eighth-note slots.
# None represents a rest. These are original themes in distinct keys and metres.
SCORES = {
    "campo": (78, 3, (
        ((50, 57, 65, 69), (77, None, 76, 74, None, 69)),
        ((46, 53, 62, 65), (72, 74, 77, None, 74, None)),
        ((53, 60, 65, 69), (76, None, 72, 69, None, 65)),
        ((48, 55, 62, 67), (67, 69, 72, None, 71, None)),
        ((50, 57, 65, 69), (74, 77, 81, None, 79, 77)),
        ((55, 62, 65, 70), (74, None, 72, 70, 69, None)),
        ((46, 53, 62, 65), (65, 69, 74, None, 72, None)),
        ((45, 52, 58, 64), (71, 69, 64, None, None, None)),
    )),
    "foresta": (66, 4, (
        ((43, 55, 62, 71), (74, None, None, 71, 69, None, 67, None)),
        ((47, 59, 66, 74), (78, None, 76, 74, None, 71, None, None)),
        ((52, 55, 62, 67), (79, 78, 74, None, 71, None, 69, None)),
        ((48, 55, 60, 64), (76, None, None, 74, 72, 74, None, None)),
        ((43, 55, 62, 71), (83, None, 81, 79, 74, None, 71, None)),
        ((45, 57, 60, 64), (81, 79, 76, None, None, 72, None, None)),
        ((48, 55, 62, 67), (74, None, None, 72, 71, 67, None, None)),
        ((50, 55, 57, 64), (69, 67, 66, None, 64, None, None, None)),
    )),
    "sotterraneo": (61, 3, (
        ((40, 47, 55, 62), (67, None, None, 66, 64, None)),
        ((39, 46, 54, 61), (66, None, 63, None, 61, None)),
        ((40, 52, 55, 59), (71, None, 67, 66, None, 64)),
        ((45, 52, 60, 67), (72, None, None, 69, 67, None)),
        ((41, 48, 55, 60), (65, None, 67, None, 72, None)),
        ((38, 45, 53, 60), (69, 67, 65, None, 62, None)),
        ((40, 47, 53, 59), (65, None, None, 64, 62, None)),
        ((35, 47, 54, 63), (63, 66, 59, None, None, None)),
    )),
    "postea": (88, 4, (
        ((42, 54, 57, 64), (69, None, 73, 76, None, 73, 71, None)),
        ((38, 50, 57, 66), (74, 76, None, 81, None, 78, 76, None)),
        ((45, 52, 57, 61), (73, 76, 81, None, 83, None, 81, None)),
        ((40, 52, 59, 66), (78, None, 76, 74, 71, None, 66, None)),
        ((42, 49, 57, 64), (69, 73, 76, None, 78, 76, 73, None)),
        ((35, 47, 54, 62), (74, 78, 81, None, 80, 78, 74, None)),
        ((38, 50, 57, 65), (77, 76, None, 74, 72, None, 69, None)),
        ((37, 49, 56, 63), (68, None, 71, 68, 65, None, 61, None)),
    )),
    "elite": (104, 3, (
        ((48, 55, 63, 67), (72, 75, 79, 78, 75, 72)),
        ((44, 51, 60, 67), (68, None, 72, 75, 79, None)),
        ((46, 53, 62, 65), (77, 74, 72, 70, None, 65)),
        ((43, 50, 59, 65), (67, 71, 74, 77, 74, 71)),
        ((48, 55, 63, 67), (84, 79, 75, 78, 75, 72)),
        ((41, 48, 56, 63), (77, 75, 72, 68, None, 65)),
        ((44, 51, 58, 60), (68, 70, 72, 75, None, 70)),
        ((43, 50, 59, 62), (71, 74, 77, 74, 71, None)),
    )),
    "luce": (84, 4, (
        ((48, 55, 59, 64), (79, None, 81, 83, 84, None, 79, None)),
        ((45, 52, 60, 67), (81, None, 79, 76, 72, None, 76, None)),
        ((53, 60, 64, 69), (84, 86, 88, None, 86, None, 81, None)),
        ((55, 62, 65, 71), (83, 81, 79, None, 74, None, 77, None)),
        ((52, 59, 64, 67), (88, None, 91, 88, 83, None, 79, None)),
        ((45, 52, 60, 69), (84, 83, 81, 79, 76, None, 72, None)),
        ((50, 57, 60, 65), (77, 81, 84, None, 81, 77, 76, None)),
        ((55, 62, 67, 71), (74, 79, 83, None, 79, None, None, None)),
    )),
    "ombra": (90, 4, (
        ((44, 51, 59, 63), (71, None, 70, 68, None, 63, None, None)),
        ((42, 49, 54, 57), (66, 69, 73, None, 72, 69, 66, None)),
        ((40, 47, 56, 59), (76, None, 75, 71, None, 68, 64, None)),
        ((39, 46, 55, 61), (63, 67, 70, 73, 74, None, 67, None)),
        ((44, 51, 59, 63), (83, 82, 80, None, 75, None, 71, None)),
        ((47, 54, 59, 62), (74, None, 78, 77, 74, 71, None, None)),
        ((41, 48, 56, 63), (77, 75, 72, None, 68, None, 65, None)),
        ((39, 46, 55, 58), (70, 63, 67, None, 63, None, None, None)),
    )),
    "veyrth": (118, 4, (
        ((38, 45, 53, 57), (74, 77, 81, None, 80, 77, 74, None)),
        ((39, 46, 55, 58), (75, None, 79, 82, 81, 79, 75, None)),
        ((34, 46, 53, 62), (74, 77, 82, 84, 82, 77, 74, None)),
        ((33, 45, 52, 61), (73, 76, 81, None, 78, 76, 73, None)),
        ((38, 45, 53, 57), (86, 84, 81, 80, 77, 74, 69, None)),
        ((43, 50, 58, 65), (79, 82, 86, None, 84, 82, 77, None)),
        ((39, 46, 55, 62), (82, 79, 75, 74, 70, None, 67, None)),
        ((33, 45, 52, 61), (69, 73, 76, 79, 76, 73, 69, None)),
    )),
}


@lru_cache(maxsize=100)
def piano(note):
    freq = 440 * 2 ** ((note - 69) / 12)
    phases = [TAU * freq * h * (1 + .00019 * h * h) / RATE for h in range(1, 6)]
    return array("f", (
        (1 - exp(-i / 48)) * (
            .66 * sin(i * phases[0]) * exp(-i / 18000)
            + .20 * sin(i * phases[1]) * exp(-i / 9300)
            + .09 * sin(i * phases[2]) * exp(-i / 6200)
            + .04 * sin(i * phases[3]) * exp(-i / 2800)
            + .025 * sin(i * phases[4]) * exp(-i / 1600)
        )
        for i in range(int(RATE * 1.6))
    ))


def mix(track, note, start, volume):
    length = len(track)
    for i, sample in enumerate(piano(note)):
        track[(start + i) % length] += sample * volume


def write(name, signal, gain):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    pcm = array("h", (round(tanh(sample * gain) * 32000) for sample in signal))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as handle:
        handle.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        handle.writeframes(pcm.tobytes())


def render_score(name, tempo, beats, bars):
    beat = 60 / tempo
    track = array("f", [0]) * round(len(bars) * beats * beat * RATE)
    intensity = name in ("elite", "ombra", "veyrth")
    rng = Random(name)
    for bar, (chord, melody) in enumerate(bars):
        for slot in range(beats * 2):
            start = round((bar * beats + slot * .5) * beat * RATE)
            if slot == 0:
                mix(track, chord[0], start, .41 if intensity else .28)
            elif slot % 2 or intensity:
                tone = chord[1 + (slot // 2 + bar % 2) % (len(chord) - 1)]
                mix(track, tone, start, .16 if intensity else .12)
            if melody[slot] is not None:
                strength = (.22 if intensity else .185) + rng.random() * .045
                mix(track, melody[slot], start, strength)
                if name in ("luce", "veyrth") and slot in (0, 4):
                    mix(track, melody[slot] - 12, start, .095)
    dry = track[:]
    for i in range(len(track)):
        track[i] += (
            dry[(i - 2119) % len(dry)] * .15
            + dry[(i - 4339) % len(dry)] * .09
            + dry[(i - 8421) % len(dry)] * .05
        )
    write(name, track, .95)


def render_effects():
    rng = Random(21)
    for name, duration, tones, grit in (
        ("colpo", .26, (103, 159, 247), .32),
        ("ferita", .35, (67, 116, 188), .25),
        ("scudo", .42, (255, 448, 765), .20),
        ("clash", .63, (191, 532, 827, 1217, 2011), .42),
        ("sentenza", .72, (142, 283, 424, 668), .16),
        ("ricompensa", .76, (523, 659, 784), .04),
    ):
        signal = []
        previous = 0.0
        for i in range(round(duration * RATE)):
            t = i / RATE
            white = rng.uniform(-1, 1)
            transient = (white - previous) * exp(-t * 56) * grit
            previous = white
            sample = 0.0
            for j, frequency in enumerate(tones):
                delay = j * .071 if name == "ricompensa" else j * .0014
                elapsed = t - delay
                if elapsed >= 0:
                    sample += (
                        sin(TAU * frequency * elapsed * (1 - min(elapsed, .12) * .8))
                        * (1 - exp(-elapsed * 470))
                        * exp(-elapsed * (7 + 2 * j)) / (2 + j)
                    )
            signal.append((transient + sample) * min(1, (duration - t) * 25))
        write(name, signal, .8)


if __name__ == "__main__":
    for title, score in SCORES.items():
        render_score(title, *score)
    render_effects()
