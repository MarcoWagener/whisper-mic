# 🎤 Whisper Mic (macOS Local Dictation)

A zero-cost, globally accessible, and completely local AI dictation tool for macOS. Powered by `whisper.cpp` and Apple Shortcuts, this setup provides a flawless "Record-then-Transcribe" workflow optimized for complex sentences and specific accents (like South African English), completely eliminating the stuttering and hallucinations common in real-time streaming tools.

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

*These must be granted before the Shortcut will work fully. Do this once on any new machine.*

### Step 1: Grant Microphone Access

Because `ffmpeg` runs in the background via Shortcuts, macOS requires explicit permission for both Terminal and Shortcuts.

**For Terminal** (one-time handshake — run this, click OK when prompted, then `Ctrl+C`):
```bash
/opt/homebrew/bin/ffmpeg -f avfoundation -i ":default" /tmp/test.wav
```

**For Shortcuts:**
Go to **System Settings → Privacy & Security → Microphone** and enable **Shortcuts**.

### Step 2: Enable Notifications

The script uses `osascript` to show status popups, which routes through Script Editor.

Go to **System Settings → Notifications → Script Editor** and:
- Set **Allow Notifications** to ON
- Set alert style to **Banners** or **Alerts** (not None)

### Step 3: Enable Accessibility (Auto-Paste)

The script uses a virtual `Cmd+V` keystroke to paste the transcript. This requires Accessibility access.

Go to **System Settings → Privacy & Security → Accessibility** and enable **Shortcuts**.

---

## ⌨️ SECTION 3: Create the Apple Shortcut

### Step 1: Create the Shortcut

1. Open the **Shortcuts** app
2. Click **+** to create a new shortcut and name it **"Whisper Mic"**
3. Search for **"Run Shell Script"** and drag it into the workflow
4. Set **Shell** to `/bin/bash` and **Pass Input** to `to stdin`
5. Paste the entire contents of `whisper-stt.sh` into the script block

> **Note:** The paths at the top of the script (`WHISPER_DIR`, `FFMPEG_BIN`) are hardcoded. Update them if your installation is in a different location.

### Step 2: Assign a Keyboard Shortcut

1. Click the **Settings (sliders) icon** in the top-right of the shortcut editor
2. Click **"Add Keyboard Shortcut"**
3. Press your preferred key combo (e.g., `⌥⌘T`)

### Step 3: Test It

1. Press your hotkey once — you should hear a **Ping** and see **"✅ Live! Speak now..."**
2. Speak for a few seconds
3. Press your hotkey again — you should hear a **Glass** sound and see **"✅ Copied: [your transcript]"**
4. The transcript is auto-pasted into whatever app was active

If something doesn't work, check the debug log:
```bash
cat /tmp/whisper_debug.log
```

### ⚙️ How the Workflow Operates (State Machine)

1. **Start:** Pressing the hotkey launches `ffmpeg` in the background, targeting your default system mic (e.g., AirPods).
2. **Cue:** It plays a system "Ping" sound and shows a "Live" notification. You are free to dictate.
3. **Stop:** Pressing the hotkey again cleanly interrupts `ffmpeg` and saves the complete audio file.
4. **Transcribe:** The audio is passed to `whisper-cli`, giving the AI 100% context to eliminate repetitive stutters.
5. **Paste:** The cleaned text is copied to your clipboard, a "Glass" sound plays, and a virtual `Cmd+V` keystroke pastes the text directly into your current active application.

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
| **Shortcut fails silently** | Check the auto-generated debug log by running `cat /tmp/whisper_debug.log` in Terminal. Ensure *System Settings > Privacy & Security > Shortcuts > Allow Running Scripts* is ON. |