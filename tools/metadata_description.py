from __future__ import annotations

import re
import sys
from html import escape
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))
from mod_footer import render_footer
from mod_metadata import ModText, with_translations

LINK_PATTERN: re.Pattern[str] = re.compile(
    r"\[url=(https://[^\]\s]+)\]([^\[]+)\[/url\]|https://[^\s]+"
)


def render_inline(text: str) -> str:
    parts: list[str] = []
    start = 0
    for match in LINK_PATTERN.finditer(text):
        parts.append(escape(text[start : match.start()]))
        url = match.group(1) or match.group(0)
        label = match.group(2) or url
        parts.append(f'<a href="{escape(url)}">{escape(label)}</a>')
        start = match.end()
    parts.append(escape(text[start:]))
    return "".join(parts)


def render_description(texts: dict[str, ModText], source_url: str) -> str:
    sections = [
        f'<h1>{escape(texts["en"]["name"])}</h1>',
    ]
    for paragraph in texts["en"]["description"].split("\n\n"):
        sections.append(f"<p>{render_inline(paragraph)}</p>")
    body = with_translations("\n\n".join(sections), texts)
    return body.rstrip() + "\n\n" + render_footer(source_url)


def main() -> None:
    from validate_resources import (
        load_json_object,
        require_nonempty_string,
        validate_metadata_localisations,
    )

    mod_root = Path(__file__).resolve().parents[1]
    metadata_root = mod_root / "_metadata"
    metadata = load_json_object(metadata_root / "modinfo.json")
    supported_locales = set(load_json_object(mod_root / "strings.json"))
    texts = validate_metadata_localisations(metadata, supported_locales)
    source_url = require_nonempty_string(metadata.get("url_repo"), "modinfo.url_repo")
    (metadata_root / "description.html").write_text(
        render_description(texts, source_url), encoding="utf-8"
    )
    print("Updated _metadata/description.html from modinfo.json")


if __name__ == "__main__":
    main()
