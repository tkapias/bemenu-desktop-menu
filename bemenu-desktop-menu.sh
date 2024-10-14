#!/usr/bin/env bash

#########################
# bemenu-desktop-menu
#
# Licence: GNU GPLv3
# Author: Tomasz Kapias
#
# Dependencies:
#   bemenu v0.6.23
#   bemenu-orange-wrapper
#   Nerd-Fonts
#   bash
#   sed, xargs, awk
#   dex
#   setsid
#
#########################

shopt -s extglob

declare -f format_entries
declare -a bemenu_cmd desktop_path desktop_files
declare AudioVideo Audio Video Development Education Game Graphics Network \
  Office Science Settings System Utility Other tmplist

# bemenu command
bemenu_cmd=(bemenu)

# desktop entries directories paths
desktop_path=( "$HOME/.local/share/applications" )
desktop_path+=( "/usr/local/share/applications" )
desktop_path+=( "/usr/share/applications" )

# desktop entries absolute filepaths
# shellcheck disable=SC2206
desktop_files=( ${desktop_path[*]/%//*.desktop} )

# temporary fle to store unique entires filenames
tmplist="/tmp/.bemenu-desktop-menu.tmp"

# main categories icons
AudioVideo="🎬"
Audio="🎧"
Video="🎞️"
Development="🚀"
Education="🎓"
Game="🎮"
Graphics="🎨"
Network="📡"
Office="💼"
Science="🧪"
Settings="🪛"
System="💻"
Utility="🛠️"
Other="❓"

format_entries() {
  local filename category
  # keep the most local version
  filename=$(basename "$1")
  if /usr/bin/grep -Eq "$filename" "$tmplist"; then
    return
  else
    echo " $filename" >> "$tmplist"
  fi
  # respect NoDisplay & Hidden
  if /usr/bin/grep -Eq '^NoDisplay=true$|^Hidden=true$' "$1"; then
    return
  fi
  # assocate the first main category to an icon
  category=$(printf '%s\n' "$(sed -rn -e 's/;/\n/g' -e '/^Categories=/{s/^Categories=(.*)$/\1 AudioVideo Audio Video Development Education Game Graphics Network Office Science Settings System Utility Other/p;q}' "$1")" | tr ' ' '\n' | sort | uniq -d | head -1)
  [[ -z "$category" ]] && category="Other"
  # line for the menu
  printf '%s %-50s[%s]\n' "${!category}" "$(sed -rn '/^Name=/{s/^Name=(.*)$/\1/p;q}' "$1")" "$1"
}

# exports for the subshells in xargs
export -f format_entries
export AudioVideo Audio Video Development Education Game Graphics Network Office Science Settings System Utility Other
export tmplist

# create/clean tmplist
truncate --size 0 "$tmplist"

# main
printf '%s\0' "${desktop_files[@]}" | xargs -0 -P 8 -I {} bash -c 'format_entries "$@"' _ {} \
  | head -c -1 | sort --ignore-case --field-separator=' ' --key=1 --key=2 \
  | "${bemenu_cmd[@]}" --prompt "󰣆 Desktop Menu" | awk -F '[][]' '{print $2}' \
  | xargs -I _ setsid --fork dex _ > /dev/null 2>&1 &

