#!/usr/bin/env bash

# Simple interactive Bash menu with arrow keys and highlight

# User/config
USERNAME="Grackle_OS"
ART="                                              ╔═╝  ╔═║  ╔═║       ╔═║╔═╝    
                                             ║║ ║  ╔╔╝  ╔═║       ║ ║══║    
                                              ══╝  ╝ ╝  ╝ ╝  ══╝  ══╝══╝    "
BLANKLINES=5

# Menu choices
options=("QuakedIRL      // Earthquakes" "next" "Back")
selected=0

# Description text
DESCRIPTION="
    Choose an App,
                     It will be installed if it is not detected"

draw_menu() {
    clear
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    printf "%% %-76s%%\n" "$USERNAME"
    echo "%%%%%---------------------------------------------------------------------%%%%%"

    # Place ASCII art on the right (first)
    while IFS= read -r line; do
        printf "%% %-102s%%\n" "$line"
    done <<< "$ART"

    echo "%%%%%---------------------------------------------------------------------%%%%%"

    # Description section
    while IFS= read -r line; do
        printf "%% %-76s%%\n" "$line"
    done <<< "$DESCRIPTION"

    # Add blank lines after description (set by $BLANKLINES)
    for ((i=0; i<BLANKLINES; i++)); do
        printf "%% %-76s%%\n" " "
    done

    echo "%%%%%---------------------------------------------------------------------%%%%%"

    # Menu area (with blank line above and below)
    printf "%% %-76s%%\n" " "   # blank line
    for i in "${!options[@]}"; do
        if [[ $i -eq $selected ]]; then
            printf "%%   > %-72s%%\n" "${options[$i]}"
        else
            printf "%%     %-72s%%\n" "${options[$i]}"
        fi
    done
    printf "%% %-76s%%\n" " "   # blank line

    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    echo "Use ↑/↓ arrows to move, Enter to select"
}

# Read arrow keys
while true; do
    draw_menu
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.1 key
        case $key in
            "[A") # Up
                ((selected--))
                ((selected<0)) && selected=$((${#options[@]}-1))
                ;;
            "[B") # Down
                ((selected++))
                ((selected>=${#options[@]})) && selected=0
                ;;
        esac
    elif [[ $key == "" ]]; then # Enter
        clear
        if [[ $selected -eq 0 ]]; then
            if cat apps/installed.txt | grep "QuakedIRL" ; then
				cd apps/QuakedIRL
				git pull
				bash script.sh
				cd ..
				cd ..
				bash submenu/1/menu.sh
			else
				mkdir apps/QuakedIRL
				git clone "https://github.com/lewallen4/QuakedIRL.git" apps/QuakedIRL
				echo "QuakedIRL" >> apps/installed.txt
				cd apps/QuakedIRL
				bash script.sh
				cd ..
				cd ..
				bash submenu/1/menu.sh
			fi
		elif [[ $selected -eq 1 ]]; then
			bash submenu/1/menu.sh
        else
            bash menu.sh
        fi
        break
    fi
done
