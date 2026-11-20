# zvec-llm-wiki-okf-migrate

An [Agent Skill](https://agentskills.io/) that migrates a wiki written under the older
[`zvec-llm-wiki`](../../zvec-llm-wiki/zvec-llm-wiki/) page contract to an
[Open Knowledge Format (OKF) v0.3](https://github.com/open-knowledge-format/open-knowledge-format/blob/main/SPEC.md)
bundle, then walks a person through reviewing it and records their verification.

It is a one-time tool, kept separate so the daily `zvec-llm-wiki` skill stays small.

## Layout

```
skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/
  README.md                 # this file (catalog / humans)
  install/install.sh        # copy the skill into agent skill directories
  SKILL.md                  # agent entry point: migration procedure
  scripts/okf_migrate.py    # convert pages, log, and root index; record verifications
```

## Install

Install `zvec-llm-wiki` first (its `install.sh` also fetches `okf-generate` and `okf-consume`), then
this skill into the same scope:

```bash
cd your-repo
sh /path/to/skills/skills/zvec-llm-wiki/zvec-llm-wiki/install/install.sh
sh /path/to/skills/skills/zvec-llm-wiki-okf-migrate/zvec-llm-wiki-okf-migrate/install/install.sh
```

The same `--user`, `--claude`, and `--force` options apply. Requires Python 3.9+ with PyYAML.
Restart your agent, then ask it to migrate the wiki to OKF. After the migration is committed you may
remove this skill.
