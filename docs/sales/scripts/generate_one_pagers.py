import argparse
import json
import os
import shutil
import subprocess
import zipfile
from pathlib import Path


def load_template(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def slugify(text: str) -> str:
    return (
        text.lower()
        .replace(" ", "-")
        .replace(".", "")
        .replace("/", "-")
        .replace("--", "-")
    )


def ensure_key(data: dict, key: str, default: str = "") -> str:
    return data.get(key, default)


def fill_template(template: str, data: dict) -> str:
    context = {}
    context["actor_name"] = ensure_key(data, "actor_name")
    context["elevator_pitch"] = ensure_key(data, "elevator_pitch")
    context["sovereign_stack_description"] = ensure_key(data, "sovereign_stack_description")
    context["team_onboarding"] = ensure_key(data, "team_onboarding", "squad ATLANTYQA")
    context["pilot_idea"] = ensure_key(data, "pilot_idea", "piloto inicial")
    context["actor_anchor"] = ensure_key(data, "actor_anchor", slugify(data.get("actor_name", context["actor_name"])))

    deliverables = data.get("deliverables", [])
    for i in range(1, 4):
        context[f"deliverable_{i}"] = deliverables[i - 1] if i <= len(deliverables) else "En desarrollo"

    metrics = data.get("metrics", [])
    for i in range(1, 4):
        context[f"metric_{i}"] = metrics[i - 1] if i <= len(metrics) else "Pendiente"

    filled = template
    for key, value in context.items():
        filled = filled.replace(f"{{{{ {key} }}}}", value)
    return filled


def maybe_run_pandoc(md_path: Path, pdf_path: Path):
    if shutil.which("pandoc") is None:
        print("pandoc not found; skipping PDF generation.")
        return False
    cmd = ["pandoc", "-o", str(pdf_path), str(md_path)]
    subprocess.run(cmd, check=True)
    return True


def create_zip(bundle_path: Path, sources):
    with zipfile.ZipFile(bundle_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for src in sources:
            zf.write(src, arcname=src.name)
    print(f"Created zip bundle at {bundle_path}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate ATLANTYQA one-pagers from metadata."
    )
    parser.add_argument(
        "--dest",
        type=Path,
        default=Path("docs/sales/generated"),
        help="Destination directory for generated files.",
    )
    parser.add_argument(
        "--metadata",
        type=Path,
        default=Path("docs/sales/one-pagers/actors.json"),
        help="Metadata JSON file describing actors.",
    )
    parser.add_argument(
        "--template",
        type=Path,
        default=Path("docs/sales/templates/one-pager-template.md"),
        help="Template Markdown file.",
    )
    parser.add_argument(
        "--make-pdf",
        action="store_true",
        help="Generate PDF version using pandoc (if available).",
    )
    parser.add_argument(
        "--zip-bundle",
        action="store_true",
        help="Create a zip bundle of generated files.",
    )
    args = parser.parse_args()

    template_text = load_template(args.template)

    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    args.dest.mkdir(parents=True, exist_ok=True)

    generated_paths = []
    for entry in metadata:
        md_content = fill_template(template_text, entry)
        md_path = args.dest / f"{entry['id']}.md"
        md_path.write_text(md_content, encoding="utf-8")
        generated_paths.append(md_path)
        print(f"Generated {md_path}")

        if args.make_pdf:
            pdf_path = md_path.with_suffix(".pdf")
            try:
                if maybe_run_pandoc(md_path, pdf_path):
                    generated_paths.append(pdf_path)
            except subprocess.CalledProcessError as exc:
                print(f"pandoc failed for {md_path}: {exc}")

    if args.zip_bundle:
        bundle_path = args.dest / "one-pagers.zip"
        create_zip(bundle_path, generated_paths)


if __name__ == "__main__":
    main()
