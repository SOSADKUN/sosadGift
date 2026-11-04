"""Mysterious Mandarin male voice: clear normal pitch, no echo or music tail."""
from pathlib import Path
import array, subprocess,sys,wave
root=Path(__file__).resolve().parents[1]
tmp=root/'tmp/hunt_audio';tmp.mkdir(parents=True,exist_ok=True)
for index,text in [(1,'生日快乐，小寿星。我们来玩个解密游戏吧。'),(2,'上面这张图是唯一的线索。破解这场解密游戏吧。')]:
 aiff=tmp/f'voice{index}_clear.aiff';raw=tmp/f'voice{index}_raw.wav'
 subprocess.run(['say','-v','Reed (Chinese (China mainland))','-r','145','-o',str(aiff),text],check=True)
 subprocess.run(['afconvert',str(aiff),str(raw),'-f','WAVE','-d','LEI16@22050','-c','1'],check=True)
 with wave.open(str(raw)) as f:data=array.array('h',f.readframes(f.getnframes()))
 if sys.byteorder!='little':data.byteswap()
 assert len(data)>1000
 active=[i for i,v in enumerate(data) if abs(v)>100]
 data=data[max(0,active[0]-2200):min(len(data),active[-1]+3300)]
 peak=max(abs(v) for v in data) or 1
 out=array.array('h',(round(v/peak*.82*32767*min(1,i/110,(len(data)-1-i)/110)) for i,v in enumerate(data)))
 if sys.byteorder!='little':out.byteswap()
 with wave.open(str(root/f'assets/music/voice{index}_mysterious_clear.wav'),'wb') as f:
  f.setparams((1,2,22050,0,'NONE','not compressed'));f.writeframes(out.tobytes())
 print('voice',index,round(len(data)/22050,2),'seconds, speech only',flush=True)
