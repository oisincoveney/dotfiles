---
root: false
targets: ["*"]
description: "Universal anti-patterns to avoid"
---

# Anti-Patterns

## Code Quality
- NEVER manually edit auto-generated files — regenerate them instead
- NEVER suppress type errors (`as any`, `@ts-ignore`, `@ts-expect-error`)
- NEVER use bandaids or hacks — proper fixes only
- NEVER create new Zod schemas when generated ones exist
- NEVER use `var` declarations
- NEVER add `.unwrap()` calls in Rust code

## Error Handling
- Silent error handling is NEVER permitted
- Every fallback and default value MUST have specific business logic reasoning
- Unexpected errors MUST be logged, not swallowed
- Errors affecting user flow MUST surface to the user — never hide failures

## Testing
- NEVER commit code without tests for new functionality
- NEVER skip tests or mark them as skipped to make CI pass
- NEVER disable or delete existing tests — fix the code, not the tests
- Test both success and error cases
