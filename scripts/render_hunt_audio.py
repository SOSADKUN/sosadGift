"""Render the two Mandarin phone messages and an original five-second mystery sting.

Inputs: tmp/hunt_audio/voice1.wav and voice2.wav, recorded with macOS say.
The sting is original; it does not use or reproduce the Detective Conan theme.
"""
from pathlib import Path
import array
import math
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050

def read(path):
    with wave.open(str(path), 'rb') as f:
        assert f.getnchannels() == 1 and f.getsampwidth() == 2 and f.getframerate() == RATE
        pcm = array.array('h', f.readframes(f.getnframes()))
        if sys.byteorder != 'little': pcm.byteswap()
        return [v / 32768 for v in pcm]

def save(path, samples):
    peak = max(abs(v) for v in samples) or 1
    gain = min(1, .9 / peak)
    pcm = array.array('h', (round(max(-1, min(1, v*gain))*32767) for v in samples))
    if sys.byteorder != 'little': pcm.byteswap()
    with wave.open(str(path), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(pcm.tobytes())

def mystery_voice(samples):
    # Slight pitch lowering and a quiet, short echo while keeping words clear.
    speed = .94
    slowed=[]
    for i in range(int((len(samples)-1)/speed)):
        pos=i*speed
        lo=int(pos)
        slowed.append(samples[lo]*(1-(pos-lo))+samples[lo+1]*(pos-lo))
    result=slowed+[0.]*round(.16*RATE)
    delay=round(.085*RATE)
    for i,v in enumerate(slowed):
        result[i+delay]+=v*.1
    return result

# Original minor-key bass and brass-like notes, with a clean resolved ending.
sting=[0.]*int(5*RATE)
def note(start, duration, midi, volume, brass=False):
    f=440*2**((midi-69)/12)
    for j in range(min(int(duration*RATE), len(sting)-int(start*RATE))):
        t=j/RATE
        env=min(1,t/.018)*min(1,(duration-t)/.09)*math.exp(-t*2)
        phase=2*math.pi*f*t
        tone=math.sin(phase)+(.28 if brass else .12)*math.sin(2*phase)+(.1 if brass else 0)*math.sin(3*phase)
        sting[int(start*RATE)+j]+=tone*env*volume
for start,midi in [(0,45),(.6,52),(1.2,48),(1.8,55),(2.4,50),(3,57),(3.6,45)]:
    note(start,.4,midi,.2)
for start,midi in [(.1,76),(.4,79),(.85,78),(1.3,74),(1.65,77),(2.1,76),(2.7,71),(3.3,72),(3.7,69)]:
    note(start,.35 if start<3.7 else .9,midi,.2,True)
for midi in [57,60,64]: note(3.7,1.1,midi,.08)
for i in range(len(sting)):
    t=i/RATE
    sting[i]*=min(1,t/.08,(5-t)/.5)
save(ROOT/'assets/music/hunt_detective_sting.wav',sting)
for index in [1,2]:
    speech=mystery_voice(read(ROOT/f'tmp/hunt_audio/voice{index}.wav'))
    if index==2:
        speech += [0.]*round(.22*RATE) + sting
    save(ROOT/f'assets/music/voice{index}_mystery.wav',speech)
    print(f'voice{index}: {len(speech)/RATE:.2f}s' + (' (includes 5s original sting)' if index==2 else ''))
