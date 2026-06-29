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

# Fallback: Robust Pure-Bash JSON String Parser (no python or external tools required)
TEMP="${RESPONSE#*\"content\"}"
TEMP="${TEMP#*:}"
TEMP="${TEMP#*\"}"

CONTENT=""
while [ -n "$TEMP" ]; do
    PART="${TEMP%%\"*}"
    CONTENT="${CONTENT}${PART}"
    
    # Count trailing backslashes to see if the closing quote is escaped
    BS_COUNT=0
    while [[ "${PART: -1}" == '\' ]]; do
        BS_COUNT=$((BS_COUNT + 1))
        PART="${PART%?}"
    done
    
    if [ $((BS_COUNT % 2)) -eq 0 ]; then
        break
    fi
    
    CONTENT="${CONTENT}\""
    TEMP="${TEMP#*\"}"
done

if [ -n "$CONTENT" ]; then
    # Unescape escaped double quotes
    CONTENT="${CONTENT//\\\"/\"}"
    # Print output interpreting standard escapes like \n, \t, etc.
    echo -e "\nAI: $CONTENT"
else
    # Ultimate fallback: print raw response
    echo -e "\nRaw Response: $RESPONSE"
fi