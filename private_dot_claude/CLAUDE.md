# Personal preferences

- Default to simple, readable solutions over clever abstractions
- Prefer composition over inheritance
- Keep functions small and focused on a single responsibility
- Use descriptive variable and function names; avoid abbreviations

# Workflow

- Start with plan mode for non-trivial tasks; iterate on the plan before writing code
- Run the project's test suite after making changes: look for a Makefile, package.json scripts, or mix.exs to find the right command
- Run the linter/formatter before committing if one is configured
- Commit with concise messages in imperative mood (e.g. "Add user auth endpoint")
- Prefer small, focused commits over large sweeping ones

# Code style

- Match the existing style of the file and project — do not impose a different convention
- Use the project's configured formatter (prettier, mix format, black, etc.) rather than manually formatting
- Prefer early returns over deeply nested conditionals
- Only add comments where the *why* isn't obvious from the code

# Git

- Default branch is `main`
- Use `git push --force-with-lease` instead of `--force`
- Prefer fast-forward merges; rebase feature branches before merging

# Error handling

- Handle errors at the boundary where they can be meaningfully addressed
- Do not swallow errors silently — log or propagate them
- Prefer specific error types over generic catch-all handlers

# Testing

- Write tests for behaviour, not implementation details
- Prefer a single assertion per test when it improves clarity
- Name tests to describe the expected outcome, not the method under test

# Security

- Never commit secrets, credentials, or API keys
- Validate and sanitize all external input at system boundaries
- Use parameterized queries; never interpolate user input into SQL or shell commands

# When unsure

- Ask rather than guess about project conventions
- Read existing code and tests before proposing changes
- Check for a project-level CLAUDE.md — it takes precedence over this file
