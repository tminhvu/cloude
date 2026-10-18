#!/usr/bin/env python3
"""Install the Codex workflow, preserving existing instructions and backups."""

import argparse
import datetime
import os
from pathlib import Path
import shutil
import tempfile


def install(home, codex_home):
    source = Path(__file__).resolve().parent
    instructions = codex_home / "AGENTS.md"
    skill = home / ".agents/skills/low-priority-build"
    if (codex_home / "AGENTS.override.md").exists():
        raise SystemExit("AGENTS.override.md exists; reconcile it before installing.")
    targets = [instructions, skill / "SKILL.md", skill / "lowprio-build.sh"]
    if any(path.is_symlink() for path in targets) or skill.is_symlink():
        raise SystemExit("Installation targets contain symlinks; review them first.")
    template = (source / "AGENTS.md").read_text()
    old = instructions.read_text() if instructions.exists() else ""
    start = "<!-- cloude-codex:start -->"
    end = "<!-- cloude-codex:end -->"
    if old.count(start) != old.count(end) or old.count(start) > 1:
        raise SystemExit("Invalid managed instruction markers; reconcile manually.")
    block = f"{start}\n{template.rstrip()}\n{end}"
    if start in old:
        before, remainder = old.split(start, 1)
        _, after = remainder.split(end, 1)
        merged = before + block + after
    else:
        merged = (old.rstrip() + "\n\n" if old else "") + block + "\n"
    codex_home.mkdir(parents=True, exist_ok=True)
    backup = Path(tempfile.mkdtemp(
        prefix=datetime.datetime.now().strftime("%Y%m%d-%H%M%S-"),
        dir=str(codex_home),
    ))
    for index, path in enumerate(targets):
        if path.exists():
            shutil.copy2(path, backup / f"{index}-{path.name}")
    (backup / "restore.txt").write_text("\n".join(
        f"{index}-{path.name} -> {path} (remove target if no backup exists)"
        for index, path in enumerate(targets)
    ) + "\n")
    skill.mkdir(parents=True, exist_ok=True)
    instructions.write_text(merged)
    shutil.copy2(source / "skills/low-priority-build/SKILL.md", targets[1])
    shutil.copy2(source.parent / "skills/low-priority-build/lowprio-build.sh", targets[2])
    targets[2].chmod(targets[2].stat().st_mode | 0o111)
    print(f"Installed instructions: {instructions}")
    print(f"Installed skill: {skill}")
    print(f"Backups and rollback mapping: {backup}")
    print("Existing config.toml and hooks were preserved. Start a fresh Codex chat.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument("--codex-home", type=Path)
    args = parser.parse_args()
    install(args.home, args.codex_home or Path(os.environ.get(
        "CODEX_HOME", str(args.home / ".codex"))))
