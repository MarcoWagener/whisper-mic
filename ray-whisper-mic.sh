#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Whisper Mic
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎤
# @raycast.shortcut ctrl+opt+cmd+t

# --- DEBUG LOGGING SETUP ---
LOG_FILE="/tmp/whisper_debug.log"
echo "========================================" >> "$LOG_FILE"
echo "[$(date)] SCRIPT TRIGGERED (Raycast)" >> "$LOG_FILE"

# --- CONFIGURATION ---
# Load user config from ~/.whisper-mic.conf (copy config.example.sh to get started)
CONFIG="$HOME/.whisper-mic.conf"
if [ ! -f "$CONFIG" ]; then
    osascript -e 'display notification "❌ Missing ~/.whisper-mic.conf — see README" with title "Whisper Mic"' 2>>"$LOG_FILE"
    echo "[$(date)] ERROR: Config file not found at $CONFIG" >> "$LOG_FILE"
    exit 1
fi
source "$CONFIG"

BINARY="$WHISPER_DIR/build/bin/whisper-cli"
if [ ! -f "$BINARY" ]; then BINARY="$WHISPER_DIR/build/bin/main"; fi

MODEL="$WHISPER_DIR/models/$WHISPER_MODEL"
AUDIO_FILE="/tmp/whisper_audio_sa.wav"
PID_FILE="/tmp/whisper_rec.pid"

echo "[$(date)] BINARY PATH: $BINARY" >> "$LOG_FILE"
echo "[$(date)] FFMPEG PATH: $FFMPEG_BIN" >> "$LOG_FILE"

if [ -f "$PID_FILE" ]; then
    # --- STEP 2: STOPPING & TRANSCRIBING ---
    echo "[$(date)] STATE: Stopping & Transcribing" >> "$LOG_FILE"
    PID=$(cat "$PID_FILE")
    rm -f "$PID_FILE"

    echo "[$(date)] Killing PID: $PID" >> "$LOG_FILE"
    osascript -e 'display notification "⏳ Finalizing transcript..." with title "Whisper Mic"' 2>>"$LOG_FILE"

    # Send Interrupt signal to FFmpeg
    kill -INT "$PID" 2>>"$LOG_FILE"
    sleep 0.8

    echo "[$(date)] Running Whisper on $AUDIO_FILE..." >> "$LOG_FILE"
    RAW_OUTPUT=$("$BINARY" -m "$MODEL" -f "$AUDIO_FILE" -l en -nt -np 2>>"$LOG_FILE")

    echo "[$(date)] RAW WHISPER OUTPUT: $RAW_OUTPUT" >> "$LOG_FILE"

    TRANSCRIPT=$(echo "$RAW_OUTPUT" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

    if [ -n "$TRANSCRIPT" ]; then
        echo "[$(date)] Cleaned Transcript: $TRANSCRIPT" >> "$LOG_FILE"
        echo -n "$TRANSCRIPT" | pbcopy
        afplay /System/Library/Sounds/Glass.aiff &
        osascript -e "display notification \"✅ Copied: $TRANSCRIPT\" with title \"Whisper Mic\"" 2>>"$LOG_FILE"

        echo "[$(date)] Attempting auto-paste..." >> "$LOG_FILE"
        osascript -e 'tell application "System Events" to keystroke "v" using command down' 2>>"$LOG_FILE"
    else
        echo "[$(date)] ERROR: No transcript generated. Audio might be empty." >> "$LOG_FILE"
        osascript -e 'display notification "❌ No speech detected" with title "Whisper Mic"' 2>>"$LOG_FILE"
    fi
else
    # --- STEP 1: STARTING ---
    echo "[$(date)] STATE: Starting Recording" >> "$LOG_FILE"
    rm -f "$AUDIO_FILE"

    if [ ! -f "$FFMPEG_BIN" ]; then
        echo "[$(date)] ERROR: FFMPEG not found at $FFMPEG_BIN" >> "$LOG_FILE"
        osascript -e 'display notification "❌ ERROR: FFMPEG not found" with title "Whisper Mic"' 2>>"$LOG_FILE"
        exit 1
    fi

    osascript -e 'display notification "🎤 Initializing mic..." with title "Whisper Mic"' 2>>"$LOG_FILE"

    echo "[$(date)] Launching FFMPEG..." >> "$LOG_FILE"
    nohup "$FFMPEG_BIN" -y -loglevel error -f avfoundation -i ":default" -ar 16000 -ac 1 "$AUDIO_FILE" >> "$LOG_FILE" 2>&1 &

    PID=$!
    echo $PID > "$PID_FILE"
    echo "[$(date)] FFMPEG PID: $PID saved to $PID_FILE" >> "$LOG_FILE"

    sleep 0.5
    afplay /System/Library/Sounds/Ping.aiff &
    osascript -e 'display notification "✅ Live! Speak now..." with title "Whisper Active"' 2>>"$LOG_FILE"
fi
echo "[$(date)] END OF RUN" >> "$LOG_FILE"
