---
name: low-priority-build
description: Run a heavy build (flutter build apk / appbundle, gradlew assemble…, any long compile) on Windows (Git Bash), Linux or macOS at low priority with limited Gradle workers, so the computer doesn't lag. Use whenever the user asks for a build (an APK, a bundle, "build me…"), and always when they mention lag, resources, or limiting the build. Several builds can run in parallel this way.
---

# Low-priority build

`lowprio-build.sh` (next to this file) runs a command so it doesn't slow the
computer down:

- **Lower priority**, set as the process is created, so every child (dart,
  Gradle, the Kotlin compiler, R8) inherits it: below-normal on Windows,
  `nice -n 10` on Linux and macOS, and on Linux also the lowest best-effort
  disk priority (`ionice -c2 -n7`, skipped where it isn't available). The
  user's own apps get the CPU first.
- **Gradle capped at 4 workers** (`-w` to change), one project at a time, and
  **no shared daemon**, so an earlier normal-priority daemon isn't reused.
- Memory is whatever the project's `android/gradle.properties` gives Gradle.

On a 12-core, 32 GB machine two builds in parallel are fine; on a smaller
one, build one at a time or pass `-w 2`.

## How to run it

Always use the Bash tool with `run_in_background: true` (a build takes minutes),
then wait for the completion notice; don't poll.

```bash
bash ~/.claude/skills/low-priority-build/lowprio-build.sh \
  -C <project dir> -l <scratchpad>/<name>.log -- \
  flutter build apk --flavor dev -t lib/main_dev.dart --target-platform android-arm,android-arm64
```

- `-C` is the project (or worktree) folder. Build from the folder whose branch the user wants.
- `-l` is the log file. Put it in the session's scratchpad. The log ends with `EXIT <code>`, and the script exits with that code and prints the log's last 25 lines.
- Everything after `--` is the command. On Linux and macOS it runs as given. On Windows it goes through `cmd`: arguments with spaces are quoted for you, and an argument can't contain a double quote.
- If the project's translations or generated code changed since its last build, run `flutter gen-l10n` (and `dart run build_runner build --delete-conflicting-outputs` when DTOs, routes or freezed classes changed) through the script first.

## After the build

- Find the output, e.g. `build/app/outputs/flutter-apk/app-<flavor>-release.apk`.
- Two builds of the same project from different folders give files with the same name. Copy each one to the scratchpad under a name that says what it is (e.g. `<app>-dev-<feature>.apk`), then send it with SendUserFile (`display: attach`).
- If the build failed, show the error from the log; don't retry blindly.

Project rules still apply: build only when the user asks for it in that message.
