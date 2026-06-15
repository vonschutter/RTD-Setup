# RTD AI Chat Launcher

[Back to Tool Reference](../../docs/TOOLS.md) | [Back to Modules](../README.md)

## Purpose

`rtd-ai-chat` provides a consistent RTD command for launching terminal AI chat. It prefers a local Ollama model, installs Ollama when no local runtime is available, pulls a default local model when needed, and falls back to the bundled `chatgpt.sh` OpenAI client only when local execution cannot be used.

## Good For

- Starting an interactive local chat session from a terminal.
- Sending a prompt to a local model from a shell workflow.
- Persisting a preferred local Ollama model with `--model`.
- Keeping the AI client available through the same `rtd-*` command namespace as other RTD tools.

## Requirements

- Bash.
- Ollama for local model execution. If it is not detected, the launcher attempts to install it.
- `curl` or `wget` if Ollama must be installed.
- `curl`, `jq`, the bundled `chatgpt.sh` client, and `OPENAI_KEY` only when remote fallback is needed.

## Quick Start

```bash
rtd-ai-chat
rtd-ai-chat --prompt "Summarize nftables logging"
rtd-ai-chat --model gemma4:e4b
```

Display the wrapper help:

```bash
rtd-ai-chat --help
```

## Local Model Selection

The built-in default local model is `gemma4:e2b`. When a model is selected with `--model`, the launcher pulls it with Ollama. If that pull succeeds, the selected model becomes the saved default for future runs.

The saved model configuration is stored in:

```bash
~/.config/rtd/rtd-ai-chat.config
```

## What It Changes

The wrapper may install Ollama, pull Ollama models, and save the selected local default model. If local execution fails, it may install missing `curl` or `jq` dependencies through RTD package helpers before launching the bundled remote client.

## Related Tools

- [`rtd-oem-bundle-manager`](../oem-bundle-manager.mod/README.md) for adding software bundles.
- [`_rtd_library`](../../core/README.md) for the shared dependency/bootstrap functions used by this launcher.
