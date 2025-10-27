#!/usr/bin/env bash

# Simple interactive Bash menu with arrow keys and highlight

# User/config
USERNAME="                                                            Grackle_OS v0.1 "
ART="                                         .__    .  .   ._.   .      .__    
                                         [ __   |  |    |    |      |  \   
                                         [_./ * |__| * _|_ * |___ * |__/ * "
BLANKLINES=4


# Menu choices
options=("Apps" "Sqwak" "Core" "Exit")
selected=0

# Description text
DESCRIPTION="
    Welcome,
                           please make your selection below"

draw_menu() {
    clear
    echo "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
    printf "%% %-76s%%\n" "$USERNAME"
    echo "%%%%%---------------------------------------------------------------------%%%%%"

    # Place ASCII art on the right (first)
    while IFS= read -r line; do
        printf "%% %-76s%%\n" "$line"
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
            bash submenu/1/menu.sh
		elif [[ $selected -eq 1 ]]; then
			bash chat/menu.sh
		elif [[ $selected -eq 2 ]]; then
            if cat apps/installed.txt | grep "Core" ; then
				cd apps/Core
				git pull
				bash sysmon-full.sh
				cd ..
				cd ..
				bash menu.sh
			else
				mkdir apps/Core
				git clone "https://github.com/lewallen4/core-sysmon.git" apps/Core
				echo "Core" >> apps/installed.txt
				cd apps/Core
				bash sysmon-full.sh
				cd ..
				cd ..
				bash menu.sh
			fi
        else
            bash config/exit.sh
			exit
        fi
        break
    fi
done
