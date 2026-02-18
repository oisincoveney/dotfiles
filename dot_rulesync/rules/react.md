---
root: false
targets: ["*"]
description: "React conventions and patterns"
---

# React

## Components
- Functional components only — no class components
- Prefer named exports over default exports
- Keep components under ~200 lines — extract hooks and sub-components when growing
- Don't define components inside other components — extract them
- Prefer composition (children, render props, slots) over deeply nested props

## Hooks
- Call hooks at the top level only — never conditionally or in loops
- Specify all dependencies in hook dependency arrays correctly
- Don't use `useEffect` for data fetching — use a data fetching library (TanStack Query, SWR, etc.)
- Don't use `useEffect` for deriving state — compute during render instead
- If React Compiler is enabled, don't add manual `useMemo`/`useCallback` — the compiler handles it

## Data & State
- State hierarchy: URL params → server cache → local state. Don't duplicate server state locally.
- Forms via a form library with Zod validation — no uncontrolled forms or manual validation
- Colocate related code: component, hooks, types, and styles in the same directory

## Accessibility
- Use semantic HTML (`<button>`, `<nav>`, `<main>`) — not divs with roles
- Provide meaningful `alt` text for images
- Add labels for form inputs — no unlabeled inputs
- Include keyboard event handlers alongside mouse events

## Testing
- Test behavior, not implementation — query by role, label, or text, not by class or test-id
- Use `key` prop with unique IDs in lists — not array indices
