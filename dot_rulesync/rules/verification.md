---
root: false
targets: ["*"]
description: "Rules for verifying work is actually correct"
---

# Verification

- Run tests, lint, and typecheck after every change.
- Self-assessment is unreliable — use external signals (build output, test results) as ground truth.
- Don't claim something works without running it.
- If a test suite exists, run it. Don't skip it because "the change is small."
