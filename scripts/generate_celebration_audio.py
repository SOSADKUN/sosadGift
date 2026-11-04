"""Short countdown tick and layered stereo firework launches, booms and crackles."""
from pathlib import Path
import array,math,random,sys,wave
root=Path(__file__).resolve().parents[1]/'assets/audio'
rate=22050

def save(name, samples,channels):
 peak=max(abs(x) for x in samples) or 1
 pcm=array.array('h',(round(v/max(1,peak/.85)*32767) for v in samples))
 if sys.byteorder!='little':pcm.byteswap()
 with wave.open(str(root/name),'wb') as f:
  f.setparams((channels,2,rate,0,'NONE','not compressed')); f.writeframes(pcm.tobytes())
samples=[]
for i in range(int(rate*.09)):
 t=i/rate; env=min(1,t/.004)*math.exp(-t*48)*min(1,(.09-t)/.012)
 samples.append((math.sin(2*math.pi*1050*t)+.15*math.sin(2*math.pi*2100*t))*env*.55)
save('countdown_tick.wav',samples,1)
length=int(rate*13.6); left=[0.]*length;right=[0.]*length
rng=random.Random(917)
times=[0.5955, 1.0634, 1.6164, 2.1269, 2.5948, 3.0627, 3.5731, 3.956, 4.3388, 4.7216, 5.1045, 5.4873, 5.8701, 6.0828, 6.2955, 6.806, 7.3164, 7.8269, 8.3373, 8.8478, 9.3582, 9.8687, 10.209, 10.5493, 10.8896, 11.1873, 11.4]
for index,start in enumerate(times):
 pan=.2+(index*.293%.6); smooth=0
 for j in range(int(rate*2)):
  t=j/rate; at=int(start*rate)+j
  if at>=length:break
  noise=rng.uniform(-1,1);smooth=.94*smooth+.06*noise
  boom=(math.sin(2*math.pi*(72-10*t)*t)*.22+smooth*1.5)*math.exp(-t*5.5)
  snap=noise*math.exp(-t*65)*.18
  crackle=noise*(.05 if rng.random()<.035 else 0)*math.exp(-t*2.3)
  value=(boom+snap+crackle)*min(1,t/.003)
  left[at]+=value*math.sqrt(1-pan);right[at]+=value*math.sqrt(pan)
 for j in range(int(rate*.5)):
  t=j/rate; at=int((start-.6)*rate)+j
  if at<0 or at>=length:continue
  v=rng.uniform(-1,1)*.025*math.sin(math.pi*t/.5)**2
  left[at]+=v*(1-pan);right[at]+=v*pan
save('birthday_fireworks_luxe.wav',[v for pair in zip(left,right) for v in pair],2)
print('Rendered 0.09s tick and 13.6s stereo fireworks')
