# Decisions

* [ADR-0001: Locale folders are independent packages](ADR-0001-locale-independence.md) - Each locale folder of a skill is a complete, standalone package with no cross-locale runtime links.
* [ADR-0002: Skill packages under `skills/`](ADR-0002-catalog-skills-directory.md) - Distributable skill packages live under `skills/<skill-name>/`, keeping the repo root for catalog and dogfooding artifacts.
* [ADR-0003: Karpathy alignment with a single zg engine](ADR-0003-karpathy-alignment-plan.md) - zg is the only search engine, and the wiki adopts Karpathy's operations and page kinds with involved writes.
* [ADR-0004: Project-scoped skills and MCP](ADR-0004-project-skill-install.md) - Skill installs and zvec-grep MCP wiring default to the repository so teammates and Cloud Agents share the same revision without reading a developer home directory.
* [ADR-0005: Align the LLM wiki with OKF v0.3](ADR-0005-okf-alignment.md) - The wiki is an OKF v0.3 bundle; zvec-llm-wiki layers Karpathy operations, zg retrieval, and x-zvec extensions on the official okf-generate and okf-consume skills.
