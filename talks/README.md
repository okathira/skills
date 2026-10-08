# talks (dek)

[dek](https://github.com/hajimism/dek) `@hajimism/dek@0.3.1` presentations for this catalog (Bun 1.4+, `dekc` command).

| Deck | Locale |
|------|--------|
| [decks/zvec-llm-wiki/](decks/zvec-llm-wiki/) | English |
| [decks/zvec-llm-wiki-ja/](decks/zvec-llm-wiki-ja/) | Japanese |

Same slide structure and beat ids; each deck folder is standalone (no shared theme across locales). When catalog facts the talks describe change, update **both** decks in the same change as the skill locales and README pair; run `bunx dekc lint` from `talks/` (`--visual` when slides changed).

## Setup

```bash
cd talks
bun install
bunx playwright install chromium   # first time (for lint --visual)
```

## Day to day

```bash
cd talks
bunx dekc lint --visual    # all decks
bunx dekc build            # dist/*.html per deck

cd decks/zvec-llm-wiki     # or zvec-llm-wiki-ja
bunx dekc                  # dev server for one deck
```

`script.md` in each deck is the source of truth; save triggers sync and lint.
