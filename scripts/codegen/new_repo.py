#!/usr/bin/env python3
"""Create a new repository in the PlaylisterData package following DATA.md.

Usage:
    python3 scripts/codegen/new_repo.py --name Users

Creates Sources/PlaylisterData/Repositories/<Name>/ with the public repository class and API protocol,
the public request/response protocols and the internal DAOs. The configuration is left empty
(baseURL "" and serviceNames []). Then it registers the repository in DATA.md.
"""
from __future__ import annotations

import argparse
import re

from common import (ROOT, TEMPLATES, CodegenError, append_in_section, load_config, main_wrapper, pascal_case,
                    render, write_new)

FILES = [
    ("Repository.swift.tmpl", "{R}Repository.swift"),
    ("RequestProtocol.swift.tmpl", "{R}RequestProtocol.swift"),
    ("ResponseProtocol.swift.tmpl", "{R}ResponseProtocol.swift"),
    ("DAO/RequestDAO.swift.tmpl", "DAO/{R}RequestDAO.swift"),
    ("DAO/ResponseDAO.swift.tmpl", "DAO/{R}ResponseDAO.swift"),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--name", required=True, help="Repository name, e.g. Users (a trailing 'Repository' is removed)")
    args = parser.parse_args()

    config = load_config()
    name = pascal_case(re.sub(r"\s*[Rr]epository$", "", args.name.strip()))
    sources = ROOT / config["dataSources"]
    repo_dir = sources / "Repositories" / name
    if repo_dir.exists():
        raise CodegenError(f"Repository '{name}' already exists.")

    created = []
    for template_name, destination in FILES:
        path = repo_dir / destination.format(R=name)
        write_new(path, render(TEMPLATES / "repo" / template_name, {"Repo": name}))
        created.append(str(path.relative_to(ROOT)))

    data_md = sources.parent.parent / "DATA.md"
    folder = repo_dir.relative_to(sources.parent.parent)
    append_in_section(data_md, "repository-registry",
                      f"| `{name}` | `{name}RepositoryProtocol` | `{folder}` |")

    print(f"Repository {name} created.")
    print("Files:\n  " + "\n  ".join(created))
    print(f"Next: fill in baseURL and serviceNames in {name}Repository.configuration, and the fields of "
          f"{name}RequestProtocol / {name}ResponseProtocol and their DAOs.")
    print(f"Updated: {data_md.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    main_wrapper(main)
