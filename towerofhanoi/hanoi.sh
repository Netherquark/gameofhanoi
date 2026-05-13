#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2178

# hanoi.sh - Tower of Hanoi: Recursive and Iterative Demonstrations
# Relevant lines for recursion / iteration : Line 130 - 196

set -euo pipefail

export LC_ALL=C
export LANG=en_US.UTF-8


DISK_COUNT=3
ALGORITHM_MODE="recursive"
SPEED_SETTING="Normal"
DELAY=1.0

MOVE_COUNT=0
ACTIVE_CALL_LEVEL=0
CALL_BANNER=""

declare -a rod_1=()
declare -a rod_2=()
declare -a rod_3=()

POPPED_DISK=0

cleanup() {
    tput cnorm      
    tput sgr0       
    tput rmcup      
}

trap 'cleanup; exit' EXIT SIGINT SIGTERM

init_state() {
    rod_1=()
    rod_2=()
    rod_3=()
    for (( i=DISK_COUNT; i>=1; i-- )); do
        rod_1+=("$i")
    done
    MOVE_COUNT=0
}

get_top_disk() {
    local rod_idx=$1
    local -n rod_ref="rod_$rod_idx"
    [[ ${#rod_ref[@]} -eq 0 ]] && TOP_DISK_RESULT=0 || TOP_DISK_RESULT=${rod_ref[-1]}
}

push_disk() {
    local rod_idx=$1
    local disk=$2
    local -n rod_ref="rod_$rod_idx"
    rod_ref+=("$disk")
}

pop_disk() {
    local rod_idx=$1
    local -n rod_ref="rod_$rod_idx"
    POPPED_DISK=${rod_ref[-1]}
    unset 'rod_ref[-1]'
}

can_move() {
    local from=$1 to=$2
    get_top_disk "$from"; local src=$TOP_DISK_RESULT
    [[ "$src" -eq 0 ]] && return 1
    get_top_disk "$to"; local dst=$TOP_DISK_RESULT
    [[ "$dst" -eq 0 ]] || [[ "$src" -lt "$dst" ]] && return 0
    return 1
}

redraw_frame() {
    tput clear
    local cols; cols=$(tput cols)
    local rows; rows=$(tput lines)
    
    [[ $cols -lt 40 || $rows -lt 15 ]] && { printf "Terminal too small."; return; }
    
    # Header
    tput cup 1 $(( (cols - 14) / 2 )); tput bold; printf "TOWER OF HANOI"; tput sgr0
    tput cup 3 2; printf "Mode: %s | Speed: %s (%.1fs) | Moves: %d" "$ALGORITHM_MODE" "$SPEED_SETTING" "$DELAY" "$MOVE_COUNT"
    
    if [[ "$ALGORITHM_MODE" == "recursive" ]]; then
        tput cup 4 2; printf "Recursion Depth: %d" "$ACTIVE_CALL_LEVEL"
        tput cup 5 2; tput setaf 6; printf "Active Call: %s" "$CALL_BANNER"; tput sgr0
    fi
    
    local rod_spacing=$(( cols / 4 ))
    local base_row=$(( rows - 5 ))
    
    tput sgr0; tput cup "$base_row" $(( rod_spacing / 2 ))
    for (( i=0; i < $(( 3 * rod_spacing )); i++ )); do printf "━"; done
    
    for i in 1 2 3; do
        local center=$(( i * rod_spacing ))
        tput cup $(( base_row + 1 )) $(( center - 4 )); printf "Rod %d" "$i"
        
        local -n rod="rod_$i"
        local r=$(( base_row - 1 ))
        for disk in "${rod[@]}"; do
            local start=$(( center - disk ))
            tput cup "$r" "$start"
            local rgb=("255;80;80" "255;150;50" "255;230;50" "100;255;100" "80;220;255" "100;150;255" "180;100;255" "255;100;255" "255;150;200" "200;200;200")
            printf "\033[38;2;%sm" "${rgb[$(( (disk-1)%10 ))]}"
            for (( k=0; k < disk*2+1; k++ )); do printf "█"; done
            tput sgr0
            r=$(( r - 1 ))
        done
        for (( k=r; k > base_row - DISK_COUNT - 2; k-- )); do
            tput cup "$k" "$center"; printf "┃"
        done
    done
    tput cup $(( rows - 1 )) 0
}

perform_move() {
    if can_move "$1" "$2"; then
        pop_disk "$1"
        push_disk "$2" "$POPPED_DISK"
        MOVE_COUNT=$(( MOVE_COUNT + 1 ))
        redraw_frame
        command sleep "$DELAY"
    else
        exit 1
    fi
}

# The recursive solver demonstrates the "divide and conquer" strategy.
# To move N disks from source to target:
# 1. Base Case: If N=0, do nothing (terminates recursion).
# 2. Recursive Step: Move N-1 disks to the auxiliary rod.
# 3. Work: Move the largest disk (N) to the target rod.
# 4. Recursive Step: Move N-1 disks from the auxiliary rod to the target rod.

solve_recursive() {
    local n=$1 source=$2 target=$3 auxiliary=$4 depth=$5
    
    # Update UI to reflect current call stack depth (demonstrating recursive state)
    ACTIVE_CALL_LEVEL=$depth
    CALL_BANNER="HANOI(n=$n, src=$source, dst=$target, aux=$auxiliary)"
    
    # 1. BASE CASE: Terminates the recursive calls
    if [[ "$n" -eq 0 ]]; then return; fi
    
    # 2. RECURSIVE CALL: Moving the upper sub-stack (n-1) to the auxiliary rod
    solve_recursive "$(( n - 1 ))" "$source" "$auxiliary" "$target" "$(( depth + 1 ))"
    
    # 3. WORK: Moving the n-th disk (happens after n-1 disks are out of the way)
    ACTIVE_CALL_LEVEL=$depth
    CALL_BANNER="HANOI(n=$n, src=$source, dst=$target, aux=$auxiliary)"
    perform_move "$source" "$target"
    
    # 4. RECURSIVE STEP: Moving the sub-stack (n-1) from auxiliary to target
    solve_recursive "$(( n - 1 ))" "$auxiliary" "$target" "$source" "$(( depth + 1 ))"
}

# The iterative solver demonstrates solving the same problem using a loop.
# It follows a fixed mathematical pattern based on the total number of moves (2^N - 1).
# 1. A 'for' loop iterates from 1 to the total number of moves.
# 2. Parity logic determines the direction of the smallest disk.
# 3. Every odd step moves the smallest disk.
# 4. Every even step makes the only other legal move.

solve_iterative() {
    local n=$1
    local total_moves=$(( 2**n - 1 )) # Mathematical total moves for 3 rods
    local cycle
    
    # Parity-based initialization (Iteration preparation)
    if (( n % 2 == 0 )); then cycle=(1 2 3); else cycle=(1 3 2); fi
    local smallest_rod=1
    
    # THE ITERATIVE LOOP: Executes exactly total_moves times
    for (( step=1; step <= total_moves; step++ )); do
        if (( step % 2 != 0 )); then
            # Odd steps: Iterate smallest disk position
            local next_rod
            if [[ "$smallest_rod" -eq "${cycle[0]}" ]]; then next_rod="${cycle[1]}"
            elif [[ "$smallest_rod" -eq "${cycle[1]}" ]]; then next_rod="${cycle[2]}"
            else next_rod="${cycle[0]}"; fi
            
            perform_move "$smallest_rod" "$next_rod"
            smallest_rod="$next_rod"
        else
            # Even steps: Make the only legal move NOT involving the smallest disk
            local c1 c2
            case "$smallest_rod" in
                1) c1=2; c2=3 ;; 2) c1=1; c2=3 ;; 3) c1=1; c2=2 ;;
            esac
            
            if can_move "$c1" "$c2"; then perform_move "$c1" "$c2"; else perform_move "$c2" "$c1"; fi
        fi
    done
}

show_menu() {
    tput sgr0; clear
    printf "==============================\n    TOWER OF HANOI SOLVER\n==============================\n\n"
    while true; do
        printf "Select Algorithm:\n1) Iterative (Loop-based)\n2) Recursive (Divide-and-Conquer)\n"
        read -rp "Choice (1-2): " choice
        [[ "$choice" == "1" ]] && { ALGORITHM_MODE="iterative"; break; }
        [[ "$choice" == "2" ]] && { ALGORITHM_MODE="recursive"; break; }
        printf "Invalid choice\n\n"
    done
    printf "\n"
    while true; do
        read -rp "Number of disks (1-10): " disks
        [[ "$disks" =~ ^[0-9]+$ ]] && (( disks >= 1 && disks <= 10 )) && { DISK_COUNT=$disks; break; }
        printf "Invalid disk count (1-10)\n\n"
    done
    printf "\nSelect Speed:\n1) Slow (2.0s)\n2) Normal (1.0s)\n3) Fast (0.2s)\n4) Instant (0.0s)\n"
    while true; do
        read -rp "Choice (1-4): " schoice
        case "$schoice" in
            1) SPEED_SETTING="Slow"; DELAY=2.0; break ;;
            2) SPEED_SETTING="Normal"; DELAY=1.0; break ;;
            3) SPEED_SETTING="Fast"; DELAY=0.2; break ;;
            4) SPEED_SETTING="Instant"; DELAY=0.0; break ;;
            *) printf "Invalid choice\n" ;;
        esac
    done
}

[[ ! -t 1 ]] && { echo "Error: Need TTY." >&2; exit 1; }

show_menu
tput smcup; tput civis; clear
init_state; redraw_frame

if [[ "$ALGORITHM_MODE" == "recursive" ]]; then
    solve_recursive "$DISK_COUNT" 1 3 2 1
else
    solve_iterative "$DISK_COUNT"
fi

CALL_BANNER="COMPLETE"; ACTIVE_CALL_LEVEL=0; redraw_frame
tput cup $(( $(tput lines) - 3 )) 2; tput bold; tput setaf 2
printf "Task Complete! Total moves: %d\n" "$MOVE_COUNT"; tput sgr0
tput cup $(( $(tput lines) - 2 )) 2; printf "Press any key to exit..."; read -rsn 1
