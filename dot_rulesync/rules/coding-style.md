---
root: false
targets: ["*"]
description: "Universal coding style rules"
---

# Coding Style

## TypeScript / JavaScript
- No `any`, `unknown`, or `as` casts
- No `var` declarations
- No `@ts-ignore` or `@ts-expect-error`
- Only `console.error` allowed — no `console.log`, `console.warn`, `console.info`
- Prefer generated Zod schemas with `.pick()`/`.omit()` over creating new ones

## Rust
- No `.unwrap()` in new code — use `?` operator or `.unwrap_or()`
- Always add `#[utoipa::path]` for OpenAPI documentation on endpoints

## General
- Trailing commas everywhere
- Single quotes in JS, double quotes in JSX
- 120 char line width

## Git
- NEVER commit/push directly to main
- NEVER amend commits or rewrite history after pushing
- NEVER use `--force` without explicit approval
- Always create new commits — never amend, squash, or rebase unless explicitly asked
- Conventional commit format: `feat|fix|chore|docs|test|refactor(scope): description`
