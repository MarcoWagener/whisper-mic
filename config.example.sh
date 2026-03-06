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
