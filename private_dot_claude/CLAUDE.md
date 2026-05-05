# Behaviour

Tradeoff: these guidelines bias toward caution over speed. For trivial tasks, use judgement.

## Think before coding

- State assumptions explicitly. If uncertain, ask rather than guess.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- Read existing code and tests before proposing changes.

## Simplicity first

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## Surgical changes

Touch only what you must.

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Note unrelated dead code; don't delete it.
- Remove imports/variables that *your* changes orphaned. Leave pre-existing dead code alone unless asked.

Every changed line should trace directly to the user's request.

## Goal-driven execution

Define success criteria. Loop until verified.

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan with a verification check per step. Strong success criteria let you loop independently; weak criteria ("make it work") require constant clarification.

# Workflow

- Start in plan mode for non-trivial tasks; iterate on the plan before coding. If implementation goes sideways, return to plan mode rather than pushing through.
- IMPORTANT: verify your work — run tests, linters, or type-checkers. If verification fails, fix and retry up to 3 times, then stop and ask. Look for a Makefile, `package.json` scripts, or `mix.exs` to find commands.
- Run the project's configured formatter before committing.
- Commit messages: imperative mood, concise (e.g. "Add user auth endpoint"). Prefer small, focused commits.

# Code preferences

- Prefer deep modules — simple interfaces hiding internal complexity. Pull complexity downward rather than leaking it to callers.
- Prefer pure functions; isolate side effects at the edges.
- Favour immutable data — avoid mutation unless the language idiom demands it.
- Parse, don't validate — use types and structures to make illegal states unrepresentable.
- Prefer pattern matching and guards over conditionals; early returns in imperative code.
- Pipelines and `map`/`filter`/`reduce` over imperative loops.
- Comments only where the *why* isn't obvious from the code.

# Error handling

- Handle errors at the boundary where they can be meaningfully addressed.
- Use tagged tuples (`{:ok, _}` / `{:error, _}`) or result types; pattern match on them explicitly.

# Git

- Default branch: `main`.
- Use `git push --force-with-lease`, never `--force`.
- Prefer fast-forward merges; rebase feature branches before merging.
- After pushing a feature branch, open a pull request by default — don't wait to be asked. Skip if one already exists.

---

A project-level `CLAUDE.md` takes precedence over this file.
