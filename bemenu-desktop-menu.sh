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

declare desktop_list filename categorie icon name
declare -a bemenu_cmd desktop_path desktop_files \
  desktop_filenames desktop_filenames
declare -A categories_xdg

# bemenu command
bemenu_cmd=(bemenu)

# matching emoji for main categories
categories_xdg[AudioVideo]="🎬"
categories_xdg[Audio]="🎧"
categories_xdg[Video]="🎞️"
categories_xdg[Development]="🚀"
categories_xdg[Education]="🎓"
categories_xdg[Game]="🎮"
categories_xdg[Graphics]="🎨"
categories_xdg[Network]="📡"
categories_xdg[Office]="💼"
categories_xdg[Science]="🧪"
categories_xdg[Settings]="🪛"
categories_xdg[System]="💻"
categories_xdg[Utility]="🛠️"
categories_xdg[Other]="❓"

# desktop entries directories paths
desktop_path=( "$HOME/.local/share/applications" )
desktop_path+=( "/usr/local/share/applications" )
desktop_path+=( "/usr/share/applications" )

# desktop entries absolute paths
desktop_files=( ${desktop_path[*]/%/\/\*\.\*} )

for application in "${desktop_files[@]}"; do
  # wrong filetype?
  if [[ ! "$application" =~ \.desktop$ ]]; then
    continue
  fi

  filename=$(basename "$application")
  # already listed more locally?
  if [[ "${desktop_filenames[*]}" =~ $filename ]]; then
    continue
  fi

  desktop_filenames+=( "$filename" )
  # is marked to not be displayed?
  if /usr/bin/grep -Eq -- '^NoDisplay=true$|^Hidden=true$' "$application"; then
    continue
  fi
  # match icons
  categorie=$(printf '%s\n' \
    "$(sed -rn -e 's/;/\n/g' -e '/^Categories=/{s/^Categories=(.*)$/\1/p;q}' "$application")" \
    "${!categories_xdg[@]}" | sort | uniq -d | head -1)
  if [[ -v "categories_xdg[$categorie]" ]]; then
    icon="${categories_xdg[$categorie]}"
  else
    icon="${categories_xdg[Other]}"
  fi

  name=$(sed -r -n '/^Name=/{s/^Name=(.*)$/\1/p;q}' "$application")
  # append 'icon name [absolute path]'
  desktop_list+="$icon $(printf %-50s "$name") [$application]\n"
done

# run the file with setsid and dex
echo -e "$desktop_list" \
  | head -c -1 | sort --ignore-case --field-separator=' ' --key=1 --key=2 \
  | "${bemenu_cmd[@]}" --prompt "󰣆 Desktop Menu" | awk -F '[][]' '{print $2}' \
  | xargs -I _ setsid --fork dex _ > /dev/null 2>&1 &

