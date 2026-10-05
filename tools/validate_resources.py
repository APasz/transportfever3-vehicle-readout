from __future__ import annotations

import json
import re
import sys
import zipfile
from collections import Counter
from pathlib import Path, PurePosixPath
from typing import Literal, TypedDict, cast

LOCALISATION_PATTERN: re.Pattern[str] = re.compile(r'_\("([A-Z][A-Z0-9_]+)"\)')
PARAMETER_PATTERN: re.Pattern[str] = re.compile(r'"([a-z][a-z0-9_]+)"')
PARAMETER_KEY_PATTERN: re.Pattern[str] = re.compile(
    r'local ([A-Z][A-Z0-9_]*_PARAM_KEY) = "([a-z][a-z0-9_]+)"'
)
DEFAULT_PARAM_INDEX_PATTERN: re.Pattern[str] = re.compile(
    r"\[([A-Z][A-Z0-9_]*_PARAM_KEY)\] = ([1-9][0-9]*),"
)
REACT_PLUGIN_TYPE_PATTERN: re.Pattern[str] = re.compile(
    r'type = "react-plugin ::([A-Za-z][A-Za-z0-9_]*)"'
)
PLUGIN_FILE_PATH_PATTERN: re.Pattern[str] = re.compile(
    r'filePath = "([^"@]+)@([A-Za-z][A-Za-z0-9_]*)"'
)
PLUGIN_REGISTRATION_PATTERN: re.Pattern[str] = re.compile(
    r"local ([A-Za-z][A-Za-z0-9_]*) = react\.RegisterPluginRecipe\(\s*"
    + r"game_bar_widgets\.([A-Za-z][A-Za-z0-9_]*)"
)
PLUGIN_ORDER_PATTERN: re.Pattern[str] = re.compile(
    r"local GAME_BAR_ORDER = ([1-9][0-9]*)"
)
IDENTITY_EXPORT_PATTERN: re.Pattern[str] = re.compile(
    r"^\s*([A-Za-z][A-Za-z0-9_]*) = \1,$", re.MULTILINE
)
MOD_ID_PATTERN: re.Pattern[str] = re.compile(r'local MOD_ID = "([a-z0-9_]+)"')
PROJECT_RESOURCE_PATTERN: re.Pattern[str] = re.compile(
    r'"([a-z0-9_]+)::/vehicle_readout/'
)
GUI_TEXTURE_PATTERN: re.Pattern[str] = re.compile(r'"(::/gui/[^"\n]+\.tga)"')
PLACEHOLDER_PATTERN: re.Pattern[str] = re.compile(r"\{([a-z][a-z0-9_]*)\}")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
GAME_BAR_EXTENSION_POINT = "GameBarInfoDisplayExtension"

ParameterUiType = Literal["CheckBox", "ComboBox"]


class ModParameter(TypedDict):
    default_index: int
    key: str
    name: str
    tooltip: str
    ui_type: ParameterUiType
    values: list[str]


def load_json_object(path: Path) -> dict[str, object]:
    with path.open(encoding="utf-8") as file:
        value = cast(object, json.load(file))
    if not isinstance(value, dict):
        raise TypeError(f"Expected a JSON object in {path}")
    return cast(dict[str, object], value)


def require_string(value: object, label: str) -> str:
    if not isinstance(value, str):
        raise TypeError(f"Expected {label} to be a string")
    return value


def require_nonempty_string(value: object, label: str) -> str:
    result = require_string(value, label)
    if not result.strip():
        raise ValueError(f"Expected {label} to be non-empty")
    return result


def require_integer(value: object, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError(f"Expected {label} to be an integer")
    return value


def require_ui_type(value: object, label: str) -> ParameterUiType:
    if value not in ("CheckBox", "ComboBox"):
        raise ValueError(f"Expected {label} to be CheckBox or ComboBox")
    return value


def require_string_list(value: object, label: str) -> list[str]:
    if not isinstance(value, list):
        raise TypeError(f"Expected {label} to be a list of strings")

    result: list[str] = []
    for item in cast(list[object], value):
        if not isinstance(item, str):
            raise TypeError(f"Expected {label} to be a list of strings")
        result.append(item)
    return result


def parse_parameters(value: object) -> list[ModParameter]:
    if not isinstance(value, list):
        raise TypeError("Expected params to be a list")

    result: list[ModParameter] = []
    for index, raw_parameter in enumerate(cast(list[object], value)):
        if not isinstance(raw_parameter, dict):
            raise TypeError(f"Expected params[{index}] to be an object")
        parameter = cast(dict[str, object], raw_parameter)
        label = f"params[{index}]"
        values = require_string_list(parameter.get("values"), f"{label}.values")
        default_index = require_integer(
            parameter.get("defaultIndex"), f"{label}.defaultIndex"
        )
        ui_type = require_ui_type(parameter.get("uiType"), f"{label}.uiType")
        if not values:
            raise ValueError(f"Expected {label}.values to be non-empty")
        if any(not value.strip() for value in values):
            raise ValueError(f"Expected {label}.values not to contain empty strings")
        require_unique(values, f"{label}.values")
        if not 0 <= default_index < len(values):
            raise ValueError(
                f"{label}.defaultIndex {default_index} is outside the zero-based values range"
            )
        if ui_type == "CheckBox" and len(values) != 2:
            raise ValueError(
                f"Expected {label}.values to contain exactly two CheckBox choices"
            )
        if ui_type == "ComboBox" and len(values) < 2:
            raise ValueError(
                f"Expected {label}.values to contain at least two ComboBox choices"
            )
        result.append(
            {
                "default_index": default_index,
                "key": require_nonempty_string(parameter.get("key"), f"{label}.key"),
                "name": require_nonempty_string(parameter.get("name"), f"{label}.name"),
                "tooltip": require_nonempty_string(
                    parameter.get("tooltip"), f"{label}.tooltip"
                ),
                "ui_type": ui_type,
                "values": values,
            }
        )
    return result


def require_string_map(value: object, label: str) -> dict[str, str]:
    if not isinstance(value, dict):
        raise TypeError(f"Expected {label} to be an object containing strings")

    result: dict[str, str] = {}
    for key, item in cast(dict[object, object], value).items():
        if not isinstance(key, str) or not isinstance(item, str):
            raise TypeError(f"Expected {label} to be an object containing strings")
        result[key] = item
    return result


def find_matches(pattern: re.Pattern[str], source: str) -> list[str]:
    return cast(list[str], pattern.findall(source))


def find_match_pairs(pattern: re.Pattern[str], source: str) -> list[tuple[str, str]]:
    return cast(list[tuple[str, str]], pattern.findall(source))


def require_unique(values: list[str], label: str) -> None:
    duplicates = sorted(value for value, count in Counter(values).items() if count > 1)
    if duplicates:
        raise ValueError(f"Duplicate {label}: {', '.join(duplicates)}")


def get_scaled_texture_path(path: str) -> str:
    resource_path = PurePosixPath(path)
    return str(
        resource_path.with_name(f"{resource_path.stem}@2x{resource_path.suffix}")
    )


def validate_gui_textures(game_root: Path, sources: list[str]) -> None:
    archive_path = game_root / "base" / "content" / "gui.zip"
    if not archive_path.is_file():
        raise ValueError(f"Missing game GUI archive: {archive_path}")
    with zipfile.ZipFile(archive_path) as archive:
        archived_files = set(archive.namelist())

    resource_paths = {
        match
        for source in sources
        for match in find_matches(GUI_TEXTURE_PATTERN, source)
    }
    missing_resources: list[str] = []
    for resource_path in sorted(resource_paths):
        relative_path = resource_path.removeprefix("::/")
        candidates = (relative_path, get_scaled_texture_path(relative_path))
        is_unpacked = any(
            (game_root / "content" / candidate).is_file() for candidate in candidates
        )
        is_archived = any(candidate in archived_files for candidate in candidates)
        if not is_unpacked and not is_archived:
            missing_resources.append(resource_path)
    if missing_resources:
        raise ValueError(f"Missing GUI textures: {', '.join(missing_resources)}")


def validate_metadata_icon(path: Path) -> None:
    if not path.is_file():
        raise ValueError(f"Missing metadata icon: {path}")
    with path.open("rb") as file:
        if file.read(len(PNG_SIGNATURE)) != PNG_SIGNATURE:
            raise ValueError(f"Metadata icon is not a PNG file: {path}")


def validate_parameter_defaults(
    parameters: list[ModParameter], script: str
) -> set[str]:
    parameter_key_pairs = find_match_pairs(PARAMETER_KEY_PATTERN, script)
    require_unique(
        [constant for constant, _ in parameter_key_pairs], "parameter key constants"
    )
    require_unique(
        [key for _, key in parameter_key_pairs], "parameter key constant values"
    )
    current_parameter_key_pairs = [
        pair for pair in parameter_key_pairs if not pair[0].startswith("LEGACY_")
    ]
    legacy_parameter_key_pairs = [
        pair for pair in parameter_key_pairs if pair[0].startswith("LEGACY_")
    ]
    parameter_key_by_constant = dict(current_parameter_key_pairs)

    default_index_pairs = find_match_pairs(DEFAULT_PARAM_INDEX_PATTERN, script)
    require_unique(
        [constant for constant, _ in default_index_pairs],
        "default parameter constants",
    )
    actual_defaults: dict[str, int] = {}
    for constant, raw_index in default_index_pairs:
        key = parameter_key_by_constant.get(constant)
        if key is None:
            raise ValueError(f"Unknown default parameter constant: {constant}")
        actual_defaults[key] = int(raw_index)

    expected_defaults = {
        parameter["key"]: parameter["default_index"] + 1 for parameter in parameters
    }
    if actual_defaults != expected_defaults:
        details = f"expected={expected_defaults}, actual={actual_defaults}"
        raise ValueError(f"Runtime parameter defaults do not match manifest: {details}")
    return {key for _, key in legacy_parameter_key_pairs}


def require_single_match(pattern: re.Pattern[str], source: str, label: str) -> str:
    matches = find_matches(pattern, source)
    if len(matches) != 1:
        raise ValueError(f"Expected one {label}, found: {matches!r}")
    return matches[0]


def validate_game_bar_plugin(resource: str, script: str, mod_id: str) -> None:
    extension_point = require_single_match(
        REACT_PLUGIN_TYPE_PATTERN, resource, "game-bar extension point"
    )
    if extension_point != GAME_BAR_EXTENSION_POINT:
        raise ValueError(f"Unexpected game-bar extension point: {extension_point}")

    _ = require_single_match(PLUGIN_ORDER_PATTERN, resource, "positive game-bar order")
    for field in ("order", "priority"):
        assignment = f"{field} = GAME_BAR_ORDER"
        if resource.count(assignment) != 1:
            raise ValueError(f"Expected one game-bar {assignment!r} assignment")

    plugin_paths = find_match_pairs(PLUGIN_FILE_PATH_PATTERN, resource)
    if len(plugin_paths) != 1:
        raise ValueError(
            f"Expected one game-bar plugin file path, found: {plugin_paths!r}"
        )
    file_path, recipe = plugin_paths[0]
    expected_file_path = f"{mod_id}::/vehicle_readout/vehicle_readout.script"
    if file_path != expected_file_path:
        raise ValueError(
            f"Game-bar plugin file path does not match script: {file_path}"
        )

    registrations = find_match_pairs(PLUGIN_REGISTRATION_PATTERN, script)
    if registrations != [(recipe, extension_point)]:
        raise ValueError(
            f"Game-bar plugin registration does not match resource: {registrations!r}"
        )
    exported_recipes = set(find_matches(IDENTITY_EXPORT_PATTERN, script))
    if recipe not in exported_recipes:
        raise ValueError(f"Game-bar plugin recipe is not exported: {recipe}")


def get_supported_locales(game_root: Path) -> set[str]:
    archive_path = game_root / "base" / "content" / "locale.zip"
    if not archive_path.is_file():
        raise ValueError(f"Missing game locale archive: {archive_path}")
    with zipfile.ZipFile(archive_path) as archive:
        locales = {
            path.name.removesuffix(".lang.lua")
            for name in archive.namelist()
            if (path := PurePosixPath(name)).parent == PurePosixPath("locale")
            and path.name.endswith(".lang.lua")
        }
    if "en" not in locales:
        raise ValueError(
            f"Game locale archive does not contain English: {archive_path}"
        )
    return locales


def validate_localisations(
    strings: dict[str, object], supported_locales: set[str]
) -> dict[str, str]:
    actual_locales = set(strings)
    if actual_locales != supported_locales:
        missing = sorted(supported_locales - actual_locales)
        unexpected = sorted(actual_locales - supported_locales)
        raise ValueError(
            f"Localisation locale mismatch: missing={missing}, unexpected={unexpected}"
        )

    english_strings = require_string_map(strings.get("en"), "strings.en")
    english_keys = set(english_strings)
    english_placeholders = {
        key: Counter(find_matches(PLACEHOLDER_PATTERN, value))
        for key, value in english_strings.items()
    }
    for locale in sorted(supported_locales):
        localised_strings = require_string_map(strings.get(locale), f"strings.{locale}")
        localised_keys = set(localised_strings)
        if localised_keys != english_keys:
            missing = sorted(english_keys - localised_keys)
            unexpected = sorted(localised_keys - english_keys)
            details = f"missing={missing}, unexpected={unexpected}"
            raise ValueError(f"Localisation key mismatch for {locale}: {details}")
        empty_keys = sorted(
            key for key, value in localised_strings.items() if not value.strip()
        )
        if empty_keys:
            raise ValueError(f"Empty {locale} localisation: {', '.join(empty_keys)}")
        for key, expected_placeholders in english_placeholders.items():
            actual_placeholders = Counter(
                find_matches(PLACEHOLDER_PATTERN, localised_strings[key])
            )
            if actual_placeholders != expected_placeholders:
                details = (
                    f"expected={dict(expected_placeholders)}, "
                    f"actual={dict(actual_placeholders)}"
                )
                raise ValueError(f"Placeholder mismatch for {locale}.{key}: {details}")
    return english_strings


def validate_metadata_localisations(
    path: Path, supported_locales: set[str]
) -> dict[str, str]:
    strings = load_json_object(path)
    actual_locales = set(strings)
    if actual_locales != supported_locales:
        missing = sorted(supported_locales - actual_locales)
        unexpected = sorted(actual_locales - supported_locales)
        raise ValueError(
            f"Metadata locale mismatch: missing={missing}, unexpected={unexpected}"
        )
    required_keys = {"NAME", "SUMMARY", "DESCRIPTION"}
    english_metadata: dict[str, str] | None = None
    for locale in sorted(supported_locales):
        locale_groups = strings.get(locale)
        if not isinstance(locale_groups, dict):
            raise TypeError(f"Expected metadata strings.{locale} to be an object")
        default_group = require_string_map(
            cast(dict[str, object], locale_groups).get(""),
            f"metadata strings.{locale}['']",
        )
        if set(default_group) != required_keys:
            missing = sorted(required_keys - set(default_group))
            unexpected = sorted(set(default_group) - required_keys)
            details = f"missing={missing}, unexpected={unexpected}"
            raise ValueError(f"Metadata key mismatch for {locale}: {details}")
        empty_keys = sorted(
            key for key, value in default_group.items() if not value.strip()
        )
        if empty_keys:
            raise ValueError(
                f"Empty {locale} metadata localisation: {', '.join(empty_keys)}"
            )
        if locale == "en":
            english_metadata = default_group
    if english_metadata is None:
        raise ValueError("Missing English metadata localisation")
    return english_metadata


def main() -> None:
    if len(sys.argv) != 3:
        raise ValueError("Usage: validate_resources.py MOD_ROOT GAME_ROOT")

    mod_root = Path(sys.argv[1]).resolve()
    game_root = Path(sys.argv[2]).resolve()
    manifest = load_json_object(mod_root / "mod.json")
    strings = load_json_object(mod_root / "strings.json")
    metadata = load_json_object(mod_root / "_metadata" / "modinfo.json")
    supported_locales = get_supported_locales(game_root)
    validate_metadata_icon(mod_root / "_metadata" / "0.png")
    english_metadata = validate_metadata_localisations(
        mod_root / "_metadata" / "strings.json", supported_locales
    )
    metadata_fields = {
        "NAME": "name",
        "SUMMARY": "summary",
        "DESCRIPTION": "description",
    }
    for localisation_key, metadata_key in metadata_fields.items():
        metadata_value = require_nonempty_string(
            metadata.get(metadata_key), f"modinfo.{metadata_key}"
        )
        if english_metadata[localisation_key] != metadata_value:
            raise ValueError(
                f"English metadata {localisation_key} does not match modinfo.{metadata_key}"
            )

    mod_id = require_nonempty_string(manifest.get("modId"), "modId")
    parameters = parse_parameters(manifest.get("params"))
    parameter_keys = [parameter["key"] for parameter in parameters]
    require_unique(parameter_keys, "parameter keys")
    parameter_prefix = f"{mod_id}_"
    invalid_parameter_keys = sorted(
        key for key in parameter_keys if not key.startswith(parameter_prefix)
    )
    if invalid_parameter_keys:
        raise ValueError(
            f"Parameter keys outside the mod namespace: {', '.join(invalid_parameter_keys)}"
        )

    english_strings = validate_localisations(strings, supported_locales)
    manifest_localisation_keys = {
        localisation_key
        for parameter in parameters
        for localisation_key in (
            parameter["name"],
            parameter["tooltip"],
            *parameter["values"],
        )
    }
    script_path = mod_root / "content" / "vehicle_readout" / "vehicle_readout.script.tl"
    stylesheet_path = (
        mod_root / "content" / "vehicle_readout" / "vehicle_readout.css.lua"
    )
    replacement_path = (
        mod_root / "content" / "vehicle_readout" / "vehicle_readout_replacement.res.lua"
    )
    game_bar_plugin_path = (
        mod_root / "content" / "vehicle_readout" / "vehicle_readout_game_bar.res.lua"
    )
    script = script_path.read_text(encoding="utf-8")
    stylesheet = stylesheet_path.read_text(encoding="utf-8")
    replacement = replacement_path.read_text(encoding="utf-8")
    game_bar_plugin = game_bar_plugin_path.read_text(encoding="utf-8")
    source_mod_ids = find_matches(MOD_ID_PATTERN, script)
    if len(source_mod_ids) != 1:
        raise ValueError(f"Expected one script MOD_ID, found: {source_mod_ids!r}")
    resource_namespace = source_mod_ids[0]
    if resource_namespace != mod_id:
        raise ValueError(
            f"Script resource namespace does not match manifest modId: {resource_namespace}"
        )
    referenced_resource_namespaces = set(
        find_matches(PROJECT_RESOURCE_PATTERN, script + replacement + game_bar_plugin)
    )
    if referenced_resource_namespaces != {resource_namespace}:
        namespaces = sorted(referenced_resource_namespaces)
        raise ValueError(f"Vehicle Readout resource namespace mismatch: {namespaces}")
    validate_game_bar_plugin(game_bar_plugin, script, resource_namespace)
    localisation_prefix = parameter_prefix.upper()
    script_localisation_keys = {
        key
        for key in find_matches(LOCALISATION_PATTERN, script)
        if key.startswith(localisation_prefix)
    }
    used_localisation_keys = script_localisation_keys | manifest_localisation_keys
    missing_localisation_keys = sorted(used_localisation_keys - english_strings.keys())
    if missing_localisation_keys:
        raise ValueError(
            f"Missing localisation keys: {', '.join(missing_localisation_keys)}"
        )
    project_localisation_keys = {
        key for key in english_strings if key.startswith(localisation_prefix)
    }
    unused_localisation_keys = sorted(
        project_localisation_keys - used_localisation_keys
    )
    if unused_localisation_keys:
        raise ValueError(
            f"Unused localisation keys: {', '.join(unused_localisation_keys)}"
        )

    legacy_parameter_keys = validate_parameter_defaults(parameters, script)
    invalid_legacy_parameter_keys = sorted(
        key for key in legacy_parameter_keys if not key.startswith(parameter_prefix)
    )
    if invalid_legacy_parameter_keys:
        raise ValueError(
            "Legacy parameter keys outside the mod namespace: "
            + ", ".join(invalid_legacy_parameter_keys)
        )
    manifest_parameter_keys = set(parameter_keys)
    legacy_keys_in_manifest = sorted(legacy_parameter_keys & manifest_parameter_keys)
    if legacy_keys_in_manifest:
        raise ValueError(
            "Legacy parameter keys remain in manifest: "
            + ", ".join(legacy_keys_in_manifest)
        )
    script_parameter_keys = {
        key
        for key in find_matches(PARAMETER_PATTERN, script)
        if key not in {mod_id, resource_namespace} and key.startswith(parameter_prefix)
    } - legacy_parameter_keys
    if script_parameter_keys != manifest_parameter_keys:
        missing_in_manifest = sorted(script_parameter_keys - manifest_parameter_keys)
        missing_in_script = sorted(manifest_parameter_keys - script_parameter_keys)
        details = (
            f"missing in manifest={missing_in_manifest}, "
            f"missing in script={missing_in_script}"
        )
        raise ValueError(f"Parameter mismatch: {details}")
    validate_gui_textures(game_root, [script, stylesheet])
    print("Resources, metadata, localisation, and parameters: OK")


if __name__ == "__main__":
    main()
