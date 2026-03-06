#!/bin/bash

# --- CONFIGURATION ---
WHISPER_DIR="/Users/marcowagener/Agents/whisper.cpp"
BINARY="$WHISPER_DIR/build/bin/whisper-stream"
MODEL="$WHISPER_DIR/models/ggml-large-v3-turbo-q5_0.bin"
OUTPUT_FILE="/tmp/whisper_transcript_sa.txt"

if pgrep -f "whisper-stream" > /dev/null; then
    # --- STEP: STOPPING & FINAL CLEANUP ---
    osascript -e 'display notification "⏳ Finalizing transcript..." with title "Whisper Mic"'
    pkill -9 -f "whisper-stream"
    sleep 0.6
    
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        # 1. Strip timestamps and tags
        # 2. Grab only the unique lines
        # 3. Filter: If two lines are similar, keep the LONGER/LATER one
        TRANSCRIPT=$(cat "$OUTPUT_FILE" | sed 's/\[[^]]*\]//g' | awk '
        {
            # Clean leading/trailing whitespace
            gsub(/^[ \t]+|[ \t]+$/, "");
            if (length($0) > 10) { # Ignore tiny fragments/hallucinations
                lines[count++] = $0;
            }
        }
        END {
            for (i=0; i<count; i++) {
                # Only print the line if it is NOT a subset of the NEXT line
                is_subset = 0;
                for (j=i+1; j<count; j++) {
                    if (index(lines[j], lines[i]) > 0) {
                        is_subset = 1;
                        break;
                    }
                }
                if (!is_subset) print lines[i];
            }
        }' | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

        echo -n "$TRANSCRIPT" | pbcopy
        afplay /System/Library/Sounds/Glass.aiff &
        osascript -e 'display notification "✅ Copied: $TRANSCRIPT" with title "Whisper Mic"'
    fi
else
    # --- STEP: STARTING ---
    rm -f "$OUTPUT_FILE"
    osascript -e 'display notification "🎤 Initializing AirPods..." with title "Whisper Mic"'
    
    # We increase --step to 1200ms to give the model more "bicycle" context
    nohup "$BINARY" -m "$MODEL" -c 0 -vth 0.6 -l en -t 8 --step 1200 --length 10000 -ps -kc -f "$OUTPUT_FILE" > /dev/null 2>&1 &
    
    sleep 1.5
    afplay /System/Library/Sounds/Ping.aiff &
    osascript -e 'display notification "✅ Live! Speak now..." with title "Whisper Active"'
fi