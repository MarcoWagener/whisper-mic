# Whisper Mic - Configuration Template
# ─────────────────────────────────────────────────────────────────────────────
# Copy this file to ~/.whisper-mic.conf and fill in your paths.
# ~/.whisper-mic.conf is never committed to git — it stays on your machine only.
#
#   cp config.example.sh ~/.whisper-mic.conf
#   nano ~/.whisper-mic.conf
# ─────────────────────────────────────────────────────────────────────────────

# Path to your whisper.cpp installation directory
# Default clone location: $HOME/whisper.cpp
WHISPER_DIR="$HOME/whisper.cpp"

# Path to the ffmpeg binary
# Apple Silicon (M1/M2/M3): /opt/homebrew/bin/ffmpeg
# Intel Mac:                 /usr/local/bin/ffmpeg
FFMPEG_BIN="/opt/homebrew/bin/ffmpeg"

# Whisper model filename (must exist inside $WHISPER_DIR/models/)
# Recommended: ggml-large-v3-turbo-q5_0.bin (best accuracy, fast on Apple Silicon)
# Lightweight:  ggml-base.en-q5_0.bin (faster, lower accuracy)
WHISPER_MODEL="ggml-large-v3-turbo-q5_0.bin"

# Maximum recording duration in minutes — ffmpeg auto-stops to prevent runaway disk writes
MAX_RECORD_MINS=10

# (Optional) Space-separated list of app names treated as Windows remote desktop clients.
# When any of these is the frontmost app, Ctrl+V is used instead of Cmd+V for pasting.
# Default covers the most common apps; override here if you use something else.
# WINDOWS_REMOTE_APPS="AnyDesk Microsoft Remote Desktop TeamViewer"

# (Optional) Claude API key for AI post-processing.
# When set, transcripts are automatically cleaned up: grammar fixed, spelling corrected,
# filler words removed, and text made more concise — before pasting into the active app.
# Get a key at: https://console.anthropic.com/
# CLAUDE_API_KEY="sk-ant-..."
