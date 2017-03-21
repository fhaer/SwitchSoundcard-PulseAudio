# SwitchSoundcard-PulseAudio
Switches active sound card on linux using PulseAudio

Usage: 
- ```perl switch-soundcard.pl``` to move all audio streams to the next sink
- ```perl switch-soundcard.pl <sink-id>``` to move all audio streams to the given sink ID (ID as specified by pactl)

Requires: perl pulse-audio
