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

## Which command

- **build_ntd** when the project's `pubspec.yaml` has a top-level `build_ntd:`
  section and build_ntd is installed (`command -v build_ntd` or
  `command -v build_ntd.bat` — on Windows only the `.bat` exists, and `cmd`
  finds it). It runs `flutter build`, then copies the artifact under its
  templated name (`App941_short_drama_v1.0.0(1)_2026.10.17_14.30_dev_release.apk`)
  and adds a row with the commit and branch to `build_ntd_records.md`.
  - `build_ntd apk …` for an APK, `build_ntd bundle …` for an app bundle.
  - It takes `--flavor`, `--mode` (release by default), `-t`,
    `--dart-define`, `--output-dir`, `--output-name`. **Always pass
    `--no-copy`**: by default it puts the file on the clipboard, which
    would replace whatever the user has copied while they work.
  - **It takes no other flutter flags** (`--target-platform`,
    `--split-per-abi`, `--split-debug-info`, …). If the build needs one,
    use plain `flutter build` instead and say why in one line. A newer
    build_ntd may pass everything after `--` through to flutter: check
    `build_ntd apk --help` before assuming it can't.
- **Plain `flutter build`** otherwise.

## How to run it

Always use the Bash tool with `run_in_background: true` (a build takes minutes),
then wait for the completion notice; don't poll.

```bash
bash ~/.claude/skills/low-priority-build/lowprio-build.sh \
  -C <project dir> -l <scratchpad>/<name>.log -- \
  flutter build apk --flavor dev -t lib/main_dev.dart --target-platform android-arm,android-arm64
```

or, through build_ntd:

```bash
bash ~/.claude/skills/low-priority-build/lowprio-build.sh \
  -C <project dir> -l <scratchpad>/<name>.log -- \
  build_ntd apk --flavor dev -t lib/main_dev.dart --no-copy
```

- `-C` is the project (or worktree) folder. Build from the folder whose branch the user wants.
- `-l` is the log file. Put it in the session's scratchpad. The log ends with `EXIT <code>`, and the script exits with that code and prints the log's last 25 lines.
- Everything after `--` is the command. On Linux and macOS it runs as given. On Windows it goes through `cmd`: arguments with spaces are quoted for you, and an argument can't contain a double quote.
- If the project's translations or generated code changed since its last build, run `flutter gen-l10n` (and `dart run build_runner build --delete-conflicting-outputs` when DTOs, routes or freezed classes changed) through the script first.

## After the build

- **build_ntd:** its log names the renamed file (next to flutter's output, e.g. `build/app/outputs/flutter-apk/`, or in the project's `output_dir`). Send that file as it is with SendUserFile (`display: attach`), the branch in the caption — the name already carries version, date, time and flavor. Leave `build_ntd_records.md` alone: whether it's committed is the project's call.
- **Plain flutter:** find the output, e.g. `build/app/outputs/flutter-apk/app-<flavor>-release.apk`. Two builds of the same project from different folders give files with the same name, so copy each one to the scratchpad under a name that says what it is (e.g. `<app>-dev-<feature>.apk`), then send it with SendUserFile (`display: attach`).
- If the build failed, show the error from the log; don't retry blindly.

Project rules still apply: build only when the user asks for it in that message.
