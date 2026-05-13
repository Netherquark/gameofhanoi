#!/usr/bin/env bash

# Game of Life

set -u

# State
ROWS=0
COLS=0
GENERATION=0
LIVE_CELLS=0
DELAY="0.10"
DELAY_MS=100
RENDER_FREQ=3
PAUSED=false
STEP_REQUESTED=false
RUNNING=true
CURR_IDX=0

# Symbols
ALIVE="●"
DEAD="·"
COLOR_GRID=()

# Grids
grid_0=()
grid_1=()
rendered_grid=()
UP=()
DOWN=()
LEFT=()
RIGHT=()

cleanup() {
    tput cnorm 2>/dev/null || true
    tput sgr0 2>/dev/null || true
    clear
    printf "Game of Life exited.\n"
    exit 0
}

on_signal() {
    cleanup
}

trap cleanup EXIT
trap on_signal INT TERM

init_terminal() {
    printf '\033[2J'
    tput civis
}

get_term_size() {
    ROWS=$(tput lines)
    COLS=$(tput cols)
    ROWS=$((ROWS - 5))
    (( ROWS < 5 )) && ROWS=5
    (( COLS < 5 )) && COLS=5
}

make_empty_grid() {
    local total=$((ROWS * COLS))
    # Iteration: Initialize flat arrays using a single loop
    for ((i=0; i<total; i++)); do
        grid_0[i]=0
        grid_1[i]=0
        rendered_grid[i]=-1
    done
}

set_cell() {
    local r=$1
    local c=$2
    local val=$3
    
    if [[ $r -lt 0 || $r -ge ROWS || $c -lt 0 || $c -ge COLS ]]; then
        return
    fi
    
    local idx=$((r * COLS + c))
    local -n curr="grid_$CURR_IDX"
    if [[ "$val" == "$ALIVE" ]]; then
        curr[idx]=1
    else
        curr[idx]=0
    fi
}

count_live_cells() {
    LIVE_CELLS=0
    local val
    local -n curr="grid_$CURR_IDX"
    # Iteration: Traverse the entire grid array to sum live cells
    for val in "${curr[@]}"; do
        (( LIVE_CELLS += val ))
    done
}

compute_next_grid() {
    local r c idx neighbors alive
    local ru rd cl cr r_cols ru_cols rd_cols
    local next_idx=$(( 1 - CURR_IDX ))
    local -n curr="grid_$CURR_IDX"
    local -n next="grid_$next_idx"
    
    LIVE_CELLS=0
    # Iteration: Nested loops to process every row and column of the grid
    for ((r=0; r<ROWS; r++)); do
        ru=${UP[r]}
        rd=${DOWN[r]}
        ru_cols=$((ru * COLS))
        rd_cols=$((rd * COLS))
        r_cols=$((r * COLS))
        
        for ((c=0; c<COLS; c++)); do
            cl=${LEFT[c]}
            cr=${RIGHT[c]}
            
            # Iteration: Arithmetic summation of 8 neighboring cells
            (( neighbors = 
                curr[ru_cols + cl] + curr[ru_cols + c] + curr[ru_cols + cr] +
                curr[r_cols + cl] +                     curr[r_cols + cr] +
                curr[rd_cols + cl] + curr[rd_cols + c] + curr[rd_cols + cr]
            ))

            idx=$((r_cols + c))
            alive=${curr[idx]}
            
            if (( neighbors == 3 || (alive && neighbors == 2) )); then
                next[idx]=1
                ((LIVE_CELLS++))
            else
                next[idx]=0
            fi
        done
    done
    
    CURR_IDX=$next_idx
}

update_grid() {
    compute_next_grid
    ((GENERATION++))
}

init_grid() {
    make_empty_grid
    # Iteration: Precompute coordinate mappings for toroidal wrapping
    for ((r=0; r<ROWS; r++)); do
        UP[r]=$(((r - 1 + ROWS) % ROWS))
        DOWN[r]=$(((r + 1) % ROWS))
    done
    for ((c=0; c<COLS; c++)); do
        LEFT[c]=$(((c - 1 + COLS) % COLS))
        RIGHT[c]=$(((c + 1) % COLS))
    done
    
    local r c idx
    # Iteration: Nested loops to generate a 24-bit Truecolor gradient map
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            idx=$((r * COLS + c))
            local red=$(( r * 255 / ROWS ))
            local green=$(( 255 - (c * 255 / COLS) ))
            local blue=255
            printf -v COLOR_GRID[idx] "\033[38;2;%d;%d;%dm" "$red" "$green" "$blue"
        done
    done
}

seed_grid() {
    local r=$((ROWS / 2))
    local c=$((COLS / 2))

    # Acorn
    # .O.....
    # ...O...
    # OO..OOO

    set_cell $r         $((c+1)) "$ALIVE"

    set_cell $((r+1))   $((c+3)) "$ALIVE"

    set_cell $((r+2))   $c        "$ALIVE"
    set_cell $((r+2))   $((c+1)) "$ALIVE"
    set_cell $((r+2))   $((c+4)) "$ALIVE"
    set_cell $((r+2))   $((c+5)) "$ALIVE"
    set_cell $((r+2))   $((c+6)) "$ALIVE"

    count_live_cells
}

    local r c idx val
    local RESET=$'\033[0m'
    local BOLD=$'\033[1m'
    local CYAN=$'\033[38;2;0;255;255m'
    local YELLOW=$'\033[38;2;255;255;0m'
    local GREEN=$'\033[38;2;0;255;0m'

    buf+="${BOLD}${CYAN}--- CONWAY'S GAME OF LIFE ---${RESET}"$'\n'
    
    local mode="RUNNING"
    [[ "$PAUSED" == "true" ]] && mode="PAUSED"
    
    local total_cells=$((ROWS * COLS))
    local density_val=$(( (LIVE_CELLS * 10000) / total_cells ))
    local density
    printf -v density "%d.%02d" $((density_val / 100)) $((density_val % 100))
    
    local stat_line
    printf -v stat_line "${BOLD}Gen: ${YELLOW}%-6d${RESET} | ${BOLD}Live: ${GREEN}%-6d (%s%%)${RESET} | ${BOLD}Size: ${CYAN}%dx%d${RESET} | ${BOLD}Mode: ${YELLOW}%-8s${RESET} | ${BOLD}Delay: ${CYAN}%-4s${RESET}\n" \
        "$GENERATION" "$LIVE_CELLS" "$density" "$COLS" "$ROWS" "$mode" "$DELAY"
    buf+="$stat_line"

    # Iteration: Nested loops to identify and render only changed cells (diff rendering)
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            idx=$((r * COLS + c))
            val=${curr[idx]}
            if (( val != rendered_grid[idx] )); then
                if (( val )); then
                    buf+=$'\033['"$((r+3))"';'"$((c+1))"'H'"${COLOR_GRID[idx]}${ALIVE}${RESET}"
                else
                    buf+=$'\033['"$((r+3))"';'"$((c+1))"'H'"${DEAD}"
                fi
                rendered_grid[idx]=$val
            fi
        done
    done
    
    buf+=$'\033['"$((ROWS+3))"';1H'"${BOLD}${YELLOW}"'Controls: [q]uit [p]ause [s]tep [+/-] speed'"${RESET}"'\n'
    
    printf "%s" "$buf"
}

main() {
    init_terminal
    get_term_size
    init_grid
    seed_grid
    
    # Iteration: Main execution loop that persists until the user quits
    while "$RUNNING"; do
        key=""
        if [[ "$PAUSED" == "true" || "$STEP_REQUESTED" == "true" || $(( GENERATION % RENDER_FREQ )) -eq 0 ]]; then
            render
        fi

        if read -r -t "$DELAY" -n 1 key; then
            case "$key" in
                q) RUNNING=false ;;
                p)
                    if [[ "$PAUSED" == "true" ]]; then
                        PAUSED=false
                    else
                        PAUSED=true
                    fi
                    ;;
                s) STEP_REQUESTED=true; PAUSED=true ;;
                +)
                    (( DELAY_MS -= 20 ))
                    [[ $DELAY_MS -lt 20 ]] && DELAY_MS=20
                    printf -v DELAY "%d.%02d" $((DELAY_MS / 1000)) $(((DELAY_MS % 1000) / 10))
                    ;;
                -)
                    (( DELAY_MS += 20 ))
                    [[ $DELAY_MS -gt 10000 ]] && DELAY_MS=10000
                    printf -v DELAY "%d.%02d" $((DELAY_MS / 1000)) $(((DELAY_MS % 1000) / 10))
                    ;;
            esac
        fi

        if [[ "$PAUSED" == "false" || "$STEP_REQUESTED" == "true" ]]; then
            update_grid
            STEP_REQUESTED=false
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
