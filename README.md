# 🎤 Whisper Mic (macOS Local Dictation)

A zero-cost, globally accessible, and completely local AI dictation tool for macOS. Powered by [`whisper.cpp`](https://github.com/ggerganov/whisper.cpp) and triggered via [Raycast](https://www.raycast.com), this setup provides a flawless "Record-then-Transcribe" workflow optimized for complex sentences and specific accents (like South African English), completely eliminating the stuttering and hallucinations common in real-time streaming tools.

---

## What is this and do I need it?

**Whisper Mic lets you speak and have your words instantly typed anywhere on your Mac — completely free, completely private, and works even in apps that normally block dictation (like VS Code or Claude).**

It uses OpenAI's Whisper AI model, but runs 100% locally on your machine. Nothing is sent to the cloud. No subscription. No login.

### How it works once set up

1. Press `⌥⌘T` (Option + Command + T) from anywhere
2. You hear a **ping** — start speaking
3. Press `⌥⌘T` again when done
4. You hear a **chime** — your words are automatically typed into whatever app you were in

That's it. It works in every app, including ones that intercept keyboard shortcuts like VS Code and Claude.

### What you need

- A Mac running macOS (Apple Silicon recommended — M1 or later)
- About **30–45 minutes** for the one-time setup
- Basic comfort copying and pasting Terminal commands (no coding knowledge required)
- A free app called [Raycast](https://raycast.com) (replaces Spotlight)

### Why not just use macOS built-in dictation?

| | macOS Dictation | Whisper Mic |
| --- | --- | --- |
| Cost | Free | Free |
| Privacy | Potentially sent to Apple's servers | 100% local, never leaves your Mac |
| Accuracy (accents) | Okay | Excellent |
| Works in VS Code / Claude | No | Yes |
| Stuttering / hallucinations | Common | None (records first, then transcribes) |

---

## Setup Overview

Setup has four parts. Do them in order:

| Part | What you're doing | Time |
| --- | --- | --- |
| **Part 1** | Install the AI engine and download the model | ~20 min |
| **Part 2** | Install Raycast and add the script | ~5 min |
| **Part 3** | Grant macOS permissions (mic, notifications, paste) | ~5 min |
| **Part 4** | Create your personal config file and test | ~5 min |

---

## Part 1: Install the AI Engine

*You'll be copying commands into Terminal. Open Terminal by pressing `⌘ Space` and typing "Terminal".*

### Step 1: Install the build tools

Copy and paste each block into Terminal, one at a time. Press Enter after each.

```bash
# Install Xcode Command Line Tools — a popup will appear, click "Install"
xcode-select --install
```

Wait for that to finish, then:

```bash
# Install Homebrew — macOS's app manager for developer tools
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then install everything else in one go:

```bash
# Install the audio recorder, AI build tools, and notification helper
brew install cmake ffmpeg sdl2 ninja terminal-notifier jq ollama
```

> **Intel Mac?** Everything works the same — just note that some paths differ (covered in Part 4).

### Step 2: Download and build the Whisper AI engine

This downloads the Whisper source code and compiles it to run natively on your Mac's GPU. It takes 1–3 minutes.

```bash
git clone https://github.com/ggerganov/whisper.cpp.git ~/whisper.cpp
cd ~/whisper.cpp
mkdir -p models
cmake -B build -DWHISPER_METAL=ON -DWHISPER_SDL2=ON
cmake --build build --config Release -j
```

When it finishes, verify it worked by checking that this folder has files in it:

```bash
ls ~/whisper.cpp/build/bin/
```

You should see `whisper-cli` (or `main`) listed.

### Step 3: Download the AI models

**Whisper model** (~600MB) — converts your voice to text:

```bash
cd ~/whisper.cpp
curl -L -o models/ggml-large-v3-turbo-q5_0.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin
```

**Gemma 3 model** (~3.3GB) — polishes the transcript locally (fixes grammar, removes filler words):

```bash
brew services start ollama
ollama pull gemma3:4b
```

> This runs in the background and takes a few minutes depending on your connection. You can continue with the rest of setup while it downloads.

### Step 4: Quick sanity check (optional but recommended)

Run this to confirm your microphone is being picked up by the engine:

```bash
cd ~/whisper.cpp/build/bin
./whisper-stream -m ../../models/ggml-large-v3-turbo-q5_0.bin -l en -t 8 --step 400 --length 5000 -f /tmp/sa-english-test.txt
```

Speak a sentence, wait a few seconds, then press `Ctrl+C`. Run this to see if it was transcribed:

```bash
cat /tmp/sa-english-test.txt
```

If you see your words, the engine is working perfectly.

---

## Part 2: Install Raycast and Add the Script

[Raycast](https://raycast.com) is a free Spotlight replacement. It's what lets the hotkey work globally — even inside VS Code and other apps that would normally block it.

### Step 1: Install Raycast

Download and install it from [raycast.com](https://raycast.com).

### Step 2: Add this repo as a Script Commands directory

1. Open **Raycast Settings** (`⌘,` from Raycast)
2. Go to **Extensions → Script Commands**
3. Click **Add Directory** and select the folder where you cloned/downloaded this repo
4. Raycast will automatically detect `whisper-mic.sh` and register it as **"Whisper Mic"**

### Step 3: Confirm your hotkey

The shortcut `⌥⌘T` is baked into the script and Raycast picks it up automatically. Open Raycast Settings → Extensions and confirm it shows up next to "Whisper Mic".

---

## Part 3: Grant macOS Permissions

macOS requires explicit permission for microphone access, notifications, and auto-paste. You only do this once.

### Step 1: Microphone access

**For Terminal** — run this command, click **OK** when macOS prompts you, then press `Ctrl+C` to stop it:

```bash
/opt/homebrew/bin/ffmpeg -f avfoundation -i ":default" /tmp/test.wav
```

**For Raycast** — go to **System Settings → Privacy & Security → Microphone** and turn on **Raycast**.

### Step 2: Notifications

Go to **System Settings → Notifications → Raycast** and:
- Set **Allow Notifications** to ON
- Set the alert style to **Banners** or **Alerts** (not "None")

### Step 3: Auto-paste permission

The tool automatically pastes your transcript into the active app after transcription. To allow this:

Go to **System Settings → Privacy & Security → Accessibility** and turn on **Raycast**.

---

## Part 4: Personal Config File and Test

### Step 1: Create the config file

The script reads your local paths from a config file so nothing machine-specific gets committed to git.

```bash
cp config.example.sh ~/.whisper-mic.conf
```

### Step 2: Edit it

```bash
nano ~/.whisper-mic.conf
```

The defaults work for most Apple Silicon Macs. If you installed things in non-standard locations, update these values:

| Variable | What it points to | Default |
| --- | --- | --- |
| `WHISPER_DIR` | Where you cloned `whisper.cpp` | `$HOME/whisper.cpp` |
| `FFMPEG_BIN` | Your `ffmpeg` binary | `/opt/homebrew/bin/ffmpeg` |
| `WHISPER_MODEL` | The model file inside `models/` | `ggml-large-v3-turbo-q5_0.bin` |
| `MAX_RECORD_MINS` | Auto-stop recording after this many minutes | `10` |

> **Safety:** `MAX_RECORD_MINS` is a hard cap passed directly to `ffmpeg` — if you forget to stop recording, it will automatically stop after this many minutes, preventing runaway disk writes. Press the hotkey once more after it stops to trigger transcription as normal.

> **Intel Mac users:** change `FFMPEG_BIN` to `/usr/local/bin/ffmpeg`.

Save with `Ctrl+O`, exit with `Ctrl+X`.

### Step 3: Test it

1. Press `⌥⌘T` from any app — you should hear a **Ping** and see a notification: **"✅ Live! Speak now..."**
2. Say a few words
3. Press `⌥⌘T` again — you should hear a **Glass chime** and see **"✅ Copied: [your words]"**
4. Your words are automatically pasted into whatever was active

If nothing happens, check the debug log:
```bash
cat /tmp/whisper_debug.log
```

---

## How it works under the hood

Each hotkey press toggles a state machine:

1. **Start:** Raycast runs the script, which launches `ffmpeg` in the background capturing your mic
2. **Cue:** A Ping plays and a notification confirms it's live
3. **Stop:** The next hotkey press sends a stop signal to `ffmpeg`, which saves the audio file
4. **Transcribe:** The full recording is passed to `whisper-cli` in one shot — no streaming, no hallucinations
5. **Paste:** The transcript is copied to your clipboard and a virtual `Cmd+V` pastes it into the active app
6. **Music resume:** If Spotify was playing when you started recording, it automatically resumes once transcription is complete
7. **Polish:** The transcript is sent to a local Gemma 3 model (via ollama) to fix grammar, spelling, and remove filler words before pasting. Runs entirely on-device — no internet required. Skipped silently if ollama is not running or Gemma 3 is not downloaded.

### Polish model & settings

The polish step uses **`gemma3:4b`** with **`num_ctx: 4096`** (set in the `ollama` API call in `whisper-mic.sh`). To change the model, update both the `ollama list | grep` guard and the JSON payload's `model` field in that script.

`gemma3:4b` (4B params, ~3.3 GB) was chosen over the larger `gemma4` (8B, ~9.6 GB): cleanup accuracy is effectively identical for transcript polishing, but the smaller model loads in ~3 s cold (vs up to ~17 s) and uses ~1/3 the RAM. Warm calls are ~0.9 s either way. The reduced `num_ctx` (vs Gemma 3's 128k default) further cuts cold-load time — transcripts are short, so a 4k window is ample.

---

## Troubleshooting

### Accuracy tips for non-standard accents (e.g. South African English)

| Issue | Fix |
| --- | --- |
| **Poor overall accuracy** | Speak 10–20% slower, keep the mic close, ensure a quiet room |
| **"Data" transcribes as "dater"** | Enunciate strongly, or spell it out if needed |
| **Uncommon words transcribe wrong** | Speak slightly slower and enunciate the syllables clearly |

### Common errors

| Error / Issue | Fix |
| --- | --- |
| **`cmake: command not found`** | Run `brew install cmake` |
| **`xcode-select: error`** | Run `xcode-select --install` |
| **Missing `whisper-cli` binary** | Re-run Part 1, Step 2 — your build likely failed |
| **Model download stalls** | Check your internet connection, or try a smaller test model: `ggml-base.en-q5_0.bin` |
| **No audio captured** | Re-do the `ffmpeg` microphone handshake in Part 3, Step 1 |
| **No notifications appearing** | Check Raycast is enabled in *System Settings → Notifications*. Run `brew install terminal-notifier` if missing. |
| **Hotkey not firing in VS Code / Claude** | Ensure Raycast has Accessibility permission (Part 3, Step 3) |
| **Raycast script not appearing** | Re-add the directory in Raycast Settings → Extensions → Script Commands |
| **Auto-paste not working** | Enable Raycast in *System Settings → Privacy & Security → Accessibility* |
