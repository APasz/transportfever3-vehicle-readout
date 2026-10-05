#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mod_root="$(cd -- "${script_dir}/.." && pwd)"
game_root="${1:-${TF3_GAME_DIR:-/home/apasz/.local/share/Steam/steamapps/common/Transport Fever 3}}"
compiler_archive="${game_root}/base/content/base.zip"

if [[ ! -f "${compiler_archive}" ]]; then
	printf 'Transport Fever 3 compiler archive not found: %s\n' "${compiler_archive}" >&2
	exit 1
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT
unzip -p "${compiler_archive}" base/tl.lua > "${temporary_dir}/tl.lua"

lua "${script_dir}/validate.lua" "${temporary_dir}/tl.lua" "${game_root}" "${mod_root}"
luac -p \
	"${mod_root}/content/vehicle_readout/vehicle_readout.css.lua" \
	"${mod_root}/content/vehicle_readout/vehicle_readout_game_bar.res.lua" \
	"${mod_root}/content/vehicle_readout/vehicle_readout_replacement.res.lua" \
	"${mod_root}/tlconfig.lua"
python3 "${script_dir}/validate_resources.py" "${mod_root}" "${game_root}"

printf 'All automated validation passed.\n'
