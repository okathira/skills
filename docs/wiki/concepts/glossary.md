---
status: decided
aliases:
  - terminology
  - ubiquitous language
  - UL
  - 用語集
source:
  - ../../../README.md
---
# Glossary

> One-line definitions for this catalog and the zvec-llm-wiki workflow. This page owns the ubiquitous language; other pages alias the fact they own.

## Terms

| Term | Definition |
|------|------------|
| **ADR** | Architecture Decision Record — one Markdown file per structural decision in `docs/wiki/decisions/`. |
| **Agent Skill** | Cursor/Codex/OpenCode/Claude instruction package (`SKILL.md` plus supporting files). |
| **Bootstrap** | Run `zg-bootstrap.sh` in a target project to scaffold the wiki, upsert hot memory, wire MCP, and build the first zg index. Distinct from install. |
| **Coding overlay** | Optional `decisions/` and `runbooks/` on top of Karpathy source/entity/concept/analysis pages. |
| **Cold memory** | `docs/wiki/**`, retrieved on demand after reading the registry. |
| **Crystallize** | File a durable answer or synthesis from a query into `analyses/` so it compounds. |
| **Dogfood** | This catalog runs zvec-llm-wiki on itself (`docs/wiki/`, `AGENTS.md`, one zg index). |
| **Frontmatter** | The YAML block between `---` at the top of a wiki page. Home for `status`, `aliases`, `source`, and ADR lifecycle. |
| **Hot memory** | Short `AGENTS.md` block loaded every session. |
| **Ingest** | Compile an immutable source into maintained source/entity/concept/analysis pages. |
| **Install** | Copy a skill package into an agent skill directory (`install.sh`). Distinct from bootstrap. |
| **Involved write** | Show the intended pages, then edit unless the user stops. Not a wiki write-lock. |
| **LLM Wiki** | Karpathy's persistent, interlinked Markdown compiled from raw sources. This skill uses zg only. |
| **One home** | One maintained page per fact; link instead of copying. |
| **Raw** | Executable code and optional immutable `raw/` dumps. Index and query them; do not compile the tree into wiki prose. |
| **Registry** | `docs/wiki/index.md` — grouped catalog of every wiki page with one-line summaries. |
| **Ubiquitous language** | Shared English names for catalog facts. Definitions live here; retrieval names live in page `aliases`. |
| **zg / zvec-grep** | Local hybrid, lexical, vector, and exact-search layer used by this skill. |

## Related

- [Catalog layout](catalog-layout.md)
- [Conventions](conventions.md)
- [ADR-0003](../decisions/ADR-0003-karpathy-alignment-plan.md)
