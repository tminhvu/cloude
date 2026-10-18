# Codex setup

From this repository, run with Python 3:

```bash
python3 codex/install.py
```

The installer adds `codex/AGENTS.md` to a managed section of
`$CODEX_HOME/AGENTS.md` (default `~/.codex/AGENTS.md`), preserving existing
instructions outside that section. Review conflicting existing rules before
installing. An existing `AGENTS.override.md` stops installation because it
would take precedence. It installs the Codex skill instructions and a copy
of the shared build helper in `~/.agents/skills/low-priority-build/`.
Existing target files are backed up first, with a printed rollback mapping.
Rerunning replaces the managed section and skill files without duplicating
the instructions. Other skill files are left alone.

The installer preserves `config.toml`, model selection, reasoning effort,
permissions, authentication, and existing hooks. Explanatory replies are a
preference in the instructions. To choose high reasoning effort, use the
client's model settings; installation does not change that preference.

## Compatibility

The rules adapt Claude-specific tool names, model recommendations, memory,
artifact delivery, and attribution to the available Codex client. The model
approval rule is instruction-based. **The Claude subagent hook is not
installed:** Codex currently parses but does not support the hook response
`permissionDecision: "ask"`; it reports a hook error and continues the call.
Installing that hook would not enforce approval. No equivalent enforced
model-approval prompt is claimed here.

Official documentation:

- [Global and project instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [User and repository skills](https://learn.chatgpt.com/docs/build-skills)
- [Hook support and limitations](https://learn.chatgpt.com/docs/hooks)
- [Configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)

## Verification

Start a fresh Codex chat and ask it to summarize its applicable instructions
and list the `low-priority-build` skill. Confirm it proposes edits and waits
for approval. Global instructions are combined with project instructions
and remain subject to the client's higher-priority policies.

Verify the helper without compiling an application:

```bash
bash ~/.agents/skills/low-priority-build/lowprio-build.sh \
  -C /tmp -l /tmp/cloude-build-check.log -- echo hello
```

On Linux, repeat with `sh -c 'nice; ionice -p $$'` to inspect priorities
when `ionice` is installed. Expect nice level 10 in a normal-priority shell
and best-effort disk priority 7. The log should end with `EXIT 0`.
Flutter, Android SDK, and the optional `build_ntd` CLI are separate
prerequisites; see the main README. No application build runs on installation.

## Updates and rollback

Pull repository updates, review them, and rerun the installer to update the
managed instructions and skill. Installed copies do not update on a pull
alone. Restore the original files from the printed backup directory using
its `restore.txt` mapping. Remove a target if that mapping says no backup
existed. Keep newer unrelated edits when restoring instructions. Start a
new chat after updating or restoring.

For isolated verification use `--home /tmp/your-sandbox --codex-home
/tmp/your-sandbox/.codex`; this keeps changes out of your real profile.
