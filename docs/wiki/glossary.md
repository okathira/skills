# Glossary

> One-line definitions for this catalog and zvec-llm-wiki workflow.

| Term | Definition |
|------|------------|
| **Agent Skill** | Cursor/Codex/OpenCode/Claude instruction package (`SKILL.md` + supporting files). Spec: [agentskills.io](https://agentskills.io/). |
| **Bootstrap** | Run `zg-bootstrap.sh` in a target repo to scaffold `docs/wiki/`, upsert `AGENTS.md`, wire MCP, and build the first `zg` index. |
| **Hot memory** | Short `AGENTS.md` block loaded every session (`ZVEC_LLM_WIKI_*` markers). |
| **Cold memory** | `docs/wiki/**` retrieved on demand via `zg`. |
| **LLM Wiki** | [Karpathy's pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): persistent, interlinked markdown compiled from raw sources; optional search (here: zvec-grep). |
| **zg / zvec-grep** | Local semantic + lexical search CLI and MCP server. Flags: `zg help`. |
| **Registry** | `docs/wiki/index.md` — catalog of wiki pages with one-line summaries. |

## Related

- [architecture.md](architecture.md)
- [runbooks/skill-setup.md](runbooks/skill-setup.md)
