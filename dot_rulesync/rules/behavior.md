---
root: false
targets: ["*"]
description: "Personal AI assistant behavior rules"
---

# Behavior

## Communication
- NEVER end responses with "Want me to do X?" or "Should I implement this?" — answer the question fully and stop. If the user wants more, they'll ask.
- When uncertain, ask — don't guess.

## Workflow: understand → propose → implement → verify
- The answer to "Why is X an improvement?" should never be "I'm not sure."
- ALWAYS do research before making changes — know how the components and libraries in question work. Only look at code relevant to the question, and never refer to other code except for stylistic consistency.
- NEVER use bandaids/hacks — proper fixes only.

## Before Writing Code
- Search for existing implementations before creating new code.
- Check for existing utilities before adding helpers.
- Don't add dependencies without checking if functionality already exists in current deps.
- Reuse patterns from similar files in the codebase.

## Problem-Solving Philosophy
- Is this a real problem? Reject over-engineering.
- Is there a simpler way? Always seek the simplest solution.
- Will it break anything? Backward compatibility matters.
