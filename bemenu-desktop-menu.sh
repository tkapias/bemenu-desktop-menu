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
# tmp file storing POSIX date of the last modification and count of entries
tmp_last="/tmp/bemenu-desktop-menu_last"

old_last=$(cut -d " " -f1 < $tmp_last)
new_last=$(stat --format='%Y' "${desktop_files[@]}" | sort -n | tail -1)
old_count=$(cut -d " " -f2 < $tmp_last)
new_count=$(/usr/bin/ls "${desktop_files[@]}" | wc -l)
echo -n "$new_last $new_count" > "$tmp_last"

if [[ -f "$tmp_last" ]] && [[ "$old_last" -ge "$new_last" ]] && [[ "$old_count" == "$new_count" ]]; then
  "${bemenu_cmd[@]}" --prompt "󰣆 Desktop Menu" < "$tmp_list" | awk -F '[][]' '{print $2}' \
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
    local filename category name genericname lang
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
    # localized names
    if [[ -n "${LANGUAGE::2}" ]]; then
      lang="\[${LANGUAGE::2}\]"
      if grep -q -e "Name[${lang}]="; then
        name=$(sed -rn "/^\[Desktop Entry\]$/,/^\[/{s/^Name${lang}=(.*)$/\1/p}" "$1")
      else
        name=$(sed -rn "/^\[Desktop Entry\]$/,/^\[/{s/^Name=(.*)$/\1/p}" "$1")
      fi
      if grep -q -e "GenericName[${lang}]="; then
        genericname=$(sed -rn "/^\[Desktop Entry\]$/,/^\[/{s/^GenericName${lang}=(.*)$/\1/p}" "$1")
      else
        genericname=$(sed -rn "/^\[Desktop Entry\]$/,/^\[/{s/^GenericName=(.*)$/\1/p}" "$1")
      fi
    fi
    if [[ -n "$genericname" ]] && [[ ! "$genericname" == "$name" ]]; then
      name+="  ($genericname)"
    fi
    # line for the menu
    printf '%s %-55s[%s]\n' "${!category}" "$name" "$1"
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
