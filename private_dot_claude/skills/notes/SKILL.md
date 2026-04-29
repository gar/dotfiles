---
name: notes
description: Search, create, and manage personal markdown notes in ~/notes with wikilinks and index notes. Use when the user wants to find, create, or organize their notes.
---

# Notes

Personal notes are kept as plain markdown files in `~/notes`. Many are created through Obsidian, so the conventions below mirror Obsidian's idioms (wikilinks, index notes, title-case filenames) — but the files themselves are just markdown and should be treated that way.

## Vault location

`~/notes`

Mostly flat at the root level.

## Naming conventions

- **Index notes**: aggregate related topics (e.g., `Ralph Wiggum Index.md`, `Skills Index.md`, `RAG Index.md`)
- **Title case** for all note names
- No folders for organization — use links and index notes instead

## Linking

- Use `[[wikilinks]]` syntax: `[[Note Title]]`
- Notes link to dependencies/related notes at the bottom
- Index notes are just lists of `[[wikilinks]]`

## Workflows

### Search for notes

```bash
# Search by filename
find ~/notes -name "*.md" | grep -i "keyword"

# Search by content
grep -rl "keyword" ~/notes --include="*.md"
```

Or use Grep/Glob tools directly on `~/notes`.

### Create a new note

1. Use **Title Case** for the filename
2. Write content as a unit of learning (per vault rules)
3. Add `[[wikilinks]]` to related notes at the bottom
4. If part of a numbered sequence, use the hierarchical numbering scheme

### Find related notes

Search for `[[Note Title]]` across the vault to find backlinks:

```bash
grep -rl "\\[\\[Note Title\\]\\]" ~/notes
```

### Find index notes

```bash
find ~/notes -name "*Index*"
```
