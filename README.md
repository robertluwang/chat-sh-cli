# Chat Bash / Curl CLI

A lightweight, zero-dependency single-shot command-line interface (CLI) written in pure Bash, specifically designed to interact with **Google Vertex AI** via a **LiteLLM** proxy gateway.

This tool is optimized for highly constrained, legacy, or limited edge nodes (such as the iPad Mini running iOS 9) where modern runtimes like Go or Python 3 are unavailable, difficult to bootstrap, or too heavy to run.

## Features

- **Zero Dependencies:** Runs entirely on standard `bash`, `curl`, and `jq` (if available), with automatic fallback to standard library `python` (compatible with Python 2 and 3) or pure-shell regex extraction. No virtual environments or heavy packages needed.
- **Ultra Lightweight:** Less than 50 lines of shell scripting, making it perfect for dynamic devices or minimal shell environments.
- **Built-in Google Search Support:** Supports the `googleSearch` tool for Vertex AI models through LiteLLM.
- **SSL Bypass for Older Devices:** Uses `curl -k` natively to bypass handshake or certificate errors on older systems (e.g. iOS 9's expired root certs).

## Prerequisites

- Bash
- `curl`
- `jq` or a basic Python installation (pre-installed on almost all Unix-like platforms) for parsing response payloads (with a basic pure-shell regex fallback).
- A running instance of [LiteLLM](https://github.com/BerriAI/litellm) configured to route traffic to Vertex AI.

## Installation

Clone the repository and make the script executable:

```bash
git clone https://github.com/robertluwang/chat-sh-cli.git ~/chat-sh-cli
cd ~/chat-sh-cli
chmod +x chat.sh
```

## Configuration

The CLI relies on standard environment variables. Since background tasks and cron jobs do not load `.bashrc`, storing configuration in a dedicated `~/.env` file is recommended.

1. **Create a `~/.env` file:**
Rename the provided `.env.template` to `~/.env`, fill in your specific values, and source it for your LiteLLM tunnel setup:
```bash
cp .env.template ~/.env
nano ~/.env # add your keys, IP, user, and SSH key
```

2. **For interactive terminal use:**
Add this line to your `~/.bashrc` or `~/.zshrc` so the variables load automatically when you open a terminal:
```bash
source ~/.env
```

## Usage

Pass a prompt directly as an argument for a quick response:

```bash
./chat.sh "What is the capital of France?"
```

### Creating an Alias

For easier access, add an alias to your `~/.bashrc`:

```bash
alias chat='~/chat-sh-cli/chat.sh'
```

Now you can prompt the AI from anywhere in your shell:

```bash
chat "Explain quantum computing in one sentence."
```
