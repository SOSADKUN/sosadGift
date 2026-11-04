"""Original cinematic intro impacts, independent of gameplay sound effects."""
from pathlib import Path
import math, random, wave, array, sys
root=Path(__file__).resolve().parents[1]/'assets/audio'
rate=22050
for name,duration,base in [('game_intro_title',.65,180),('game_intro_line',.48,240)]:
 rng=random.Random(917); samples=[]; noise=0; phase=0
 for i in range(round(rate*duration)):
  t=i/rate
  phase+=2*math.pi*(base+110*math.exp(-t*24))/rate
  noise=.72*noise+.28*rng.uniform(-1,1)
  attack=min(1,t/.006)
  thump=math.sin(phase)*math.exp(-t*11)*.7
  sweep=noise*math.exp(-t*17)*.4
  knock=(math.sin(2*math.pi*720*t)+.4*math.sin(2*math.pi*1420*t))*math.exp(-t*22)*.24
  shimmer=math.sin(2*math.pi*1300*t)*math.exp(-t*28)*.025
  samples.append((thump+sweep+shimmer+knock)*attack*min(1,(duration-t)/.06))
 peak=max(abs(x) for x in samples)
 pcm=array.array('h',(round(v/peak*.72*32767) for v in samples))
 if sys.byteorder!='little':pcm.byteswap()
 with wave.open(str(root/f'{name}.wav'),'wb') as f:
  f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(pcm.tobytes())
 print(name,duration)
