---
root: false
targets: ["*"]
description: "Rust conventions"
---

# Rust

## Error Handling
- No `.unwrap()` or `.expect()` in production code — use `?` operator, `.unwrap_or()`, or `.unwrap_or_else()`
- Use `thiserror` for library error types, `anyhow` for application error handling
- Return `Result<T, E>` — never panic for recoverable errors
- Implement `Display` and `Error` on custom error types

## Ownership & Borrowing
- Borrow (`&T`) by default — only clone when ownership transfer is truly needed
- Accept `&str` in function parameters, return `String` — don't require callers to allocate
- Use `Cow<'_, str>` when a function may or may not need to allocate
- Avoid unnecessary `Arc<Mutex<T>>` — redesign to avoid shared mutable state when possible

## Async
- Never call blocking functions inside async context — use `tokio::task::spawn_blocking` instead
- Ensure futures are `Send + Sync` when needed for `tokio::spawn`
- Use `tokio::select!` for concurrent operations with cancellation

## Code Quality
- Run `cargo clippy --all-targets --all-features -- -D warnings` — treat all warnings as errors
- Derive `Debug` on all public types
- Use `pub(crate)` over `pub` for internal APIs — minimize public surface
- Prefer iterator chains over `.collect()` then loop — avoid unnecessary allocations
- Use `#[must_use]` on functions whose return value should not be ignored
