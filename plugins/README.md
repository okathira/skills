# zvec-llm-wiki plugin

[日本語](README.ja.md) · [Agent Tools](../README.md)

Build a local test package with Python 3.9 or newer. The builder fetches the two OKF companion skills at the revision pinned by the standalone installers. The generated marketplace contains an English plugin and a Japanese plugin. Install one locale per profile.

```sh
python plugins/build.py
```

The output is `dist/agent-tools/`. Use `--output` with a fresh path to build another copy. Use `--version` to prepare a later version for update testing. The folder contains both marketplace manifests and self-contained plugin folders. Remote Git distribution requires publishing that generated tree at a Git ref with the marketplace manifests at its root.

## Local installation test

The following client paths are ready for testing. Use a clean profile and a separate test repository. Record the client version and OS. Have Node.js 22+, npm/npx, Bash, and Python 3.9+ with PyYAML available. On Windows, run Bash scripts from Git Bash. In each command, use the absolute path to the generated marketplace.

| Client | Install path to test |
| --- | --- |
| Codex | Run `codex plugin marketplace add <marketplace-root>`. In the ChatGPT desktop app, open Plugins, select **Agent Tools**, and install `zvec-llm-wiki` or `zvec-llm-wiki-ja`. |
| Claude Code | Run `/plugin marketplace add <marketplace-root>` and `/plugin install zvec-llm-wiki@agent-tools` (or use `zvec-llm-wiki-ja@agent-tools`). |
| Cursor | Copy the selected generated `plugins/<plugin-name>/` folder into `~/.cursor/plugins/local/`, reload the window, and check Customize. |

These are local installation paths. Public directory submissions and OpenAI web execution are separate.

zvec-grep 0.3.1 is pinned in the plugin. Run the test in an environment with no older zvec-grep daemon already running. Client profiles alone do not isolate the daemon; use a separate OS environment for tests that must run alongside an older daemon.

## Prepare the target repository

From the target repository root, run the bundled bootstrap explicitly. `--skip-mcp` leaves the project's MCP configuration alone and lets the plugin own the connection.

```sh
bash /path/to/plugin/skills/zvec-llm-wiki/scripts/zg-bootstrap.sh --skip-mcp
```

Use `zvec-llm-wiki-ja` in that path for the Japanese package. Keep the CPU multilingual default (`local/potion-multilingual-128m`) for the first test. For a new index, `--embedding local/embeddinggemma-300m` or `--embedding local/qwen3-embedding-0.6b` opts into a larger local model. Use a supported CUDA or Metal runtime to accelerate it. Changing the model on an existing index requires an explicit rebuild.

## Pass criteria

1. Install from the generated artifact. Confirm one Wiki skill, both OKF companions, and one zvec-grep MCP connection are available. Run `llm_wiki.py lint --strict` against the target Wiki from the installed plugin to verify it can find its bundled validator.
2. Index two test repositories containing different known documents. Run `zvec_grep_search` with each repository's absolute `root` and `globs: ["docs/wiki/**"]`. Each result must come from its selected repository.
3. Repeat with an existing standalone install and then with an existing project MCP setting. Disable the overlapping skill and `zvec_grep` connection in the test profile before switching. Check which copy each host loads and confirm the plugin workflow has a single active copy of each component.
4. Update to a new test version and confirm the new version loads without duplicate components. Uninstall it and verify the target repo and its local index are still present. Re-enable any existing components you disabled for the switch.
5. Verify both locales and run the standalone and project dogfooding regression checks before declaring client support.

[Codex packaging](https://developers.openai.com/plugins/build/plugins) · [Claude Code marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) · [Cursor plugins](https://cursor.com/docs/plugins) · [zvec-grep MCP inputs](https://github.com/zvec-ai/zvec-grep/blob/main/docs/03-mcp.md) · [embedding devices](https://zvec.org/en/docs/zvec-grep/embedding-models/)
