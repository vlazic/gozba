#!/usr/bin/env bash

# execute script from directory where it is located
cd "$(dirname "$0")" || exit

source bash-helpers.sh

exit_on_error_and_undefined

install_if_not_installed curl ffmpeg jq xclip

source .env

# Check if input file is provided
if [ $# -eq 0 ]; then
    error "Please provide an input MP3 file as an argument."
    exit 1
fi

input_file="$1"
base_name=$(basename "$input_file" .mp3)
current_datetime=$(date +"%Y%m%d_%H%M%S")

# Optional: Set the cut-off time (in seconds)
cut_off_time=${2:-""}

# Prompts
fix_errors_prompt="Ispravite gramaticki tekst koji je dat. Vratite iskljucivo ispravljenu verziju, bez dodatnih komentara."

function check_api_key {
    local api_key="$1"
    local key_name="$2"

    if [ -z "$api_key" ]; then
        error "Please set $key_name in .env file"
        exit 1
    fi
}

function check_deno_installation {
    if ! command -v deno &> /dev/null; then
        error "Deno is not installed. Please install Deno 2 or later."
        echo "For macOS and Linux:"
        echo "curl -fsSL https://deno.land/install.sh | sh"
        echo "For Windows (using PowerShell):"
        echo "irm https://deno.land/install.ps1 | iex"
        exit 1
    fi

    local deno_version=$(deno --version | head -n 1 | cut -d ' ' -f 2)
    if [[ ! "$deno_version" =~ ^2 ]]; then
        error "Deno version 2 or later is required. Your version: $deno_version"
        echo "Please update Deno to the latest version."
        exit 1
    fi
}

function process_audio {
    local input="$1"
    local output="${base_name}_processed_${current_datetime}.mp3"

    if [ -n "$cut_off_time" ]; then
        ffmpeg -i "$input" -t "$cut_off_time" -ar 16000 -ac 1 -map 0:a "$output" -loglevel error
    else
        ffmpeg -i "$input" -ar 16000 -ac 1 -map 0:a "$output" -loglevel error
    fi

    if [ $? -eq 0 ]; then
        echo "$output"
    else
        error "Audio processing failed"
        exit 1
    fi
}

function transcribe_audio_groq {
    local groq_api_key="$1"
    local audio_file="$2"
    local prompt="$3"
    local response
    if [ -n "$prompt" ]; then
        response=$(curl -s https://api.groq.com/openai/v1/audio/transcriptions \
            -H "Authorization: Bearer $groq_api_key" \
            -F "file=@$audio_file" \
            -F model=whisper-large-v3-turbo \
            -F temperature=0 \
            -F response_format=verbose_json \
            -F language=sr \
            -F prompt="$prompt")
    else
        response=$(curl -s https://api.groq.com/openai/v1/audio/transcriptions \
            -H "Authorization: Bearer $groq_api_key" \
            -F "file=@$audio_file" \
            -F model=whisper-large-v3-turbo \
            -F temperature=0 \
            -F response_format=verbose_json \
            -F language=sr)
    fi

    echo "$response"
}

function create_vtt_from_json {
    local json_file="$1"
    local output_file="$2"

    deno run --allow-read --allow-write https://raw.githubusercontent.com/vlazic/json-verbose-to-vtt-converter/main/main.ts --input "$json_file"

    # output file will be input file name with .vtt extension, so we need to replace .json extension with .vtt
    mv "${json_file/.json/.vtt}" "$output_file"
}

function validate_vtt {
    local vtt_file="$1"

    deno run --allow-read --allow-write https://raw.githubusercontent.com/vlazic/json-verbose-to-vtt-converter/main/main.ts --input "$vtt_file" --validate

    # capture the exit code of the last command and return it
    return $?
}

function post_edit_text {
    local openai_api_key="$1"
    local system_message="$2"
    local user_message="$3"

    local request
    request=$(jq -n \
        --arg model "gpt-4o" \
        --arg system "$system_message" \
        --arg user "$user_message" \
        '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}]}')
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $openai_api_key" \
        -d "$request")

    message=$(echo "$response" | jq -r '.choices[0].message.content')
    echo "$message"
}

# Main script execution
check_api_key "$GROQ_API_KEY" "GROQ_API_KEY"
check_api_key "$OPENAI_API_KEY" "OPENAI_API_KEY"
check_deno_installation

info "Processing audio file..."
processed_audio=$(process_audio "$input_file")
if [ -z "$processed_audio" ]; then
    error "Failed to process audio file"
    exit 1
fi
info "Audio processing completed: $processed_audio"

# Rest of the script continues here...
info "Calling Groq API to transcribe audio. Please wait..."
transcription_response=$(transcribe_audio_groq "$GROQ_API_KEY" "$processed_audio" "$fix_errors_prompt")

# Save JSON response
json_file="${base_name}_transcription_${current_datetime}.json"
echo "$transcription_response" > "$json_file"

info "Create original VTT"
original_vtt="${base_name}_original_${current_datetime}.vtt"
echo $json_file
create_vtt_from_json "$json_file" "$original_vtt"
vtt_content=$(cat "$original_vtt")


info "Post-edit the text"
post_edited_text=$(post_edit_text "$OPENAI_API_KEY" "$fix_errors_prompt" "$vtt_content")

info "Save post-edited text"
post_edited_vtt_file="${base_name}_post_edited_${current_datetime}.vtt"
echo "$post_edited_text" > "$post_edited_vtt_file"

info "Validate post-edited VTT"
validate_vtt "$post_edited_vtt_file"
if [ $? -ne 0 ]; then
    error "Post-edited VTT is not valid"
    exit 1
fi

echo "Post-edited text saved as $post_edited_vtt_file"

info "Transcription and post-editing completed."
echo "Original VTT: $original_vtt"
echo "Post-edited VTT: $post_edited_vtt_file"

echo "To compare the original and post-edited VTT files, run:"
echo "meld $original_vtt $post_edited_vtt_file"

# Clean up
rm "$processed_audio"
rm "$json_file"
