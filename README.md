# whisper-dictation

Offline, push-to-talk speech-to-text for Linux on Wayland. Uses OpenAI's
Whisper (via [whisper.cpp](https://github.com/ggerganov/whisper.cpp)) for
highly accurate transcription — fully local, no internet required, no API
keys, no data leaves your machine.

Press a key, speak, press again — text appears in any application.

speed upto 300wpm

<img width="1866" height="1078" alt="image" src="https://github.com/user-attachments/assets/dc13dd65-e517-42ab-a439-fdd8c9ce215f" />


## Why Whisper?

| Model | Architecture | Accuracy |
|---|---|---|
| VOSK (Kaldi) | Traditional HMM | ~30% WER on noisy speech |
| Whisper small.en | Transformer (680k hrs trained) | ~8% WER |
| Whisper medium | Transformer (680k hrs trained) | ~6% WER |

Whisper is an order of magnitude more accurate than older STT engines like
VOSK, PocketSphinx, or CMU Sphinx. It handles accents, background noise, and
natural speech patterns far better.

## Features

- Fully offline — zero data sent anywhere
- Push-to-talk toggle (start/stop with one key)
- Types directly into any application via ydotool
- Works on Wayland (GNOME, KDE, Sway, Hyprland)
- Notification support (GNOME/FreeDesktop)
- Tiny disk footprint (~500MB including model)

## Requirements

- Linux with PipeWire (pw-cat) — standard on modern distros
- GNOME, KDE, Sway, Hyprland, or any Wayland compositor
- Python 3 (for setup only)

## Quick Install

```bash
git clone https://github.com/sabr6906i/Voice-to-text-for-Linux.git
cd whisper-dictation
chmod +x setup.sh
./setup.sh
```

This will:
1. Install `ydotool` (if missing)
2. Clone and build `whisper.cpp`
3. Download the `small.en` Whisper model (~466 MB)
4. Install the toggle script to `~/.local/bin/`
5. Bind `Ctrl+Alt+Space` as the dictation toggle

After setup, log out and back in (or run `source ~/.bashrc`).

## Manual Install

```bash
# Install ydotool
sudo apt install ydotool       # Debian/Ubuntu
sudo pacman -S ydotool         # Arch
sudo dnf install ydotool       # Fedora

# Build whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp.git /tmp/whisper.cpp
cmake -B /tmp/whisper.cpp/build -S /tmp/whisper.cpp \
  -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON
cmake --build /tmp/whisper.cpp/build -j$(nproc) --target whisper-cli

# Install
mkdir -p ~/.local/share/whisper-dictation/{bin,models}
cp /tmp/whisper.cpp/build/bin/whisper-cli ~/.local/share/whisper-dictation/bin/

# Download model
wget -c https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin \
  -O ~/.local/share/whisper-dictation/models/ggml-small.en.bin

# Install toggle script
cp whisper-dictation ~/.local/bin/
chmod +x ~/.local/bin/whisper-dictation

# Set keyboard shortcut (GNOME)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whisper-dictation/']"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whisper-dictation/name "'Dictation'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whisper-dictation/command "'$HOME/.local/bin/whisper-dictation'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/whisper-dictation/binding "'<Control><Alt>space'"
```

## Usage

1. Make sure `ydotoold` is running:
   ```bash
   systemctl --user enable ydotoold --now
   ```
2. Press **Ctrl+Alt+Space** — notification says "Recording..."
3. Speak clearly
4. Press **Ctrl+Alt+Space** again — notification says "Transcribing..."
5. Text appears in the focused window

The toggle script can also be run from the terminal:
```bash
whisper-dictation    # start recording
whisper-dictation    # stop, transcribe, type
```

## How It Works

```
Press toggle → pw-cat records audio to /tmp/whisper-dictation.wav
Press toggle → whisper.cpp transcribes the WAV file
            → ydotool types the text into the active window
            → temp WAV file is deleted
```

Audio exists on disk only during transcription (a few seconds), then is
deleted. It never leaves your machine.

## Other Desktop Environments

### KDE
Set the keyboard shortcut in System Settings → Shortcuts → Custom Shortcuts.

### Sway / Hyprland
Add to your config:
```
bindsym $mod+d exec ~/.local/bin/whisper-dictation
```

## Changing the Model

Larger models are more accurate but slower:

```bash
# List available models
bash ~/.local/share/whisper-dictation/models/download-ggml-model.sh

# Download a different model (e.g. medium.en)
bash ~/.local/share/whisper-dictation/models/download-ggml-model.sh medium.en

# Update the toggle script to point to the new model
# Edit ~/.local/bin/whisper-dictation and change MODEL=...
```

| Model | Size | RAM | Speed | Accuracy |
|---|---|---|---|---|
| tiny.en | 75 MB | ~1 GB | Instant | Good |
| base.en | 142 MB | ~1.5 GB | ~1s/s | Better |
| small.en | 466 MB | ~2 GB | ~2s/s | Best value |
| medium.en | 1.5 GB | ~5 GB | ~4s/s | High |
| large-v3 | 3.1 GB | ~10 GB | ~8s/s | Highest |

## Troubleshooting

**Nothing happens when I press the shortcut**
```bash
~/.local/bin/whisper-dictation  # run manually to see errors
```

**ydotoold not running**
```bash
systemctl --user restart ydotoold
```

**No sound recorded**
```bash
pw-cat --record /tmp/test.wav --rate 16000 --channels=1 --format=s16
# speak, then Ctrl+C and check the file
```

**"Command not found" for whisper-dictation**
```bash
export PATH="$PATH:$HOME/.local/bin"
# Add to ~/.bashrc to make permanent
```

## Uninstall

```bash
rm -rf ~/.local/share/whisper-dictation
rm -f ~/.local/bin/whisper-dictation
```

## License

MIT
