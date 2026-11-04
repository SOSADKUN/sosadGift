"""Generate English countdowns with installed macOS voices; no online TTS needed."""
from pathlib import Path
import array, math, subprocess, sys, wave
ROOT=Path(__file__).resolve().parents[1]
TMP=ROOT/'tmp/countdown_audio'
TMP.mkdir(parents=True,exist_ok=True)
RATE=22050
WORDS={0:'Happy birthday!',1:'One!',2:'Two!',3:'Three!',4:'Four!',5:'Five!',6:'Six!',7:'Seven!',8:'Eight!',9:'Nine!',10:'Ten!',15:'Fifteen!',20:'Twenty!',25:'Twenty five!',30:'Thirty!'}

def render(name,text,rough=False):
    aiff=TMP/f'{name}.aiff'; raw=TMP/f'{name}.wav'
    voice='Rocko (English (US))' if rough else 'Samantha'
    subprocess.run(['say','-v',voice,'-r','230' if rough else '180','-o',str(aiff),text],check=True)
    subprocess.run(['afconvert',str(aiff),str(raw),'-f','WAVE','-d','LEI16@22050','-c','1'],check=True)
    with wave.open(str(raw)) as f:
        data=array.array('h',f.readframes(f.getnframes()))
    if sys.byteorder!='little': data.byteswap()
    assert len(data)>1000, 'Speech service returned an empty file'
    active=[i for i,v in enumerate(data) if abs(v)>100]
    data=data[max(0,active[0]-220):min(len(data),active[-1]+330)]
    # Darker arcade announcer, modest saturation for a gritty edge.
    speed=.87 if rough else 1
    out=[]
    for i in range(int((len(data)-1)/speed)):
        p=i*speed; lo=int(p); v=(data[lo]*(1-(p-lo))+data[lo+1]*(p-lo))/32768
        out.append(math.tanh(v*2.2)/1.4 if rough else v)
    limit=.62 if rough else (1.6 if name=='countdown_0' else 1.1)
    if len(out)>int(limit*RATE):
        old=out
        ratio=len(old)/(limit*RATE)
        out=[old[min(len(old)-1,int(i*ratio))] for i in range(int(limit*RATE))]
    peak=max(abs(v) for v in out) or 1
    gain=.8/peak
    for i in range(len(out)):
        out[i]*=gain*min(1,i/100,(len(out)-1-i)/150)
    pcm=array.array('h',(round(v*32767) for v in out))
    if sys.byteorder!='little': pcm.byteswap()
    with wave.open(str(ROOT/'assets/audio'/f'{name}.wav'),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed')); f.writeframes(pcm.tobytes())
    print(name,round(len(out)/RATE,2),flush=True)
for number,word in WORDS.items(): render(f'countdown_{number}',word)
if '--birthday-only' not in sys.argv:
    for number,word in [(3,'Three!'),(2,'Two!'),(1,'One!'),(0,'Start!')]: render(f'game_ready{number}',word,True)
