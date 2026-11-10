"""Shared helpers for the code generators. Python 3.9+, standard library only."""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

CODEGEN_DIR = Path(__file__).resolve().parent
ROOT = CODEGEN_DIR.parent.parent
TEMPLATES = CODEGEN_DIR / "templates"
IDENTIFIER = re.compile(r"^[A-Z][A-Za-z0-9]*$")


class CodegenError(Exception):
    """A problem the user must fix; printed without a traceback."""


def load_config() -> dict:
    """Project settings written by the new-project skill (name, app folder, packages)."""
    return json.loads((CODEGEN_DIR / "project.json").read_text(encoding="utf-8"))


def pascal_case(raw: str) -> str:
    parts = [p for p in re.split(r"[^A-Za-z0-9]+", raw.strip()) if p]
    name = "".join(p[0].upper() + p[1:] for p in parts)
    if not IDENTIFIER.match(name):
        raise CodegenError(f"'{raw}' is not a valid type name. Use letters and digits, starting with a letter.")
    return name


def lower_camel(name: str) -> str:
    """Profile -> profile, UserSettings -> userSettings, URLLoader -> urlLoader, API -> api."""
    prefix = re.match(r"^[A-Z]+(?=[A-Z][a-z]|[0-9]|$)", name)
    head = prefix.group(0) if prefix else name[0]
    return head.lower() + name[len(head):]


def render(template: Path, values: dict[str, str]) -> str:
    text = template.read_text(encoding="utf-8")
    for key, value in values.items():
        text = text.replace("{{" + key + "}}", value)
    leftover = re.findall(r"\{\{\w+\}\}", text)
    if leftover:
        raise CodegenError(f"Unresolved placeholders {leftover} in {template.name}")
    return text


def write_new(path: Path, content: str) -> None:
    if path.exists():
        raise CodegenError(f"{path.relative_to(ROOT)} already exists.")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def insert_before_marker(path: Path, marker: str, block: str) -> None:
    """Insert `block` right before the line that holds `marker`, with the marker's indentation."""
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    for index, line in enumerate(lines):
        if marker in line:
            indent = line[: len(line) - len(line.lstrip())]
            new = "".join(f"{indent}{row}\n" if row else "\n" for row in block.split("\n"))
            lines.insert(index, new)
            path.write_text("".join(lines), encoding="utf-8")
            return
    raise CodegenError(f"Marker '{marker}' not found in {path.relative_to(ROOT)}. Restore it and try again.")


def append_in_section(path: Path, section: str, row: str, before_closing_fence: bool = False) -> None:
    """Append a line at the end of a `<!-- codegen:<section>:start/end -->` block of a Markdown file."""
    text = path.read_text(encoding="utf-8")
    start = f"<!-- codegen:{section}:start -->"
    end = f"<!-- codegen:{section}:end -->"
    if start not in text or end not in text:
        raise CodegenError(f"Markers for '{section}' not found in {path.relative_to(ROOT)}.")
    head, rest = text.split(start, 1)
    body, tail = rest.split(end, 1)
    body = body.rstrip("\n")
    if before_closing_fence and body.endswith("```"):
        body = body[:-3].rstrip("\n") + "\n" + row + "\n```"
    else:
        body = body + "\n" + row
    path.write_text(head + start + body + "\n" + end + tail, encoding="utf-8")


def section_rows(path: Path, section: str) -> list[str]:
    text = path.read_text(encoding="utf-8")
    start = f"<!-- codegen:{section}:start -->"
    end = f"<!-- codegen:{section}:end -->"
    if start not in text:
        return []
    return text.split(start, 1)[1].split(end, 1)[0].strip().splitlines()


def run(args: list[str], check: bool = True, cwd: Path = ROOT) -> subprocess.CompletedProcess:
    result = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise CodegenError(f"`{' '.join(args)}` failed:\n{result.stderr.strip() or result.stdout.strip()}")
    return result


def regenerate_xcode_project() -> str:
    if shutil.which("xcodegen") is None:
        return "xcodegen is not installed: run `brew install xcodegen` and then `xcodegen generate`."
    result = run(["xcodegen", "generate", "--quiet"], check=False)
    if result.returncode != 0:
        return "xcodegen generate failed: " + (result.stderr.strip() or result.stdout.strip())
    return "Xcode project regenerated with xcodegen."


def main_wrapper(main) -> None:
    try:
        sys.exit(main())
    except CodegenError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
