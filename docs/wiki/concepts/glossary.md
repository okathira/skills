---
type: Concept
title: Glossary
description: One-line definitions of the catalog's ubiquitous language, which other pages alias instead of redefining.
x-zvec-aliases:
  - terminology
  - ubiquitous language
  - UL
  - 用語集
generated: { by: "cursor/auto", at: "2026-11-20T11:07:00Z" }
verified:
  - { by: "human:owner", at: "2026-11-20T15:31:00Z" }
sources:
  - id: readme
    resource: ../../../README.md
    title: Agent Skills catalog
  - id: okf-spec
    resource: https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md
    title: Open Knowledge Format v0.3 specification
---

# Terms

| Term | Definition |
|------|------------|
| **ADR** | Architecture Decision Record — one Markdown file per structural decision in `docs/wiki/decisions/`. |
| **Agent Skill** | Cursor/Codex/OpenCode/Claude instruction package (`SKILL.md` plus supporting files). |
| **Bootstrap** | Run `zg-bootstrap.sh` in a target project to scaffold the wiki, upsert hot memory, wire MCP, and build the first zg index. Distinct from install. |
| **Bundle** | An OKF knowledge bundle: the directory tree under `docs/wiki/`, identified by the root `index.md` frontmatter (`okf_version`). |
| **Coding overlay** | Optional `decisions/` and `runbooks/` on top of Karpathy summary/entity/concept/analysis pages. |
| **Cold memory** | `docs/wiki/**`, retrieved on demand after reading the indexes. |
| **Concept** | One OKF page: a `.md` file whose frontmatter has a non-empty `type`. `index.md`, `log.md`, and files without `type` are not concepts. |
| **Crystallize** | File a durable answer or synthesis from a query into `analyses/` so it compounds. |
| **Deciders** | Superseded ADR key. Acceptance is now a `verified` event by the deciding actor ([ADR-0005](../decisions/ADR-0005-okf-alignment.md)). |
| **Dogfood** | This catalog runs zvec-llm-wiki on itself (`docs/wiki/`, `AGENTS.md`, one zg index). |
| **Frontmatter** | The YAML block between `---` at the top of a wiki page. Home for OKF fields (`type`, `title`, `description`, `status`, `generated`, `verified`, `sources`) and `x-zvec-aliases`. |
| **Hot memory** | Short `AGENTS.md` block loaded every session. |
| **Index** | A generated `index.md` per directory that lists its concepts with their `description`; the root one also carries bundle metadata. Replaces the hand-kept registry. |
| **Ingest** | Compile an immutable source into maintained summary/entity/concept/analysis pages. |
| **Install** | Copy a skill package into an agent skill directory (`install.sh`). Default: `.agents/skills/` in the repo (commit). Also fetches the official OKF skills. Distinct from bootstrap. |
| **Project MCP** | Committed `.cursor/mcp.json` / `.mcp.json` wiring agents to local zvec-grep; distinct from user-level `zg install`. |
| **Involved write** | Show the intended pages, then edit unless the user stops. Not a wiki write-lock. |
| **LLM Wiki** | Karpathy's persistent, interlinked Markdown compiled from raw sources. This skill uses zg only. |
| **OKF** | Open Knowledge Format v0.3: Markdown plus YAML frontmatter with provenance, trust, and lifecycle fields. The official `okf-generate` and `okf-consume` skills own its rules. |
| **One home** | One maintained page per fact; link instead of copying. |
| **Owner** | Actor id `human:owner` for the repository owner of a personal project; not a legal name or handle. |
| **Raw** | Executable code and optional immutable imports in `docs/raw/`, outside the OKF bundle. Index and query them; do not compile the tree into wiki prose. |
| **Trust tier** | What a reader derives from `verified` events newer than `generated.at`: unverified, machine-confirmed, or human-reviewed (needs a `human:` actor). |
| **Ubiquitous language** | Shared English names for catalog facts. Definitions live here; retrieval names live in page `x-zvec-aliases`. |
| **zg / zvec-grep** | Local hybrid, lexical, vector, and exact-search layer used by this skill. |

# Related

- [Catalog layout](catalog-layout.md)
- [Conventions](conventions.md)
- [ADR-0003](../decisions/ADR-0003-karpathy-alignment-plan.md)
- [ADR-0005](../decisions/ADR-0005-okf-alignment.md)
