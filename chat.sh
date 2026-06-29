#!/bin/bash
# chat.sh
# A lightweight pure-bash single-shot CLI for the LiteLLM API
# Good for quick queries without starting the interactive python session

URL="${LITELLM_URL:-http://127.0.0.1:4000/v1/chat/completions}"
KEY="${LITELLM_MASTER_KEY}"
MODEL="${LITELLM_MODEL:-gemini-flash}"

if [ -z "$1" ]; then
    echo "Usage: chat \"Your message here\""
    echo "Example: chat \"How do I list files in linux?\""
    exit 1
fi

PROMPT="$1"

# Escape double quotes to avoid breaking JSON
PROMPT_ESCAPED="${PROMPT//\"/\\\"}"

if [ "${LITELLM_ENABLE_SEARCH:-false}" = "true" ]; then
    PAYLOAD="{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT_ESCAPED\"}], \"tools\": [{\"googleSearch\": {}}]}"
else
    PAYLOAD="{\"model\": \"$MODEL\", \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT_ESCAPED\"}]}"
fi

# Using curl -k to bypass iOS 9 certificate issues
RESPONSE=$(curl -k -s -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $KEY" \
     -d "$PAYLOAD")

# Parse JSON response
if command -v jq >/dev/null 2>&1; then
    CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CONTENT" ] && [ "$CONTENT" != "null" ]; then
        echo -e "\nAI: $CONTENT"
        exit 0
    fi
fi

# Fallback 1: Python (2 or 3)
if command -v python >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
    if ! command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    fi
    echo "$RESPONSE" | $PYTHON_BIN -c "
import sys, json
try:
    data = json.load(sys.stdin)
    content = data['choices'][0]['message']['content']
    print('\nAI: ' + content)
except Exception:
    sys.exit(1)
" 2>/dev/null && exit 0
fi

# Fallback 2: Pure sed/awk/grep parser if both jq and python are missing
# Best-effort extraction for constrained legacy environments
CONTENT_RAW=$(echo "$RESPONSE" | grep -o '"content": "[^"]*"' 2>/dev/null | head -n 1 | cut -d'"' -f4- | sed 's/"$//')
if [ -n "$CONTENT_RAW" ]; then
    echo -e "\nAI: $(echo -e "$CONTENT_RAW")"
else
    echo -e "\nRaw Response: $RESPONSE"
fi