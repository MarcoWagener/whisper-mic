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

## 🚀 SECTION 2: Global Automation via Apple Shortcuts

*Once the terminal test is successful, follow these steps to turn the engine into a global, one-click dictation tool that automatically types for you.*

### Step 1: Grant Background Microphone Permissions

Because our automation script uses `ffmpeg` in the background, you must perform a one-time "handshake" to grant Terminal explicit microphone access. Run this in your Terminal:

```bash
/opt/homebrew/bin/ffmpeg -f avfoundation -i ":default" /tmp/test.wav

```

Click **"OK"** when macOS prompts for Microphone permissions, then press `Ctrl + C` to stop it.

### Step 2: Create the macOS Shortcut

1. Open the **Shortcuts** app on your Mac.
2. Click **+** to create a new shortcut and name it **"Whisper Mic"**.
3. Search for the **"Run Shell Script"** action and drag it into your workflow.
4. Set the **Shell** to `/bin/bash` and **Pass Input** to `to stdin`.
5. Click the **Settings (Sliders) icon** in the right sidebar, click **"Add Keyboard Shortcut"**, and assign your preferred toggle keys (e.g., `⌥⌘T`).

### Step 3: Add the Script

Copy the entire contents of your `whisper-mic-sa.sh` file and paste it directly into the "Run Shell Script" block in the Shortcuts app.
*(Note: If your installation paths differ from the default `~`, update the `WHISPER_DIR` and `FFMPEG_BIN` variables at the top of the script).*

### ⚙️ How the Workflow Operates (State Machine)

1. **Start:** Pressing the hotkey launches `ffmpeg` in the background, targeting your default system mic (e.g., AirPods).
2. **Cue:** It plays a system "Ping" sound and shows a "Live" notification. You are free to dictate.
3. **Stop:** Pressing the hotkey again cleanly interrupts `ffmpeg` and saves the complete audio file.
4. **Transcribe:** The audio is passed to `whisper-cli`, giving the AI 100% context to eliminate repetitive stutters.
5. **Paste:** The cleaned text is copied to your clipboard, a "Glass" sound plays, and a virtual `Cmd+V` keystroke pastes the text directly into your current active application.

---

## 🔐 Required macOS Permissions (New Machine Checklist)

These permissions must be granted manually on any new Mac. Without them, specific parts of the workflow will silently fail.

| Permission | Where to Grant | Required For |
| --- | --- | --- |
| **Microphone → Terminal** | System Settings → Privacy & Security → Microphone → enable Terminal | `ffmpeg` capturing audio in the background |
| **Microphone → Shortcuts** | System Settings → Privacy & Security → Microphone → enable Shortcuts | Running the script via the Shortcuts hotkey |
| **Notifications → Script Editor** | System Settings → Notifications → Script Editor → Allow Notifications → set style to **Banners** or **Alerts** | `osascript` showing status popups (recording started, transcript ready, errors) |
| **Accessibility → Shortcuts** | System Settings → Privacy & Security → Accessibility → enable Shortcuts | Auto-paste (`Cmd+V`) injecting the transcript into the active app |

> **Tip:** Grant all four permissions before your first run. Missing Microphone permission causes silent recording failure. Missing Notifications permission means you'll hear sounds but see no popups. Missing Accessibility permission means the transcript is copied to clipboard but never auto-pasted.

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