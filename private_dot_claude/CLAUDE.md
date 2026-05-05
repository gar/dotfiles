# Behaviour

Tradeoff: these guidelines bias toward caution over speed. For trivial tasks, use judgement.

## Think before coding

Don't assume. Don't hide confusion. Surface tradeoffs.

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Surgical changes

Touch only what you must. Clean up only your own mess.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that *your* changes made unused. Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

## Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with a verification check per step. Strong success criteria let you loop independently; weak criteria ("make it work") require constant clarification.

# Personal preferences

- Default to simple, readable solutions over clever abstractions
- Prefer deep modules — simple interfaces that hide internal complexity
- Pull complexity downward — handle it inside the module rather than leaking it to callers
- Prefer pure functions; isolate side effects at the edges
- Favour immutable data — avoid mutation unless the language idiom demands it
- Parse, don't validate — use types and structures to make illegal states unrepresentable
- Keep functions small and focused on a single responsibility
- Use descriptive variable and function names; avoid abbreviations

# Workflow

- Start with plan mode for non-trivial tasks; iterate on the plan before writing code. If implementation goes sideways, switch back to plan mode and re-plan rather than pushing through
- IMPORTANT: always verify your work — run tests, linters, or type-checkers to close the feedback loop. If verification fails, fix and retry up to 3 times, then stop and ask for guidance. Look for a Makefile, package.json scripts, or mix.exs to find the right commands
- Run the linter/formatter before committing if one is configured
- Commit with concise messages in imperative mood (e.g. "Add user auth endpoint")
- Prefer small, focused commits over large sweeping ones

# Code style

- Match the existing style of the file and project — do not impose a different convention
- Use the project's configured formatter (prettier, mix format, black, etc.) rather than manually formatting
- Prefer pattern matching and guards over conditionals; use early returns in imperative code
- Use pipelines and function composition to express data transformations
- Prefer map/filter/reduce over imperative loops
- Only add comments where the *why* isn't obvious from the code

# Git

- Default branch is `main`
- Use `git push --force-with-lease` instead of `--force`
- Prefer fast-forward merges; rebase feature branches before merging
- After pushing a feature branch, open a pull request by default — do not wait to be asked. If a PR already exists for the branch, skip this step

# Error handling

- Handle errors at the boundary where they can be meaningfully addressed
- Use tagged tuples ({:ok, _} / {:error, _}) or result types; pattern match on them explicitly
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
