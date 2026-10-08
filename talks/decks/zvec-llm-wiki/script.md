---
# yaml-language-server: $schema=../../.dek/schema.json
title: "Agent Skills catalog and zvec-llm-wiki"
description: An independent Agent Skills catalog and zvec-llm-wiki, which runs docs/wiki with zg.
event: Internal share
date: 2026-10-08
duration: 5m
---

## Agent Skills catalog and zvec-llm-wiki {#cover}

Hello. Today I will introduce the Agent Skills in this repository and
zvec-llm-wiki at their center.

This deck is both the talk and a handout you can read on its own.
In about eight minutes I will cover three things: what the catalog is,
what the skill does, and how to install it and run the loop.

> Please save questions for the end.

## This repository is a catalog of independent Agent Skills {#catalog}

First, where things live. This is not a slide tool; it is where you
keep skills you install into agents.

### Catalog role {#catalog-role}

A catalog of independent Agent Skills for terminal agents such as
Cursor and Codex.

### Standalone packages {#catalog-package}

Each skill is its own folder. Extract that folder alone and install
and run without the rest of the catalog.

## The main skill is zvec-llm-wiki, which runs a living wiki with zg {#skills}

Today the main skill is zvec-llm-wiki.

### English and Japanese {#skills-locales}

English is `zvec-llm-wiki`; Japanese is `zvec-llm-wiki-ja`, a
separate name with the same behavior per locale.

### What it does {#skills-what}

It compiles sources and design context into a living `docs/wiki/`,
with zvec-grep `zg` as the only retrieval engine.

## Knowledge compounds in one loop from Query through index {#loop}

The skill centers on this loop.

### Query {#loop-query}

Read `docs/wiki/index.md` first, then wiki-scoped hybrid search if
needed, then exact rg when the name is known.

### Work {#loop-work}

Implement or investigate after you have evidence.

### Ingest and record {#loop-ingest}

Wiki writes are involved: show the page plan, then edit; log
substantial changes.

### Lint and index {#loop-lint}

After lint, run incremental `zg index` when the wiki changed.

## Information splits into raw, wiki, hot memory, and README {#layers}

Layers matter. Mixing them up makes it unclear what to edit.

### Raw {#layers-raw}

Executable code and package files are raw. The wiki links to them; it
does not compile the whole tree into prose.

### Wiki {#layers-wiki}

`docs/wiki/` is the compiled knowledge people and agents share.

### Hot memory {#layers-agents}

The marked block in `AGENTS.md` plus the installed skill are the
entry point every turn.

### Human README {#layers-readme}

Root README is installer UI; it is not copied into the skill package.

## Onboarding is two steps: skill install and project bootstrap {#two-steps}

Do not confuse them. Putting the skill on a machine is not the same as
wiring a wiki into a project.

### Skill install {#two-install}

`install/install.sh` copies skill files into agent directories. Once per
machine or repo scope.

### Project bootstrap {#two-bootstrap}

`scripts/zg-bootstrap.sh` wires wiki and zg into the target repo.
Once per project.

## You can install the skill three ways: user-wide, project, Claude {#install}

Three common paths.

### User-wide {#install-user}

Default `install.sh` targets `~/.agents/skills/`. Restart the agent
after install.

### Project scope {#install-project}

`--project` installs into `.agents/skills/` for team repos and Cloud
Agents.

### Claude and updates {#install-claude}

Use `--claude` for Claude Code. After pulling the catalog, re-run with
`--force` when the skill README says so.

## Bootstrap wires wiki and zg into your target repository {#bootstrap}

The target is your project, not this catalog.

### Prerequisites {#bootstrap-prereq}

Node.js 22+. zg arrives as an npm package.

### Run {#bootstrap-run}

Run bootstrap at the project root. It scaffolds when `docs/wiki/` is
missing and leaves an existing wiki untouched.

### Afterward {#bootstrap-after}

Upsert the `AGENTS.md` hot block, wire MCP, and build the index. Restart
the agent again.

## English is default; Japanese is a separate standalone package {#locale}

English is default to keep agent token load lower.

### Independent folders {#locale-independence}

Japanese lives in a `-ja` folder with no symlinks or cross-locale
runtime references.

### Maintenance {#locale-maintain}

When behavior changes, update every locale of the same skill in one
change.

## This catalog dogfoods zvec-llm-wiki {#dogfood}

This repository is where we exercise the skill.

### Wiki contents {#dogfood-wiki}

`docs/wiki/index.md` is the registry; concepts, ADRs, and runbooks
link from there.

### Your next step {#dogfood-next}

Install the skill and bootstrap your own repo to try the same loop.

## Three things to take away {#summary}

Three things to take away.

### Catalog and standalone skills {#summary-catalog}

Skills are complete per folder. The catalog distributes; README is the
human entry.

### Install and bootstrap {#summary-steps}

Copying to the machine and wiring wiki into a project are separate
one-time steps.

### The wiki and zg loop {#summary-loop}

Index first, record and lint, then incremental index updates.

> See each skill README and
> `docs/wiki/runbooks/skill-setup.md` for details.
