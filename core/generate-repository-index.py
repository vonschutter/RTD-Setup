#!/usr/bin/env python3
"""Generate a compact, searchable index for the RTD-Setup repository."""

from __future__ import annotations

import os
import re
import subprocess
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "REPOSITORY_INDEX.md"
OUTPUT_REL = OUTPUT.relative_to(ROOT).as_posix()

CORE_PURPOSES = {
    "core/_rtd_library": "Shared Bash API: platform, package, desktop, security, media, and VM functions.",
    "core/_rtd_recipies.info": "Software bundle recipes consumed by the bundle managers.",
    "core/_locations.info": "Tool registration and launcher metadata.",
    "core/_branding.info": "Shared product names, paths, URLs, and presentation defaults.",
    "core/rtd-oem-enable-config.sh": "Register and configure RTD during automated Linux installs.",
    "core/rtd-oem-linux-config.sh": "Linux OEM workstation/server/VM configuration entry point.",
    "core/rtd-vm-template-finalize-linux.sh": "Install default bundles and reseal Linux VM templates.",
    "core/rtd-bootstrap-progress-gtk.py": "GTK progress UI for bootstrap and template finalization.",
    "core/rtd-oem-macos-config.sh": "macOS OEM configuration entry point.",
    "core/rtd-oem-windows-setup.ps1": "Windows OEM setup and KVM guest integration.",
    "core/rtd-oem-windows-setup-splash.ps1": "Windows setup progress/splash UI.",
}

MODULE_PURPOSES = {
    "Security-tool.mod": "Interactive security auditing and hardening actions.",
    "gnome-shell-extension-installer.mod": "Search for and install GNOME Shell extensions.",
    "light-weight-office-games.mod": "Install a curated group of lightweight desktop games.",
    "macos-kvm.mod": "Prepare and define macOS recovery VMs on QEMU/KVM.",
    "minecraft-server-manager.mod": "Launch and monitor a dedicated Minecraft server.",
    "nordvpn-manager.mod": "Dialog wrapper for common NordVPN CLI operations.",
    "oem-app-runner.mod": "Verify, unpack, and run packaged OEM support tools.",
    "oem-bundle-manager.mod": "Install or remove role-oriented software bundles.",
    "oem-system-admin.mod": "Small system-administration and support commands.",
    "oem-system-update.mod": "Update the OS and update/reinitialize RTD itself.",
    "oem-ventoy.mod": "Build and maintain branded multi-ISO Ventoy media.",
    "rtd-ai-chat.mod": "Launch local Ollama chat with an OpenAI-client fallback.",
    "rtd-check-sec.mod": "Inspect exploit-mitigation properties of Linux binaries and processes.",
    "rtd-desktop-look-switcher.mod": "Compatibility launcher for integrated desktop profiles.",
    "rtd-oem-tweaks.mod": "GTK frontend for reusable GNOME/OEM tweaks.",
    "rtd-vpn-router.mod": "Configure a fail-closed Linux VPN router.",
    "setup-whonix.mod": "Discover, verify, and define Whonix KVM guests.",
    "simple-support-tool.mod": "Terminal menu for common local and remote support tasks.",
    "steam-world-of-tanks-utility.mod": "Manage World of Tanks replays and GE-Proton.",
    "steam-world-of-warships-utility.mod": "Manage World of Warships replays and GE-Proton.",
    "system-hardware-information.mod": "Display hardware and sensor information in a YAD dashboard.",
    "system-user-backup.mod": "Create encrypted migration backups through GTK or CLI.",
    "theme-manager": "Apply GNOME themes, appearance elements, wallpapers, and desktop profiles.",
    "vm-tool.mod": "Create and manage libvirt/KVM VMs through TUI and GTK frontends.",
    "windows.mod": "Payloads injected into unattended Windows VM installations.",
}

BASH_FUNCTION = re.compile(
    r"^\s*(?:function\s+([A-Za-z_][\w:.-]*)\s*(?:\(\s*\))?|"
    r"([A-Za-z_][\w:.-]*)\s*\(\s*\))\s*\{",
    re.MULTILINE,
)
PYTHON_SYMBOL = re.compile(r"^(?:async\s+)?(?:def|class)\s+([A-Za-z_]\w*)", re.MULTILINE)
POWERSHELL_SYMBOL = re.compile(
    r"^\s*(?:function|filter)\s+([A-Za-z_][\w-]*)", re.IGNORECASE | re.MULTILINE
)


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def repository_paths() -> list[str]:
    tracked = git("ls-files").splitlines()
    extras = git("ls-files", "--others", "--exclude-standard").splitlines()
    return sorted(
        {
            path
            for path in tracked + extras
            if path
            and path != OUTPUT_REL
            and "__pycache__" not in Path(path).parts
            and not path.endswith((".pyc", ".pyo"))
        }
    )


def is_text(path: Path) -> bool:
    try:
        return b"\0" not in path.read_bytes()[:8192]
    except OSError:
        return False


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def kind_for(relative: str, text: str) -> str:
    suffix = Path(relative).suffix.lower()
    if suffix in {".md", ".txt"}:
        return "documentation"
    if suffix in {".png", ".jpg", ".jpeg", ".svg", ".ico"}:
        return "image"
    if suffix in {".zip", ".7z"}:
        return "archive"
    if suffix == ".sig":
        return "signature"
    if suffix == ".py" or text.startswith("#!/usr/bin/env python"):
        return "python"
    if suffix == ".ps1":
        return "powershell"
    if suffix in {".sh", ".info", ".cmd"} or "bash" in text[:160] or "sh" in text[:80]:
        return "shell"
    if relative in {"LICENSE", ".gitignore"}:
        return "metadata"
    return suffix.removeprefix(".") or "file"


def declarations_for(kind: str, text: str) -> list[tuple[str, int]]:
    pattern: re.Pattern[str] | None = None
    if kind == "shell":
        declarations = []
        for match in BASH_FUNCTION.finditer(text):
            declarations.append(
                (match.group(1) or match.group(2), text.count("\n", 0, match.start()) + 1)
            )
        return declarations
    if kind == "python":
        pattern = PYTHON_SYMBOL
    elif kind == "powershell":
        pattern = POWERSHELL_SYMBOL
    if pattern:
        return [
            (match.group(1), text.count("\n", 0, match.start()) + 1)
            for match in pattern.finditer(text)
        ]
    return []


def entrypoints_for(module: str, records: dict[str, dict[str, object]]) -> list[str]:
    prefix = f"modules/{module}/"
    entrypoints = []
    for relative, record in records.items():
        if not relative.startswith(prefix) or "/" in relative[len(prefix) :]:
            continue
        name = Path(relative).name
        if name.startswith("rtd-") or name.endswith(("-gtk.py", "-gtk")):
            entrypoints.append(name)
        elif record["kind"] in {"python", "shell"} and name not in {"chatgpt.sh"}:
            entrypoints.append(name)
    return sorted(set(entrypoints))


def markdown_escape(value: str) -> str:
    return value.replace("|", "\\|")


def main() -> None:
    paths = repository_paths()
    records: dict[str, dict[str, object]] = {}
    kind_counts: Counter[str] = Counter()
    directory_counts: Counter[str] = Counter()

    for relative in paths:
        path = ROOT / relative
        text = read_text(path) if path.is_file() and is_text(path) else ""
        kind = kind_for(relative, text)
        declarations = declarations_for(kind, text)
        try:
            size = path.stat().st_size
        except OSError:
            size = 0
        lines = text.count("\n") + (1 if text and not text.endswith("\n") else 0)
        records[relative] = {
            "kind": kind,
            "size": size,
            "lines": lines,
            "declarations": declarations,
        }
        kind_counts[kind] += 1
        directory_counts[relative.split("/", 1)[0]] += 1

    commit = git("rev-parse", "--short", "HEAD")
    dirty = bool(git("status", "--porcelain"))
    total_symbols = sum(len(record["declarations"]) for record in records.values())

    out: list[str] = [
        "# RTD-Setup Repository Index",
        "",
        "This generated catalog is the routing layer for repository work. Search it first, then open only the listed source files and symbols needed for the task.",
        "",
        f"Snapshot: commit `{commit}`{' with working-tree changes' if dirty else ''}; "
        f"{len(paths)} indexed paths; {total_symbols} extracted code symbols. "
        f"`{OUTPUT_REL}` excludes itself from counts.",
        "",
        "Regenerate after structural or symbol changes:",
        "",
        "```bash",
        "python3 core/generate-repository-index.py",
        "```",
        "",
        "Fast, low-context lookups:",
        "",
        "```bash",
        "# Locate declarations without opening source files",
        "rg -n -F '`symbol_name` —' docs/REPOSITORY_INDEX.md",
        "# Find a module or tracked path",
        "rg -n -F 'path_fragment' docs/REPOSITORY_INDEX.md",
        "```",
        "",
        "## Reuse Before Adding Code",
        "",
        "1. Search the Symbol Index for an existing function before adding a helper.",
        "2. Put cross-module Bash behavior in `core/_rtd_library`; keep UI and command orchestration in modules.",
        "3. Put install/remove bundles in `core/_rtd_recipies.info` and command registration in `core/_locations.info`.",
        "4. Reuse `_branding.info`, shared media, and existing GTK/TUI launch patterns instead of copying constants or assets.",
        "5. Check sibling modules and their README before introducing another frontend or dependency wrapper.",
        "",
        "## Repository Shape",
        "",
        "| Area | Paths | Role |",
        "| --- | ---: | --- |",
    ]
    area_roles = {
        ".gitignore": "Git ignore policy.",
        "LICENSE": "Repository license text.",
        "LICENSE.md": "License documentation.",
        "README.md": "Primary user documentation and task routing.",
        "core": "Shared implementation, OEM flows, metadata, signatures, and core media.",
        "docs": "Getting-started, tool-reference, use-case, and generated repository documentation.",
        "media_files": "Repository-wide screenshots and branding assets.",
        "modules": "User-facing tools, compatibility commands, and module-local assets/docs.",
        "rtd-me.sh.cmd": "Cross-platform bootstrap/installation entry point.",
        "wallpaper": "Shared light/dark wallpaper assets.",
    }
    for area, count in sorted(directory_counts.items()):
        out.append(f"| `{area}` | {count} | {area_roles.get(area, '')} |")

    out.extend([
        "",
        "### File kinds",
        "",
        ", ".join(f"{kind}: {count}" for kind, count in sorted(kind_counts.items())),
        "",
        "## Core Sources",
        "",
        "| Source | Lines | Symbols | Purpose |",
        "| --- | ---: | ---: | --- |",
    ])
    for relative, purpose in CORE_PURPOSES.items():
        record = records.get(relative)
        if record:
            out.append(
                f"| [`{relative}`](../{relative}) | {record['lines']} | "
                f"{len(record['declarations'])} | {purpose} |"
            )

    out.extend([
        "",
        "## Module Map",
        "",
        "| Module | Entry points | Purpose |",
        "| --- | --- | --- |",
    ])
    modules = sorted(
        path.name for path in (ROOT / "modules").iterdir() if path.is_dir()
    )
    for module in modules:
        entrypoints = entrypoints_for(module, records)
        rendered = ", ".join(f"`{name}`" for name in entrypoints) or "—"
        readme = f"modules/{module}/README.md"
        label = f"[{module}](../{readme})" if readme in records else f"`{module}`"
        out.append(
            f"| {label} | {rendered} | {markdown_escape(MODULE_PURPOSES.get(module, 'Module-local tool and assets.'))} |"
        )

    out.extend([
        "",
        "## Symbol Index",
        "",
        "Format: `symbol` — `path:line`. Symbols are grouped by source so searches return a small, relevant slice.",
        "",
    ])
    for relative, record in records.items():
        declarations = record["declarations"]
        if not declarations:
            continue
        out.append(f"### `{relative}`")
        out.append("")
        for symbol, line_number in declarations:
            out.append(f"- `{symbol}` — `{relative}:{line_number}`")
        out.append("")

    out.extend([
        "## Complete Path Catalog",
        "",
        "Format: `path` — kind, lines for text files, bytes. This covers every tracked or unignored repository path except this generated index itself.",
        "",
    ])
    grouped: dict[str, list[str]] = defaultdict(list)
    for relative in paths:
        grouped[relative.split("/", 1)[0]].append(relative)
    for area in sorted(grouped):
        out.append(f"### `{area}`")
        out.append("")
        for relative in grouped[area]:
            record = records[relative]
            line_info = f", {record['lines']} lines" if record["lines"] else ""
            out.append(f"- `{relative}` — {record['kind']}{line_info}, {record['size']} bytes")
        out.append("")

    OUTPUT.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT_REL}: {len(paths)} paths, {total_symbols} symbols")


if __name__ == "__main__":
    main()
