#!/bin/bash

# ============================================================
# Usage: bash gadi-stats.sh -p <project_code>
# Example: bash gadi-stats.sh -p c25
# ============================================================

# Parse flags
while getopts "p:" flag; do
    case "${flag}" in
        p) PROJECT_CODE=${OPTARG};;
        *) echo "Usage: bash gadi-stats.sh -p <project_code>"; exit 1;;
    esac
done

# Check project code was provided
if [ -z "$PROJECT_CODE" ]; then
    echo "Error: No project code provided."
    echo "Usage: bash gadi-stats.sh -p <project_code>"
    exit 1
fi

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Progress bar function
progress_bar() {
    local used=$1
    local total=$2
    local width=40

    used=$(echo "$used" | awk '{printf "%d", $1+0}' 2>/dev/null)
    total=$(echo "$total" | awk '{printf "%d", $1+0}' 2>/dev/null)

    if [ -z "$used" ] || [ -z "$total" ] || [ "$total" -eq 0 ] 2>/dev/null; then
        echo -e "${YELLOW}  [could not calculate usage]${NC}"
        return
    fi

    local pct=$((used * 100 / total))
    local filled=$((used * width / total))
    local empty=$((width - filled))
    local bar=$(printf "%${filled}s" | tr ' ' '#')
    local space=$(printf "%${empty}s" | tr ' ' '-')

    if [ $pct -ge 90 ]; then
        color=$RED
    elif [ $pct -ge 70 ]; then
        color=$YELLOW
    else
        color=$GREEN
    fi

    echo -e "  ${color}[${bar}${space}] ${pct}%${NC}"
}

# Warning function
warn() {
    echo -e "  ${RED}[!] WARNING: $1${NC}"
}

# OK function
ok() {
    echo -e "  ${GREEN}[ok] $1${NC}"
}

# Convert storage value to MiB integer. Accepts "22.07 TiB", "22.07T", "900G", etc.
to_mib() {
    echo "$1" | awk '{
        num  = $1
        unit = (NF >= 2) ? toupper($2) : toupper(substr($1, length($1)))
        if      (unit ~ /^T/) { printf "%d", num * 1024 * 1024 }
        else if (unit ~ /^G/) { printf "%d", num * 1024 }
        else if (unit ~ /^M/) { printf "%d", num }
        else if (unit ~ /^K/) { printf "%d", num / 1024 }
        else                  { printf "%d", num }
    }'
}

# Convert KSU/SU to raw number for progress bar
parse_su() {
    local val=$1
    if echo "$val" | grep -qi 'ksu'; then
        # KSU = thousands of SUs, multiply by 1000
        echo "$val" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 | awk '{printf "%d", $1 * 1000}'
    else
        echo "$val" | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 | awk '{printf "%d", $1}'
    fi
}

clear

echo -e "${CYAN}"
cat << 'EOF'
  ██████╗  █████╗ ██████╗ ██╗    ███████╗████████╗ █████╗ ████████╗███████╗
 ██╔════╝ ██╔══██╗██╔══██╗██║    ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██╔════╝
 ██║  ███╗███████║██║  ██║██║    ███████╗   ██║   ███████║   ██║   ███████╗
 ██║   ██║██╔══██║██║  ██║██║    ╚════██║   ██║   ██╔══██║   ██║   ╚════██║
 ╚██████╔╝██║  ██║██████╔╝██║    ███████║   ██║   ██║  ██║   ██║   ███████║
  ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝
EOF
echo -e "${NC}"

echo -e "${BOLD}  Gadi Storage Dashboard | Project: ${PROJECT_CODE} | $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ============================================================================"

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [1] HOME DIRECTORY${NC}"

QUOTA_RAW=$(quota -s 2>/dev/null)
HOME_LINE=$(echo "$QUOTA_RAW" | grep -E '[0-9]+[MG]' | head -1)

HOME_USED=$(echo "$HOME_LINE" | awk '{print $1}')
HOME_QUOTA=$(echo "$HOME_LINE" | awk '{print $2}')
HOME_FILES=$(echo "$HOME_LINE" | awk '{print $5}')
HOME_FILES_QUOTA=$(echo "$HOME_LINE" | awk '{print $6}')

HOME_USED_NUM=$(to_mib "$HOME_USED")
HOME_QUOTA_NUM=$(to_mib "$HOME_QUOTA")

if [ ! -z "$HOME_USED" ] && [ ! -z "$HOME_QUOTA" ]; then
    echo -e "  Space : ${BOLD}${HOME_USED}${NC} used of ${BOLD}${HOME_QUOTA}${NC}"
    echo -e "  Files : ${BOLD}${HOME_FILES}${NC} used of ${BOLD}${HOME_FILES_QUOTA}${NC}"
    progress_bar $HOME_USED_NUM $HOME_QUOTA_NUM
else
    warn "Could not parse home quota. Run 'quota -s' to check format."
fi

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [2] SCRATCH (/scratch/${PROJECT_CODE})${NC}"

# Dump lquota and show what we find for debugging
LQUOTA_RAW=$(lquota 2>/dev/null)
SCRATCH_LINE=$(echo "$LQUOTA_RAW" | grep -i "scratch" | grep -i "${PROJECT_CODE}" | head -1)

# If that fails try a looser match
if [ -z "$SCRATCH_LINE" ]; then
    SCRATCH_LINE=$(echo "$LQUOTA_RAW" | grep -i "scratch" | head -1)
fi

if [ ! -z "$SCRATCH_LINE" ]; then
    SCRATCH_USED=$(echo "$SCRATCH_LINE" | awk '{print $3, $4}')
    SCRATCH_QUOTA=$(echo "$SCRATCH_LINE" | awk '{print $5, $6}')
    SCRATCH_IUSED=$(echo "$SCRATCH_LINE" | awk '{print $9}')
    SCRATCH_IQUOTA=$(echo "$SCRATCH_LINE" | awk '{print $10}')
    SCRATCH_USED_NUM=$(to_mib "$SCRATCH_USED")
    SCRATCH_QUOTA_NUM=$(to_mib "$SCRATCH_QUOTA")
    echo -e "  Space  : ${BOLD}${SCRATCH_USED}${NC} used of ${BOLD}${SCRATCH_QUOTA}${NC}"
    progress_bar $SCRATCH_USED_NUM $SCRATCH_QUOTA_NUM
    echo -e "  Inodes : ${BOLD}${SCRATCH_IUSED}${NC} used of ${BOLD}${SCRATCH_IQUOTA}${NC}"
    progress_bar $SCRATCH_IUSED $SCRATCH_IQUOTA
else
    warn "No scratch quota found. Run 'lquota' to check format."
fi

# Scratch expiry — filter empty lines before counting
EXPIRY_COUNT=$(nci-file-expiry list-quarantined 2>/dev/null | grep -v '^[[:space:]]*$' | wc -l)
if [ "$EXPIRY_COUNT" -gt 0 ]; then
    warn "${EXPIRY_COUNT} files on scratch are at risk of auto-deletion"
    echo -e "  ${YELLOW}  Run: nci-file-expiry list-quarantined${NC}"
else
    ok "No files at risk of expiry"
fi

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [3] GDATA (/g/data/${PROJECT_CODE})${NC}"

GDATA_LINE=$(echo "$LQUOTA_RAW" | grep -i "gdata" | grep -i "${PROJECT_CODE}" | head -1)

# Looser match fallback
if [ -z "$GDATA_LINE" ]; then
    GDATA_LINE=$(echo "$LQUOTA_RAW" | grep -i "gdata" | head -1)
fi

if [ ! -z "$GDATA_LINE" ]; then
    GDATA_USED=$(echo "$GDATA_LINE" | awk '{print $3, $4}')
    GDATA_QUOTA=$(echo "$GDATA_LINE" | awk '{print $5, $6}')
    GDATA_IUSED=$(echo "$GDATA_LINE" | awk '{print $9}')
    GDATA_IQUOTA=$(echo "$GDATA_LINE" | awk '{print $10}')
    GDATA_USED_NUM=$(to_mib "$GDATA_USED")
    GDATA_QUOTA_NUM=$(to_mib "$GDATA_QUOTA")
    echo -e "  Space  : ${BOLD}${GDATA_USED}${NC} used of ${BOLD}${GDATA_QUOTA}${NC}"
    progress_bar $GDATA_USED_NUM $GDATA_QUOTA_NUM
    echo -e "  Inodes : ${BOLD}${GDATA_IUSED}${NC} used of ${BOLD}${GDATA_IQUOTA}${NC}"
    progress_bar $GDATA_IUSED $GDATA_IQUOTA
else
    warn "No gdata quota found. Run 'lquota' to check format."
fi

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [4] COMPUTE ALLOCATION${NC}"

SU_INFO=$(nci_account -P ${PROJECT_CODE} -v 2>/dev/null)

# Parse grant and used — handle both SU and KSU
GRANT_RAW=$(echo "$SU_INFO" | grep -i "grant" | head -1 | awk '{print $2, $3}')
USED_RAW=$(echo "$SU_INFO"  | grep -i "used"  | head -1 | awk '{print $2, $3}')
AVAIL_RAW=$(echo "$SU_INFO" | grep -i "avail" | head -1 | awk '{print $2, $3}')

GRANT_NUM=$(parse_su "$GRANT_RAW")
USED_NUM=$(parse_su "$USED_RAW")

if [ ! -z "$GRANT_NUM" ] && [ ! -z "$USED_NUM" ]; then
    echo -e "  Grant     : ${BOLD}${GRANT_RAW}${NC}"
    echo -e "  Used      : ${BOLD}${USED_RAW}${NC}"
    echo -e "  Available : ${BOLD}${AVAIL_RAW}${NC}"
    progress_bar $USED_NUM $GRANT_NUM
    REMAINING=$((GRANT_NUM - USED_NUM))
    if [ $REMAINING -lt 1000 ]; then
        warn "Less than 1000 SUs remaining this quarter"
    else
        ok "${REMAINING} SUs remaining this quarter"
    fi
else
    warn "Could not parse SU allocation. Run 'nci_account -P ${PROJECT_CODE}' to check format."
fi
