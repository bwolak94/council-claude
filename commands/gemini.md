---
description: Query Gemini directly (optionally with files as context)
argument-hint: <question> [--files glob] [--fast]
allowed-tools: Task
---
Call `gemini-bridge` in `ask` mode (or `large-context`, if `--files` is provided). `--fast` → use `gemini.fastModel` from config.
Input: $ARGUMENTS
Show Gemini's response labeled as external opinion. If it significantly differs from the state of code or existing ADRs — highlight discrepancies in 1-3 points.
