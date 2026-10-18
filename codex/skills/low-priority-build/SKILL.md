---
name: low-priority-build
description: Run explicitly requested heavy Flutter, Gradle, or other compilation jobs at low CPU and disk priority with limited Gradle workers. Use for requested APKs, app bundles, or long builds, especially when machine responsiveness matters.
---

# Low-priority builds in Codex

Build only when the user requests it in the current message. This skill
does not authorize builds on its own.

Run the adjacent `lowprio-build.sh` with the shell execution tool:

```bash
bash ~/.agents/skills/low-priority-build/lowprio-build.sh \
  -C /absolute/project/path -w 4 -l /tmp/feature-build.log -- \
  flutter build apk --flavor dev -t lib/main_dev.dart
```

The helper uses `nice -n 10`, plus `ionice -c2 -n7` on Linux when available;
Windows Git Bash uses below-normal process priority. Children inherit that
priority. Gradle receives a worker cap, no daemon, and no parallel projects.
Memory limits remain the project's responsibility. Use `-w 2` or a single
build on smaller machines; choose concurrency based on actual resources.

Use the shell tool's background/session mechanism for long commands. If it
returns a process session ID, wait using that tool's supported continuation
mechanism. Do not assume Claude's `run_in_background` option exists. Report
meaningful progress without tight polling. The log ends with `EXIT <code>`;
the helper propagates that exit code and prints the last 25 log lines.

## Select the build command

- If `pubspec.yaml` contains a top-level `build_ntd:` entry and the CLI is
  installed, prefer `build_ntd apk` or `build_ntd bundle`. Always pass
  `--no-copy` to preserve the user's clipboard. Check `build_ntd apk --help`
  before relying on extra Flutter flags after `--`; fall back to plain
  `flutter build` when unsupported and explain why.
- Otherwise use plain Flutter or the project's requested build command.
- Run required localization/code generation through the same helper when
  the corresponding inputs changed. Do not run unrelated generators.
- Use the correct checkout and branch. Choose an absolute log path outside
  tracked source. Quote paths and arguments containing spaces.

## Deliver the result

For `build_ntd`, use its reported artifact name and leave its record file
subject to the project's commit policy. For plain Flutter, copy the output
to a location with a branch/feature-specific filename when collisions are
possible. Link the absolute artifact path in the final response using the
client's supported file presentation. Include the branch and verification
limits; do not assume Claude's `SendUserFile` tool exists.

On failure, inspect and report the log's error rather than retrying blindly.
