#!/bin/bash
# Nyan Cat Progress Bar - Original Pop-Tart Cat

# Rainbow colors
RAINBOW=(
  '\033[1;31m' # Red
  '\033[1;33m' # Yellow
  '\033[1;32m' # Green
  '\033[1;36m' # Cyan
  '\033[1;34m' # Blue
  '\033[1;35m' # Magenta
)
NC='\033[0m'
BOLD='\033[1m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
DIM='\033[2m'

# Nyan Cat Progress Bar
nyan_progress() {
  local current=$1
  local total=$2

  local percentage=$((current * 100 / total))

  # Build rainbow trail
  local trail=""
  local trail_length=$((percentage / 5))  # Max 20 blocks at 100%

  # `i` is local: bash scopes dynamically, so an undeclared loop variable here
  # would overwrite the loop variable of whatever called this.
  local i
  for i in $(seq 1 $trail_length); do
    local color_idx=$(((i - 1) % 6))
    trail="${trail}${RAINBOW[$color_idx]}━${NC}"
  done

  # Nyan Cat sprite (compact single line)
  local nyan="${YELLOW}[${NC}${MAGENTA}=${NC}${BOLD}${WHITE}^ᴥ^${NC}${MAGENTA}=${NC}${YELLOW}]${NC}${MAGENTA}<${NC}"

  # Sparkles
  local sparkle=""
  if [ $((current % 3)) -eq 0 ]; then
    sparkle=" ${YELLOW}✨${NC}"
  fi

  # Print progress bar with start/end markers
  echo -ne "\r${DIM}|${NC}${trail}${nyan}${sparkle}  ${BOLD}${CYAN}${percentage}%${NC} ${DIM}(${current}/${total}) |${NC}   "
}

# Demo the progress bar
if [ "$1" = "demo" ]; then
  echo ""
  echo "Nyan Cat Progress Bar Demo:"
  echo ""

  for i in $(seq 0 100); do
    nyan_progress $i 100
    sleep 0.05
  done

  echo ""
  echo ""
  echo "✅ Demo complete!"
fi

# Export function for use in other scripts
export -f nyan_progress
