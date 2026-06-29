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

# Parse JSON using python to avoid needing jq on old iOS devices
echo "$RESPONSE" | python -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print('\nAI: ' + data['choices'][0]['message']['content'])
except Exception as e:
    pass
" 2>/dev/null

# Fallback if python parsing fails
if [ $? -ne 0 ]; then
    echo -e "\nRaw Response: $RESPONSE"
fi