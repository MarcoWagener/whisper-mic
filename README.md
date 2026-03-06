# 🎤 Whisper Mic (macOS Local Dictation)

A zero-cost, globally accessible, and completely local AI dictation tool for macOS. Powered by [`whisper.cpp`](https://github.com/ggerganov/whisper.cpp) and triggered via [Apple Shortcuts](https://support.apple.com/guide/shortcuts-mac/welcome/mac) or [Raycast](https://www.raycast.com), this setup provides a flawless "Record-then-Transcribe" workflow optimized for complex sentences and specific accents (like South African English), completely eliminating the stuttering and hallucinations common in real-time streaming tools.

---

## ⚙️ SECTION 0: Configuration

Both scripts load their paths from `~/.whisper-mic.conf` — a local file that is never committed to git, keeping your personal paths private.

### Step 1: Create your config file

```bash
cp config.example.sh ~/.whisper-mic.conf
```

### Step 2: Edit it with your paths

```bash
nano ~/.whisper-mic.conf
```

Set the following three values:

| Variable | Description | Default |
| --- | --- | --- |
| `WHISPER_DIR` | Path to your `whisper.cpp` installation | `$HOME/whisper.cpp` |
| `FFMPEG_BIN` | Path to your `ffmpeg` binary | `/opt/homebrew/bin/ffmpeg` (Apple Silicon) |
| `WHISPER_MODEL` | Model filename inside `$WHISPER_DIR/models/` | `ggml-large-v3-turbo-q5_0.bin` |

> **Intel Mac users:** change `FFMPEG_BIN` to `/usr/local/bin/ffmpeg`.

---

## 🛠 SECTION 1: Core Engine Setup & Terminal Test

*Follow these steps on a clean macOS machine to install the dependencies, build the local model with Apple Metal acceleration, and verify microphone capture.*

### Step 1: Install System Prerequisites

Open your Terminal and install the required build tools and audio processors:

```bash
# 1. Install Xcode Command Line Tools (Click "Install" in the popup)
xcode-select --install

# 2. Install Homebrew (macOS package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install build tools and audio dependencies
brew install cmake ffmpeg sdl2 ninja

# 4. Verify cmake installation (Should show 3.28+)
cmake --version

```

### Step 2: Clone & Build `whisper.cpp`

Download the core repository and build it using Metal (for Apple Silicon GPU acceleration) and SDL2 (for microphone access).

```bash
# Clean install in home directory
rm -rf ~/whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp.git ~/whisper.cpp
cd ~/whisper.cpp
mkdir -p models

# Build the binaries
cmake -B build -DWHISPER_METAL=ON -DWHISPER_SDL2=ON
cmake --build build --config Release -j

```

*Note: Build takes 1-3 minutes. Verify success by ensuring the binaries exist in `~/whisper.cpp/build/bin/`.*

### Step 3: Download Optimized Model

Download the `large-v3-turbo` model, which is highly optimized for accuracy, speed, and handling accents like South African English.

```bash
cd ~/whisper.cpp
curl -L -o models/ggml-large-v3-turbo-q5_0.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin

```

### Step 4: Validate with a Terminal Test

Before automating, ensure the core engine can hear you.

```bash
cd ~/whisper.cpp/build/bin
./whisper-stream -m ../../models/ggml-large-v3-turbo-q5_0.bin -l en -t 8 --step 400 --length 5000 -f /tmp/sa-english-test.txt

```

**Success Criteria:**

1. No errors appear, and live mic capture starts.
2. Speak clearly into your mic (e.g., "Testing Cape Town South African English...").
3. Wait 10-15 seconds, press `Ctrl+C` to stop.
4. Run `cat /tmp/sa-english-test.txt` to verify your transcript was captured perfectly.

---

## 🚀 SECTION 2: macOS Permissions Setup

*Grant these once on any new machine. Both the Shortcuts and Raycast triggers share the same requirements.*

### Step 1: Grant Microphone Access

**For Terminal** (one-time handshake — run this, click OK when prompted, then `Ctrl+C`):
```bash
/opt/homebrew/bin/ffmpeg -f avfoundation -i ":default" /tmp/test.wav
```

**For Shortcuts and Raycast:**
Go to **System Settings → Privacy & Security → Microphone** and enable both **Shortcuts** and **Raycast**.

### Step 2: Enable Notifications

The script uses `osascript` for status popups, which routes through Script Editor regardless of what triggers the script.

Go to **System Settings → Notifications → Script Editor** and:
- Set **Allow Notifications** to ON
- Set alert style to **Banners** or **Alerts** (not None)

### Step 3: Enable Accessibility (Auto-Paste)

The script sends a virtual `Cmd+V` keystroke to paste the transcript into the active app.

Go to **System Settings → Privacy & Security → Accessibility** and enable both **Shortcuts** and **Raycast**.

---

## ⌨️ SECTION 3: Apple Shortcuts Setup

*Use this for most apps. For apps that intercept keystrokes (e.g. VSCode, Claude Code), use the Raycast trigger in Section 4 instead.*

### Step 1: Create the Shortcut

1. Open the **Shortcuts** app
2. Click **+** and name it **"Whisper Mic"**
3. Search for **"Run Shell Script"** and drag it into the workflow
4. Set **Shell** to `/bin/bash` and **Pass Input** to `to stdin`
5. Paste the entire contents of `whisper-stt.sh` into the script block

> **Note:** The script loads paths from `~/.whisper-mic.conf`. Ensure you've completed Section 0 before testing.

### Step 2: Assign a Keyboard Shortcut

1. Click the **Settings (sliders) icon** in the top-right of the shortcut editor
2. Click **"Add Keyboard Shortcut"** and press your preferred combo (e.g., `⌃⌥⌘T`)

---

## 🚀 SECTION 4: Raycast Setup (Recommended for VSCode & Claude Code)

Apple Shortcuts cannot fire when focus is inside a VSCode input box or similar text fields — the app intercepts the keystroke first. Raycast operates at a lower system level and fires globally regardless of focus.

### Step 1: Install Raycast

Download from [raycast.com](https://raycast.com) (free).

### Step 2: Add the Script Commands Directory

1. Open **Raycast Settings → Extensions → Script Commands**
2. Click **Add Directory** and select the folder containing this repo
3. Raycast will automatically detect `ray-whisper-mic.sh` and register it as **"Whisper Mic"**

### Step 3: Confirm the Hotkey

The shortcut `⌃⌥⌘T` is embedded in the script header and Raycast picks it up automatically. Confirm it appears under the script command in Raycast settings.

### Step 4: Test It

1. Press `⌃⌥⌘T` from any app (including VSCode or Claude Code input) — you should hear a **Ping** and see **"✅ Live! Speak now..."**
2. Speak for a few seconds
3. Press `⌃⌥⌘T` again — you should hear a **Glass** sound and see **"✅ Copied: [your transcript]"**
4. The transcript is auto-pasted into the active field

If something doesn't work, check the debug log:
```bash
cat /tmp/whisper_debug.log
```

---

### ⚙️ How the Workflow Operates (State Machine)

1. **Start:** Pressing the hotkey launches `ffmpeg` in the background, targeting your default system mic.
2. **Cue:** A "Ping" sound plays and a "Live" notification appears. Speak freely.
3. **Stop:** Pressing the hotkey again cleanly interrupts `ffmpeg` and saves the audio file.
4. **Transcribe:** The full audio is passed to `whisper-cli` for accurate, stutter-free transcription.
5. **Paste:** The transcript is copied to clipboard, a "Glass" sound plays, and a virtual `Cmd+V` pastes it into the active app.

---

## 🐛 Troubleshooting & Optimizations

### South African English Optimization Tips

| Issue | Fix |
| --- | --- |
| **Poor overall accuracy** | Speak 10-20% slower, keep the mic close, and ensure a quiet room. |
| **"Data" transcribes as "dater"** | Enunciate strongly or spell it out (`d-a-t-a`) if heavily accented. |
| **"Braai" transcribes incorrectly** | Enunciate the rolling 'r' and double vowel strongly (`b-r-a-a-i`). |

### Common System Errors

| Error / Issue | Exact Fix |
| --- | --- |
| **`cmake: command not found`** | Run `brew install cmake` |
| **`xcode-select: error`** | Run `xcode-select --install` |
| **Missing `whisper-stream` binary** | Re-run Section 1, Step 2 (your build failed). |
| **Model download stalls** | Ensure stable internet, or try a smaller model like `ggml-base.en-q5_0.bin` for testing. |
| **No audio captured in Shortcut** | Ensure you ran the `ffmpeg` microphone permission handshake (Section 2, Step 1). |
| **Shortcut fails silently** | Check `cat /tmp/whisper_debug.log`. Ensure *System Settings > Privacy & Security > Shortcuts > Allow Running Scripts* is ON. |
| **Hotkey not firing in VSCode / Claude Code** | Use the Raycast trigger (Section 4) instead — Shortcuts cannot compete with VSCode's keystroke interception. |
| **Raycast script not appearing** | Ensure the repo folder is added as a Script Commands directory in Raycast Settings → Extensions. |
| **Auto-paste not working via Raycast** | Enable Raycast in *System Settings > Privacy & Security > Accessibility*. |