"""Download composer-published CC BY recordings, preserving complete MP3s."""
from pathlib import Path
from urllib.request import Request,urlopen
from urllib.parse import quote
from concurrent.futures import ThreadPoolExecutor
root=Path(__file__).resolve().parents[1]/'assets/music'
tracks=[('game1_carefree.mp3','Carefree'),('game2_sneaky_snitch.mp3','Sneaky Snitch'),('game3_investigations.mp3','Investigations'),('game4_monkeys.mp3','Monkeys Spinning Monkeys')]
def download(item):
 filename,title=item
 url='https://incompetech.com/music/royalty-free/mp3-royaltyfree/'+quote(title)+'.mp3'
 with urlopen(Request(url,headers={'User-Agent':'BirthdayApp asset downloader (CC BY attribution included)'}),timeout=60) as response:
  data=response.read()
 if len(data)<100000 or data.lstrip().startswith(b'<'): raise ValueError('Not an MP3: '+title)
 (root/filename).write_bytes(data)
 print(title,len(data),'bytes',flush=True)
with ThreadPoolExecutor(max_workers=4) as pool:
 list(pool.map(download,tracks))
