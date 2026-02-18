---
root: false
targets: ["*"]
description: "Universal anti-patterns to avoid"
---

# Anti-Patterns

- NEVER manually edit auto-generated files — regenerate them instead
- NEVER suppress type errors (`as any`, `@ts-ignore`, `@ts-expect-error`)
- NEVER use bandaids or hacks — proper fixes only
- NEVER create new Zod schemas when generated ones exist
- NEVER use `var` declarations
- NEVER add `.unwrap()` calls in Rust code
