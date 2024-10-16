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
  Office Science Settings System Utility Other
declare tmp_list tmp_entries tmp_last old_last new_last

# bemenu command
bemenu_cmd=(bemenu)

# desktop entries directories paths
desktop_path=( "$HOME/.local/share/applications" )
desktop_path+=( "/usr/local/share/applications" )
desktop_path+=( "/usr/share/applications" )

# desktop entries absolute filepaths
# shellcheck disable=SC2206
desktop_files=( ${desktop_path[*]/%//*.desktop} )

# tmp file storing the bemenu list generated last time
tmp_list="/tmp/bemenu-desktop-menu_list"
# tmp file storing filenames of unique entires
tmp_entries="/tmp/bemenu-desktop-menu_entries"
# tmp file storing POSIX date of the last modification to entries
tmp_last="/tmp/bemenu-desktop-menu_last"

old_last=$(cat $tmp_last)
new_last=$(stat --format='%Y' "${desktop_files[@]}" | sort -n | tail -1)
echo -n "$new_last" > "$tmp_last"

if [[ -f "$tmp_last" ]] && [[ "$old_last" -ge "$new_last" ]]; then
  cat "$tmp_list" | "${bemenu_cmd[@]}" --prompt "󰣆 Desktop Menu" | awk -F '[][]' '{print $2}' \
  | xargs -I _ setsid --fork dex _ > /dev/null 2>&1 &
else
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
    if /usr/bin/grep -Eq "$filename" "$tmp_entries"; then
      return
    else
      echo " $filename" >> "$tmp_entries"
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
  export tmp_entries

  # create/clean tmp_entries
  truncate --size 0 "$tmp_entries"

  # main
  printf '%s\0' "${desktop_files[@]}" | xargs -0 -P 8 -I {} bash -c 'format_entries "$@"' _ {} \
    | head -c -1 | sort --ignore-case --field-separator=' ' --key=1 --key=2 | tee "$tmp_list" \
    | "${bemenu_cmd[@]}" --prompt "󰣆 Desktop Menu" | awk -F '[][]' '{print $2}' \
    | xargs -I _ setsid --fork dex _ > /dev/null 2>&1 &
fi
