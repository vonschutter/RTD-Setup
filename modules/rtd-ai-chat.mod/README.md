# RTD AI Chat Launcher

[Back to Tool Reference](../../docs/TOOLS.md) | [Back to Modules](../README.md)

## Purpose

`rtd-ai-chat` provides a consistent RTD command for launching the bundled terminal chat client. It loads the shared RTD library, ensures required command-line dependencies are present, then forwards arguments to the client.

## Good For

- Starting an interactive chat session from a terminal.
- Sending a prompt from a shell workflow.
- Keeping the AI client available through the same `rtd-*` command namespace as other RTD tools.

## Requirements

- Bash, `curl`, and `jq`.
- The bundled `chatgpt.sh` client available in the installed RTD files.
- Any API key or provider configuration required by that bundled client.

## Quick Start

```bash
rtd-ai-chat
rtd-ai-chat --prompt "Summarize nftables logging"
```

Display the wrapper help:

```bash
rtd-ai-chat --help
```

## What It Changes

The wrapper may install missing `curl` or `jq` dependencies through RTD package helpers. Requests and provider behavior are handled by the bundled chat client.

## Related Tools

- [`rtd-oem-bundle-manager`](../oem-bundle-manager.mod/README.md) for adding software bundles.
- [`_rtd_library`](../../core/README.md) for the shared dependency/bootstrap functions used by this launcher.
