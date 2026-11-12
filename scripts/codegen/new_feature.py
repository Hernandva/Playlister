#!/usr/bin/env python3
"""Create a new feature (scene) following FEATURES.md.

Usage:
    python3 scripts/codegen/new_feature.py --name Profile --parent Home [--repository Users]

What it does:
  1. Creates and checks out `feature/<Project>-<Feature>` from `develop` (skip with --no-branch).
  2. Creates Features/<Feature>/ with Coordinator, Dependencies, View, ViewModel, ViewData and UseCase.
  3. Adds a route to the new feature in the parent feature's coordinator.
  4. Updates the feature registry and the app map in FEATURES.md, and adds `<feature>.title` to Localizable.xcstrings.
  5. Regenerates the Xcode project with xcodegen when it is installed (skip with --no-xcodegen).
"""
from __future__ import annotations

import argparse
import json
import re

from common import (ROOT, TEMPLATES, CodegenError, append_in_section, insert_before_marker, load_config,
                    lower_camel, main_wrapper, pascal_case, regenerate_xcode_project, render, run, write_new)

# (template file, destination relative to the feature folder)
FILES = [
    ("Coordinator.swift.tmpl", "{F}Coordinator.swift"),
    ("Dependencies.swift.tmpl", "{F}Dependencies.swift"),
    ("View.swift.tmpl", "View/{F}View.swift"),
    ("ViewModel.swift.tmpl", "ViewModel/{F}ViewModel.swift"),
    ("ViewData.swift.tmpl", "Model/{F}ViewData.swift"),
    ("UseCase.swift.tmpl", "UseCase/{F}UseCase.swift"),
]
WITH_REPOSITORY = {"Dependencies.swift.tmpl", "UseCase.swift.tmpl"}


def create_branch(project: str, feature: str) -> str:
    if run(["git", "rev-parse", "--is-inside-work-tree"], check=False).returncode != 0:
        raise CodegenError("This folder is not a git repository. Use --no-branch to skip the branch.")
    if run(["git", "status", "--porcelain"]).stdout.strip():
        raise CodegenError("There are uncommitted changes. Commit or stash them before creating a feature.")
    if run(["git", "rev-parse", "--verify", "--quiet", "develop"], check=False).returncode != 0:
        raise CodegenError("Branch 'develop' does not exist. Create it from main first: git branch develop main")
    branch = f"feature/{project}-{feature}"
    if run(["git", "rev-parse", "--verify", "--quiet", branch], check=False).returncode == 0:
        raise CodegenError(f"Branch '{branch}' already exists.")
    run(["git", "checkout", "develop"])
    if run(["git", "remote", "get-url", "origin"], check=False).returncode == 0:
        pull = run(["git", "pull", "--ff-only", "origin", "develop"], check=False)
        if pull.returncode != 0:
            print("WARNING: could not update develop from origin; branching from the local develop.")
    run(["git", "checkout", "-b", branch])
    return branch


def add_localized_title(catalog_path, key: str, value: str) -> None:
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    language = catalog.get("sourceLanguage", "en")
    catalog.setdefault("strings", {}).setdefault(key, {
        "extractionState": "manual",
        "localizations": {language: {"stringUnit": {"state": "translated", "value": value}}},
    })
    catalog_path.write_text(
        json.dumps(catalog, indent=2, sort_keys=True, ensure_ascii=False, separators=(",", " : ")) + "\n",
        encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--name", required=True, help="Feature name, e.g. Profile or 'user settings'")
    parser.add_argument("--parent", help="Existing feature that opens the new one")
    parser.add_argument("--repository", help="PlaylisterData repository the use case consumes (optional)")
    parser.add_argument("--root", action="store_true", help="Create the root feature (no parent, no branch)")
    parser.add_argument("--no-branch", action="store_true", help="Do not create a git branch")
    parser.add_argument("--no-xcodegen", action="store_true", help="Do not regenerate the Xcode project")
    args = parser.parse_args()

    config = load_config()
    project = config["name"]
    app_dir = ROOT / config["appDirectory"]
    features_dir = app_dir / "Features"
    feature = pascal_case(args.name)
    feature_dir = features_dir / feature
    if feature_dir.exists():
        raise CodegenError(f"Feature '{feature}' already exists.")

    parent = None
    if not args.root:
        if not args.parent:
            existing = sorted(p.name for p in features_dir.iterdir() if p.is_dir())
            raise CodegenError(f"--parent is required. Existing features: {', '.join(existing) or 'none'}")
        parent = pascal_case(args.parent)
        parent_coordinator = features_dir / parent / f"{parent}Coordinator.swift"
        if not parent_coordinator.exists():
            existing = sorted(p.name for p in features_dir.iterdir() if p.is_dir())
            raise CodegenError(f"Feature '{parent}' does not exist. Existing features: {', '.join(existing)}")

    repository = None
    if args.repository:
        repository = pascal_case(re.sub(r"Repository$", "", args.repository))
        repo_dir = ROOT / config["dataSources"] / "Repositories" / repository
        if not repo_dir.exists():
            raise CodegenError(f"Repository '{repository}' does not exist in PlaylisterData. Create it first with new_repo.py.")

    branch = None
    if not args.root and not args.no_branch:
        branch = create_branch(project, feature)

    key = lower_camel(feature)
    values = {"Feature": feature, "key": key}
    if repository:
        values["Repo"] = repository
    created = []
    for template_name, destination in FILES:
        source = TEMPLATES / "feature" / template_name
        if repository and template_name in WITH_REPOSITORY:
            source = source.with_name(template_name.replace(".swift.tmpl", ".repository.swift.tmpl"))
        path = feature_dir / destination.format(F=feature)
        write_new(path, render(source, values))
        created.append(str(path.relative_to(ROOT)))

    if parent:
        insert_before_marker(parent_coordinator, "// @codegen:routes", f"case {key}")
        insert_before_marker(parent_coordinator, "// @codegen:destinations",
                             f"case .{key}:\n    return AnyView({feature}Coordinator().start())")

    features_md = app_dir / "FEATURES.md"
    opened_from = parent or "— (root)"
    repo_cell = f"`{repository}Repository`" if repository else "—"
    append_in_section(features_md, "feature-registry", f"| `{feature}` | {opened_from} | {repo_cell} |")
    edge = f"    {parent} --> {feature}" if parent else f"    {feature}"
    append_in_section(features_md, "app-map", edge, before_closing_fence=True)

    title = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", feature)
    add_localized_title(app_dir / "Resources" / "Localizable.xcstrings", f"{key}.title", title)

    print(f"Feature {feature} created.")
    if branch:
        print(f"Branch: {branch}")
    print("Files:\n  " + "\n  ".join(created))
    if parent:
        print(f"Route added: {parent}Coordinator.Route.{key} -> {feature}Coordinator")
        print(f"Open it from {parent}View with: NavigationLink(value: {parent}Coordinator.Route.{key}) {{ ... }}")
    print(f"Updated: {features_md.relative_to(ROOT)}, Localizable.xcstrings ({key}.title)")
    if not args.no_xcodegen:
        print(regenerate_xcode_project())
    return 0


if __name__ == "__main__":
    main_wrapper(main)
