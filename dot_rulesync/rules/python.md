---
root: false
targets: ["*"]
description: "Python conventions"
---

# Python

## Type Safety
- Add type hints to all function signatures — parameters and return types
- Use modern syntax: `list[str]` not `List[str]`, `str | None` not `Optional[str]` (3.10+)
- Use `Protocol` for structural typing instead of `ABC` when possible
- Use `dataclasses` or Pydantic models — avoid raw dicts for structured data

## Error Handling
- Never bare `except:` — always catch specific exception types
- No mutable default arguments (`def f(items=[])`) — use `None` with sentinel pattern
- Raise from context: `raise NewError() from original` to preserve tracebacks
- Custom exceptions should inherit from a project-specific base, not bare `Exception`

## Style
- f-strings over `.format()` or `%` formatting
- `pathlib.Path` over `os.path` for file operations
- `logging` module over `print()` for any non-trivial output
- Absolute imports over relative imports
- Use `if __name__ == "__main__":` guard in scripts

## Tooling
- `uv` for package management — `pyproject.toml` only, no `setup.py` or `requirements.txt`
- `ruff` for linting and formatting
- `pytest` for testing — no `unittest.TestCase`, use fixtures and parametrize

## Async
- Never call blocking functions inside `async def` — use `asyncio.to_thread()` or run in executor
- Use `async with` for async context managers — don't forget cleanup
