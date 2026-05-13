# Bash Algorithms: Tower of Hanoi & Game of Life


This repository contains two terminal applications written in pure Bash: a **Tower of Hanoi** solver and **Conway's Game of Life**.

## 1. Tower of Hanoi (`towerofhanoi/hanoi.sh`)

The Tower of Hanoi is a classical mathematical puzzle consisting of three pegs and $n$ disks of different sizes. The objective is to move the entire stack to another peg, obeying the rule that no disk may be placed on top of a smaller disk.

### Theoretical Background
- **Optimality**: The minimum number of moves required to solve a Tower of Hanoi puzzle with $n$ disks is exactly $2^n - 1$.
- **Recursive Strategy**: The problem is naturally recursive. To move $n$ disks from Source to Target:
  1. Move $n-1$ disks from Source to Auxiliary.
  2. Move the largest disk from Source to Target.
  3. Move $n-1$ disks from Auxiliary to Target.
- **Iterative Pattern**: An iterative solution exists based on the parity of $n$, cycling the smallest disk in a fixed direction every odd move.
- **Gray Codes**: The move sequence for the three-peg puzzle is mathematically identical to a binary Gray code traversal.

### Implementation Features
- **Visual Solver**: A real-time TUI that renders the disks and pegs using ASCII/Unicode blocks.
- **Recursive Engine**: Implements the canonical recursive algorithm for optimal move sequences.

### Usage
```bash
bash towerofhanoi/hanoi.sh
```

---

## 2. Conway's Game of Life (`gameoflife/life.sh`)

Conway's Game of Life is a zero-player cellular automaton. It evolves on a 2D grid based on a set of simple rules (B3/S23) that can lead to surprisingly complex and Turing-complete behavior.

### Theoretical Background
- **Rules (B3/S23)**:
  - **Birth (B3)**: A dead cell with exactly 3 live neighbors becomes alive.
  - **Survival (S23)**: A live cell with 2 or 3 live neighbors stays alive.
  - **Death**: All other live cells die (underpopulation or overpopulation).
- **Pattern Classes**:
  - **Still Lifes**: Patterns that do not change (e.g., Block, Beehive).
  - **Oscillators**: Patterns that return to their initial state after a fixed number of generations (e.g., Blinker, Pulsar).
  - **Spaceships**: Patterns that translate themselves across the grid (e.g., Glider, LWSS).
  - **Methuselahs**: Small initial patterns that evolve for a long time before stabilizing (e.g., Acorn, R-pentomino).

### Implementation Features
- **High-Performance Engine**: Optimized for Bash using:
  - **Flat Integer Arrays**: Eliminates string manipulation overhead.
  - **Precomputed Neighbors**: Toroidal (wrap-around) topology with zero-cost modulo operations in the hot loop.
  - **Diff Rendering**: Only updates changed cells in the terminal, drastically reducing ANSI overhead.
- **Interactivity**: Real-time controls for pausing, single-stepping, and speed adjustment.

### Controls
- `[q]`: Quit
- `[p]`: Pause / Resume
- `[s]`: Single-step (when paused)
- `[+]`: Increase speed (decrease delay)
- `[-]`: Decrease speed (increase delay)

### Usage
```bash
bash gameoflife/life.sh
```

---

## Technical Requirements
- **Shell**: Bash 4.3+ (uses `namerefs` for array optimizations).
- **Terminal**: A modern terminal emulator supporting **Truecolor (24-bit RGB)** and **Unicode**.
- **Dependencies**: Pure Bash; no external utilities like `bc` or `sed` are required for the simulation loop.

## Challenge
Implementation developed for the RISC-V LFX coding challenge.
