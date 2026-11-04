Treasure hunt phone audio:
- voice1_mysterious_clear.wav: 生日快乐，小寿星。我们来玩个解密游戏吧。
- voice2_mysterious_clear.wav: 上面这张图是唯一的线索。破解这场解密游戏吧。

Current voices: macOS Reed (Chinese mainland, male), rate 145, normal pitch, no echo.
Both current recordings contain speech only, with no appended music.
Regenerate with scripts/generate_phone_voices.py.
The previous *_mystery.wav files and hunt_detective_sting.wav are not used by the phone.

The phone plays each recording when its voice-message bubble is tapped.
After voice 1 finishes, the clue picture arrives, then voice 2 arrives.
Each incoming voice or photo triggers vibration and assets/audio/phone_message.wav.

hunt_location.png: AI-generated pencil sketch hinting at a note under a bed.
ImageGen prompt summary: hand-drawn bed on paper, visible bed-bottom gap, small hidden note,
subtle pencil arrow and question mark, no written solution or QR code.
Final QR payload: SOSAD-GIFT-FINALE

Game music (complete composer-published recordings, not the generated WAV loops):
- game1_carefree.mp3 — Carefree, Kevin MacLeod
- game2_sneaky_snitch.mp3 — Sneaky Snitch, Kevin MacLeod
- game3_investigations.mp3 — Investigations, Kevin MacLeod
- game4_monkeys.mp3 — Monkeys Spinning Monkeys, Kevin MacLeod
All licensed CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
Composer: https://incompetech.com/
Original MP3s from https://incompetech.com/music/royalty-free/mp3-royaltyfree/
No musical edits; playback volume lowered and recordings looped in the app.
Attribution is available from the music-note button in each game.
Download script: scripts/download_game_music.py.
