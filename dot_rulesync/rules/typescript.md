---
root: false
targets: ["*"]
description: "TypeScript and JavaScript conventions"
---

# TypeScript / JavaScript

## Type Safety
- No `any` — use `unknown` and narrow with type guards
- No type assertions (`as`) — use discriminated unions or type predicates instead
- No `@ts-ignore` or `@ts-expect-error` — fix the type error properly
- Prefer `interface` for object shapes, `type` for unions and intersections
- Use `satisfies` operator to validate types without widening
- Use `export type` for type-only exports

## Error Handling
- Throw `Error` objects with descriptive messages, not strings
- Use typed error hierarchies — never `catch(e) {}` with empty blocks
- Prefer early returns over nested conditionals for error cases

## Async
- Always handle promise rejections — no floating promises
- Use `AbortController` for cancellable operations
- Never `await` in a loop when `Promise.all` works — avoid sequential waterfalls

## Imports & Exports
- Prefer named exports over default exports
- Import directly from source modules — avoid barrel file re-exports in large projects
- Use `import type` for type-only imports

## Style
- Only `console.error` allowed — no `console.log`, `console.warn`, `console.info`
- Single quotes in JS, double quotes in JSX
- Trailing commas everywhere
