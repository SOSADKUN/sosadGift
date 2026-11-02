"""Generate original, deterministic game music loops and short effects (stdlib only)."""
from pathlib import Path
import math
import random
import struct
import wave

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'

def freq(midi):
    return 440 * 2 ** ((midi - 69) / 12)

def note(buf, start, duration, midi, volume=.15, tone='bell'):
    start = int(start * RATE)
    length = int(duration * RATE)
    f = freq(midi)
    for j in range(min(length, len(buf) - start)):
        t = j / RATE
        attack = min(1, t / .008)
        release = min(1, (length - j) / (RATE * .04))
        if tone == 'pad':
            env = math.sin(math.pi * j / length) ** 2
            value = math.sin(2*math.pi*f*t) + .15*math.sin(2*math.pi*f*2*t)
        else:
            env = attack * release * math.exp(-t * (7 if tone == 'bell' else 3))
            value = math.sin(2*math.pi*f*t) + .22*math.sin(2*math.pi*f*2*t) + .06*math.sin(2*math.pi*f*3*t)
        buf[start+j] += value * env * volume

def save(name, buf):
    peak = max(abs(v) for v in buf) or 1
    scale = min(1, .88 / peak)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as wav:
        wav.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        wav.writeframes(struct.pack(f'<{len(buf)}h', *(round(v*scale*32767) for v in buf)))

# Four-bar phrases, repeated with small variations. Notes end before the loop seam.
melodies = {
 'game_hub': (88, [72,76,79,76, 74,77,81,77, 71,74,79,74, 72,76,79,84], .7),
 'game_feather': (116, [79,76,72,76, 81,77,74,77, 79,74,71,74, 76,79,84,79], .5),
 'game_memory': (82, [72,None,79,None, 74,None,81,None, 71,None,79,None, 72,None,76,None], .32),
 'game_maze': (92, [76,79,83,79, 74,77,81,77, 71,74,79,74, 72,76,79,76], .45),
 'game_mole': (124, [72,79,76,79, 74,81,77,81, 71,79,74,79, 76,79,84,79], .55),
}
chords = [(48,60,64,67), (50,62,65,69), (43,59,62,67), (48,60,64,67)]
for name, (bpm, melody, strength) in melodies.items():
    beat = 60 / bpm
    buf = [0.] * round(32 * beat * RATE)
    for bar in range(8):
        chord = chords[bar % 4]
        start = bar * 4 * beat
        for m in chord[1:]:
            note(buf, start, 3.9*beat, m, .035, 'pad')
        for b in (0, 2):
            note(buf, start+b*beat, beat*.8, chord[0], .11, 'plucked')
        for b in range(4):
            m = melody[(bar%4)*4+b]
            if m:
                note(buf, start+b*beat, .85*beat, m + (12 if bar>=4 and b==3 else 0), .15*strength)
            if name in ('game_feather','game_mole'):
                note(buf, start+(b+.5)*beat, .35*beat, chord[1+(b%3)], .035)
    save(name, buf)

for name, pitches in {
 'game_catch':[84,91], 'game_hit':[67,79], 'game_pickup':[76,83,88],
 'game_win':[72,76,79,84], 'game_fail':[67,63,60], 'game_door':[72,79,84],
 'game_plant':[55,60], 'game_escape':[76,79,83,88],
 **{f'game_pad{i}':[m] for i,m in enumerate([72,76,79,84,86,88])},
}.items():
    spacing = .055 if name in ('game_hit','game_catch') else .11
    buf = [0.] * round((len(pitches)*spacing+.3)*RATE)
    for i,m in enumerate(pitches):
        note(buf, i*spacing, .28, m, .28)
    save(name, buf)

rng = random.Random(520)
for name, duration in [('game_step', .09), ('game_boom', .65)]:
    buf=[]
    smooth=0
    for i in range(round(duration*RATE)):
        t=i/RATE
        smooth=.8*smooth+.2*rng.uniform(-1,1)
        env=math.sin(math.pi*min(1,t/.006)) if t<.003 else math.exp(-t*(45 if name=='game_step' else 7))
        buf.append((smooth*.6+math.sin(2*math.pi*(95 if name=='game_step' else 48)*t)*.2)*env)
    save(name,buf)
print('Generated 5 music loops and 16 effects in assets/audio')
