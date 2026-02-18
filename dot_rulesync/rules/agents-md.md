---
root: false
targets: ["*"]
description: "Rules for generating and maintaining AGENTS.md files"
---

# AGENTS.md Guide

When generating or updating AGENTS.md (or CLAUDE.md) files, follow the progressive disclosure principles from https://www.aihero.dev/a-complete-guide-to-agents-md

## Root AGENTS.md — keep it minimal

- One-sentence project description
- Package manager (if not npm)
- Non-standard build/typecheck commands
- Pointers to subdirectory or separate files for everything else

That's it. Everything else goes elsewhere.

## What NOT to put in root

- File structure trees (go stale fast — let the agent navigate)
- Language-specific conventions (move to a separate file or subdirectory AGENTS.md)
- Exhaustive command lists (only non-obvious ones)
- Environment variables, deployment details, testing setup

## Monorepo pattern

- Root: monorepo purpose, how to navigate packages, shared tools
- Package-level: package purpose, specific tech stack, package-specific conventions
- Each level should be focused — the agent sees ALL merged AGENTS.md files in context

## Progressive disclosure

Instead of inlining everything, reference other files:

```
For TypeScript conventions, see docs/TYPESCRIPT.md
```

Agents navigate documentation hierarchies efficiently. Every token in the root file loads on every request regardless of relevance.
