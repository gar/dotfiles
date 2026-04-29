# Claude Code skills

Each subdirectory here is a [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills): a `SKILL.md` (with optional resource files) that Claude Code auto-discovers from `~/.claude/skills/<name>/`.

## Provenance

Most skills are vendored verbatim from [`mattpocock/skills`](https://github.com/mattpocock/skills) at commit [`f71bb97`](https://github.com/mattpocock/skills/tree/f71bb975bfae2dc0d31c529c7dd4a8479ecc3748).

| Skill | Upstream path |
|---|---|
| `grill-me` | `skills/productivity/grill-me/` |
| `grill-with-docs` | `skills/engineering/grill-with-docs/` |
| `tdd` | `skills/engineering/tdd/` |
| `improve-codebase-architecture` | `skills/engineering/improve-codebase-architecture/` |
| `ubiquitous-language` | `skills/deprecated/ubiquitous-language/` |
| `notes` | adapted from `skills/personal/obsidian-vault/` — renamed, vault path hardcoded to `~/notes`, framing made markdown-generic |

To re-sync a vendored skill:

```bash
git clone --depth 1 https://github.com/mattpocock/skills.git /tmp/upstream-skills
cp -r /tmp/upstream-skills/skills/<category>/<skill>/* private_dot_claude/skills/<skill>/
# review the diff, then bump the SHA in this README
```
