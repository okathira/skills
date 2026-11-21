---
name: zvec-llm-wiki-okf-migrate
description: One-time migration of a pre-OKF zvec-llm-wiki wiki (docs/wiki/ pages without a type key, status working/decided, aliases, source, ADR date/deciders, `## [date] kind | title` logs) to an Open Knowledge Format v0.3 bundle, ending with a human review that records verifications. Use when asked to migrate, convert, or upgrade an LLM wiki to OKF, or when zvec-llm-wiki lint reports pre-OKF keys. Not for day-to-day wiki edits.
license: MIT
---

# Migrate an LLM wiki to OKF v0.3

This skill converts a wiki written under the older zvec-llm-wiki page contract into the OKF bundle
that `zvec-llm-wiki` now maintains. It needs these sibling skills in the same skills directory:
`zvec-llm-wiki` (for `llm_wiki.py`), `okf-generate` (for `validate.py` and the writing rules), and
Python 3.9+ with PyYAML.

Migration rewrites every page, so `generated.at` moves to the migration time and every concept
becomes unverified. That is expected: the migration is where OKF trust starts. The last step asks a
person to review the result and records their verification.

## What the converter does

`scripts/okf_migrate.py convert` is idempotent; pages that already have `type` are skipped.

| Before | After |
| --- | --- |
| no `type` | `type` from the directory (`summaries/` Reference, `entities/` Entity, `concepts/` Concept, `analyses/` Analysis, `decisions/` Decision Record, `runbooks/` Playbook) |
| H1 title and a one-sentence lead (`> ...` or one line, no links) | `title` and `description`; a longer opening stays in the body; remaining headings move up one level |
| `status: working` / `proposed` | `status: draft` |
| `status: decided` / `accepted` | no `status` (stable) |
| `status: superseded`, `superseded_by` | `status: deprecated`, `/`-rooted `superseded_by` |
| `aliases` | `x-zvec-aliases` |
| `source` (path or URL list) | `sources` entries with `id`, `resource`, and a `title` when the target file has an H1 |
| ADR `date` + `deciders` | historical `verified` events (`owner` becomes `human:owner`, `@h` becomes `human:@h`) |
| `sources/` directory | `summaries/`, with links rewritten and deprecated stubs at old paths (`--no-stubs` to skip) |
| project-root `raw/` or `docs/wiki/references/` | `docs/raw/` (outside the bundle) |
| `## [YYYY-MM-DD] kind \| title` log entries | `## YYYY-MM-DD` groups, newest first, `* **Kind**: title` with nested details |
| root `index.md` without frontmatter | `okf_version: "0.3"`, `title`, `description` (and `license` only when given) |

Unknown keys are kept. Every converted page gets `generated: { by: <actor>, at: <now> }`.

## Procedure

Run from the project root. `<skills>` is the directory that holds these skills, such as
`.agents/skills`.

1. **Check the start state.** The git tree is clean, `<skills>/okf-generate` and
   `<skills>/zvec-llm-wiki` exist, and `python3 -c 'import yaml'` works. If OKF skills are missing,
   re-run the `zvec-llm-wiki` `install.sh` without `--no-okf`.
2. **Dry run and plan.** Show the user the page plan:

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate/scripts/okf_migrate.py convert --dry-run --actor "<tool>/<model>"
   ```

   Ask for the bundle `title` and one-sentence `description` if the user has not given them. Pass
   `--license` only when the project states a license; do not guess one.
3. **Convert and index.**

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate/scripts/okf_migrate.py convert --actor "<tool>/<model>" \
     --title "<bundle title>" --description "<one sentence>"
   python3 <skills>/zvec-llm-wiki/scripts/llm_wiki.py index
   ```

4. **Resolve the notes.** For each `note:` line, edit the page by hand following `okf-generate`:
   one-sentence descriptions, `title` on each `sources` entry, a `type` for unmapped directories.
   Then check what the script cannot: bodies that restate frontmatter (alias or source lists), leads
   with links or more than one sentence that stayed in the body, and wiki pages that still describe the old page contract.
5. **Validate.** Fix every error and warning. Lint runs `okf-generate`'s `validate.py` and the
   llm-wiki checks:

   ```bash
   python3 <skills>/zvec-llm-wiki/scripts/llm_wiki.py lint --strict
   ```

   `I204` info on former ADRs is expected until the review step.
6. **Log and index.** Add a `* **Record**: Migrated the wiki to OKF v0.3` entry under today's date
   in `log.md`, regenerate indexes, and run `scripts/zg.sh --index` from the installed `zvec-llm-wiki` skill.
7. **Review and approve.** Walk the user through the migrated pages, grouped by directory: the
   frontmatter, the description, and any judgment edits from step 4. Ask the reviewer to confirm
   each page or group and to state the id to record; `human:owner` is fine for a personal project.
   Never infer the id from git config or the machine. Record only confirmed pages:

   ```bash
   python3 <skills>/zvec-llm-wiki-okf-migrate/scripts/okf_migrate.py verify --actor "human:<id>" <page.md>...
   ```

   Pages the reviewer does not confirm stay unverified. Re-run `llm_wiki.py lint --strict`, then commit.
8. **Report** the converted pages, the notes you resolved, the pages that are now human-reviewed,
   the pages left unverified, and the validation result.

Do not edit a page's meaning after recording its verification; a later change in meaning needs a
new `generated.at` and a new review.
