---
root: false
targets: ["*"]
description: "Universal coding style and git rules"
---

# Coding Style

- 120 char line width
- Trailing commas everywhere

For language-specific conventions, see:
- TypeScript/JavaScript: ~/.rulesync/rules/typescript.md
- React: ~/.rulesync/rules/react.md
- Rust: ~/.rulesync/rules/rust.md
- Python: ~/.rulesync/rules/python.md

## Git
- NEVER commit/push directly to main
- NEVER amend commits or rewrite history after pushing
- NEVER use `--force` without explicit approval
- Always create new commits — never amend, squash, or rebase unless explicitly asked
- Conventional commit format: `feat|fix|chore|docs|test|refactor(scope): description`
