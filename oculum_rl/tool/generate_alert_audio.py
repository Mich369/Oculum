"""Render the original, deterministic Oculum RL alert sounds."""
from math import exp, pi, sin, tanh
from random import Random

from generate_audio import RATE, TAU, write

# (timbre, air/noise, syllables). A syllable is (frequency, seconds, vowel).
# Spoken lines are recorded separately. These motifs also work without speech.
PROFILES = {
    "evasore": ("voice", .17, [(236,.11,"o"),(280,.105,"i"),(211,.19,"e"),(258,.10,"e")]),
    "duplicatore": ("echo", .16, [(150,.17,"u"),(173,.13,"e"),(129,.22,"a")]),
    "ashley": ("voice", .23, [(155,.15,"a"),(190,.17,"e"),(146,.26,"o")]),
    "scostubandito": ("voice", .39, [(177,.21,"a"),(207,.13,"e"),(149,.25,"u")]),
    "granScostumato": ("growl", .48, [(89,.22,"e"),(98,.15,"a"),(74,.33,"u")]),
    "solare": ("echo", .16, [(128,.28,"a"),(174,.16,"e"),(120,.26,"o")]),
    "lunare": ("echo", .11, [(185,.23,"l"),(158,.17,"u"),(139,.29,"e")]),
    "goblin": ("voice", .49, [(229,.15,"e"),(186,.09,"a"),(254,.12,"i"),(168,.20,"o")]),
    "infernoNobile": ("echo", .25, [(94,.24,"u"),(127,.18,"e"),(82,.25,"a")]),
    "infernoCinque": ("growl", .42, [(103,.20,"e"),(117,.15,"a"),(77,.39,"o")]),
    "minore": ("growl", .63, [(194,.14,"a"),(154,.25,"a")]),
    "intermedio": ("growl", .55, [(75,.21,"o"),(82,.57,"a")]),
    "ruggitoForesta": ("growl", .71, [(85,.19,"u"),(112,.57,"a")]),
    "cucciolo": ("growl", .41, [(251,.11,"e"),(205,.21,"a"),(264,.10,"i")]),
    "lupo": ("howl", .29, [(165,.15,"o"),(262,.54,"u")]),
    "pipistrello": ("chirp", .16, [(1580,.068,"i"),(1910,.064,"i"),(1360,.11,"i")]),
    "pollo": ("chirp", .30, [(394,.10,"o"),(430,.10,"o"),(698,.22,"e"),(549,.14,"a")]),
    "rana": ("bubble", .33, [(194,.16,"o"),(221,.14,"a"),(145,.22,"o")]),
    "liquido": ("bubble", .22, [(103,.13,"u"),(275,.09,"o"),(144,.28,"u")]),
    "roccia": ("rattle", .71, [(99,.20,"a"),(73,.23,"o"),(51,.14,"u")]),
    "metallo": ("metal", .24, [(338,.10,"i"),(518,.11,"i"),(257,.31,"e")]),
    "zampa": ("rattle", .64, [(281,.074,"a"),(245,.10,"a"),(160,.17,"o")]),
    "eiva": ("bubble", .17, [(109,.18,"u"),(164,.25,"e"),(140,.23,"o")]),
    "campana": ("bell", .10, [(348,.18,"o"),(298,.53,"o")]),
    "sibilo": ("hiss", .77, [(850,.11,"i"),(530,.45,"e")]),
    "pyrel": ("voice", .19, [(230,.14,"e"),(288,.17,"a"),(259,.23,"o")]),
    "lithra": ("voice", .31, [(117,.18,"a"),(154,.13,"e"),(101,.31,"o")]),
    "ombra": ("echo", .34, [(138,.22,"o"),(160,.16,"e"),(110,.31,"u")]),
    "luce": ("echo", .12, [(199,.13,"e"),(245,.21,"a"),(191,.28,"o")]),
    "fabbro": ("voice", .30, [(101,.16,"e"),(151,.16,"a"),(112,.26,"o")]),
}

VOWELS = {
    "a": (800, 1170, 2400),
    "e": (450, 1810, 2540),
    "i": (260, 2240, 3000),
    "o": (500, 870, 2450),
    "u": (310, 660, 2360),
    "l": (360, 1180, 2100),
}


def mix_note(output, timbre, breath, pitch, seconds, vowel, index, rng):
    length = round(seconds * RATE)
    formants = VOWELS[vowel]
    phase = rng.random()
    previous = dark_noise = 0.0
    weights = [
        (
            (.42 if harmonic == 1 else 0)
            + sum(
                level * exp(-((harmonic * pitch - center) / width) ** 2)
                for center, width, level in zip(
                    formants, (210, 300, 380), (1, .62, .29)
                )
            )
        ) / harmonic ** .56
        for harmonic in range(1, min(14, 7500 // pitch) + 1)
    ]
    for sample in range(length):
        age = sample / RATE
        progress = sample / length
        hiss = rng.uniform(-1, 1)
        air = hiss - previous
        previous = hiss
        dark_noise += .13 * (hiss - dark_noise)
        arc = sin(pi * progress)
        rate = (
            .89 + .33 * arc
            if timbre == "howl"
            else 1.1 - .30 * progress
            if timbre in ("bubble", "chirp", "growl")
            else 1 + .12 * arc - .13 * progress
        )
        phase += TAU * pitch * rate / RATE
        voiced = sum(
            weight * sin(phase * harmonic)
            for harmonic, weight in enumerate(weights, 1)
        )
        if timbre == "growl":
            body = (voiced * .56 + .82 * dark_noise) * (.68 + .32 * sin(TAU * age * 32))
            sample_value = tanh(1.3 * body) + .18 * breath * air
        elif timbre in ("metal", "bell"):
            ring = sin(phase + 1.55 * sin(phase * 2.02)) * exp(-age * 5)
            ring += .55 * sin(phase * 2.65) * exp(-age * 9)
            sample_value = ring + air * breath * exp(-age * 38)
        elif timbre == "chirp":
            sample_value = sin(phase + .43 * sin(phase * 2.18)) + .15 * air * breath
        elif timbre == "howl":
            sample_value = voiced + .30 * sin(phase) + dark_noise * breath * .2
        elif timbre == "bubble":
            wobble = .64 * sin(TAU * age * (11 + index * 6))
            body = sin(phase + wobble * sin(phase * 1.98)) * (.79 + wobble * .31)
            sample_value = body + air * breath * exp(-age * 19) * .55
        elif timbre == "hiss":
            sample_value = air * breath * (.64 + .28 * sin(TAU * age * 19)) + .15 * voiced
        elif timbre == "rattle":
            sample_value = dark_noise * breath * .82 + air * exp(-age * 31) * .60 + voiced * .4
        else:
            sample_value = voiced + air * breath * (.22 + exp(-age * 34))
        envelope = min(1, age * 126) * ((1 - progress) ** .67)
        output.append(sample_value * envelope)


def render_alerts():
    for index, (name, (timbre, breath, syllables)) in enumerate(PROFILES.items()):
        rng = Random(49819 + index)
        audio = [0.0] * round(.012 * RATE)
        for part, (pitch, seconds, vowel) in enumerate(syllables):
            mix_note(audio, timbre, breath, pitch, seconds, vowel, part, rng)
            gap = .029 if timbre in ("voice", "echo") else .017
            audio.extend([0.0] * round(gap * RATE))
        if timbre in ("echo", "howl", "bell") or name in ("infernoCinque", "intermedio"):
            dry = list(audio)
            for wait, level in ((.047, .17), (.089, .08)):
                offset = round(wait * RATE)
                audio.extend([0.0] * max(0, len(dry) + offset - len(audio)))
                for i, sample in enumerate(dry):
                    audio[i + offset] += sample * level
        peak = max(abs(sample) for sample in audio)
        write(f"allerta-{name}", audio, .75 / peak)


if __name__ == "__main__":
    render_alerts()
