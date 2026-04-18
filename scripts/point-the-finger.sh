#!/bin/bash

# ============================================================
# Usage: bash point_the_finger.sh -p <project_code>
# Example: bash point_the_finger.sh -p er01
# ============================================================

while getopts "p:" flag; do
    case "${flag}" in
        p) PROJECT_CODE=${OPTARG};;
        *) echo "Usage: bash point_the_finger.sh -p <project_code>"; exit 1;;
    esac
done

if [ -z "$PROJECT_CODE" ]; then
    echo "Error: No project code provided."
    echo "Usage: bash point_the_finger.sh -p <project_code>"
    exit 1
fi

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${CYAN}"
cat << 'EOF'
           ___________    ____
    ______/   \__//   \__/____\
  _/   \_/  :           //____\\
 /|      :  :  ..      /        \
| |     ::     ::      \        /
| |     :|     ||     \ \______/
| |     ||     ||      |\  /  |
 \|     ||     ||      |   / | \
  |     ||     ||      |  / /_\ \
  | ___ || ___ ||      | /  /    \
   \_-_/  \_-_/ | ____ |/__/      \
                _\_--_/    \      /
               /____             /
              /     \           /
              \______\_________/
EOF
echo -e "${NC}"

echo -e "${BOLD}  Point the Finger | Project: ${PROJECT_CODE} | $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ============================================================================"

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [1] COMPUTE USAGE THIS QUARTER${NC}"
echo -e "  Who is eating the allocation?\n"

NCI_RAW=$(nci_account -P ${PROJECT_CODE} -v 2>/dev/null)

# Extract only the main HPC usage section — stop before Cloud section
USAGE_SECTION=$(echo "$NCI_RAW" | awk '/^Usage Report/,/^Cloud/' | grep -v '^Cloud')

# Print grant/used/avail summary
echo -e "  ${BOLD}Project summary:${NC}"
echo "$USAGE_SECTION" | grep -E 'Grant|Used|Reserved|Avail' | \
    awk '{printf "  %-12s %s %s\n", $1, $2, $3}'

# Print per-user breakdown
echo ""
echo -e "  ${BOLD}$(printf "  %-12s %-12s %-12s\n" "User" "Used" "Reserved")${NC}"
echo -e "  $(printf '%0.s-' {1..40})"
echo "$USAGE_SECTION" | grep -E '^[a-z]{2,3}[0-9]{3,4}' | \
    awk '{printf "  %-12s %-12s %-12s\n", $1, $2" "$3, $4" "$5}'

# ------------------------------------------------------------
# Fetch files report once and reuse
FILES_RAW=$(nci-files-report -p ${PROJECT_CODE} 2>/dev/null)

SCRATCH_SCAN=$(echo "$FILES_RAW" | grep '^scratch' | head -1 | awk '{print $2}')
GDATA_SCAN=$(echo "$FILES_RAW"   | grep '^gdata'   | head -1 | awk '{print $2}')

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [2] SCRATCH USAGE BY USER (/scratch/${PROJECT_CODE})${NC}"
echo -e "  Who is hogging scratch space? (scan date: ${SCRATCH_SCAN})\n"

echo -e "  ${BOLD}$(printf "  %-12s %-12s %-10s\n" "User" "Space Used" "Files")${NC}"
echo -e "  $(printf '%0.s-' {1..40})"

echo "$FILES_RAW" | awk -v proj="$PROJECT_CODE" '
    $1=="scratch" && $3==proj {
        printf "  %-12s %-12s %-10s\n", $5, $6, $8
    }
' | sort -k2 -rh

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [3] GDATA USAGE BY USER (/g/data/${PROJECT_CODE})${NC}"
echo -e "  Who is hogging gdata space? (scan date: ${GDATA_SCAN})\n"

echo -e "  ${BOLD}$(printf "  %-12s %-12s %-10s\n" "User" "Space Used" "Files")${NC}"
echo -e "  $(printf '%0.s-' {1..40})"

echo "$FILES_RAW" | awk -v proj="$PROJECT_CODE" '
    $1=="gdata" && $3==proj {
        printf "  %-12s %-12s %-10s\n", $5, $6, $8
    }
' | sort -k2 -rh

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [4] STORAGE FILESYSTEM SUMMARY${NC}"
echo -e "  Overall scratch and gdata allocation for project\n"

echo -e "  ${BOLD}$(printf "  %-12s %-12s %-12s %-12s %-12s\n" "Filesystem" "Used" "iUsed" "Allocation" "iAllocation")${NC}"
echo -e "  $(printf '%0.s-' {1..65})"
echo "$NCI_RAW" | awk '
    /^Storage Usage Report/,/^=====/ {
        if ($1 ~ /^gdata|^scratch/) {
            printf "  %-12s %-6s %-6s %-6s %-12s %-6s %-6s\n", $1, $2, $3, $4, $5, $6, $7
        }
    }
'

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [5] CURRENTLY RUNNING JOBS${NC}"
echo -e "  Who is in the queue right now?\n"

echo -e "  ${BOLD}$(printf "%-15s %-12s %-8s %-6s %-10s %-10s %-s\n" "User" "Job ID" "State" "CPUs" "Memory" "Walltime" "Job Name")${NC}"
echo -e "  $(printf '%0.s-' {1..80})"

qstat -f 2>/dev/null | awk -v proj="$PROJECT_CODE" '
    /Job Id/       { jobid=$3 }
    /Job_Owner/    { split($3,a,"@"); user=a[1] }
    /job_state/    { state=$3 }
    /Resource_List.ncpus/    { cpus=$3 }
    /Resource_List.mem/      { mem=$3 }
    /Resource_List.walltime/ { wt=$3 }
    /Job_Name/     { name=$3 }
    /egroup/  && $3==proj {
        printf "  %-15s %-12s %-8s %-6s %-10s %-10s %-s\n", user, jobid, state, cpus, mem, wt, name
    }
'

# ------------------------------------------------------------
echo -e "\n  ============================================================================"
echo -e "  ${BOLD}Notes:${NC}"
echo -e "  ${YELLOW}>>>${NC} Compute usage updates in real time"
echo -e "  ${YELLOW}>>>${NC} Scratch storage scan date: ${SCRATCH_SCAN}"
echo -e "  ${YELLOW}>>>${NC} Gdata storage scan date:   ${GDATA_SCAN}"
echo -e "  ${YELLOW}>>>${NC} Storage figures may be up to 24 hours old"
echo -e "  ${YELLOW}>>>${NC} Talk to your project CI if allocation is being exhausted"
echo -e "  ${YELLOW}>>>${NC} Run ${CYAN}qstat -u <username>${NC} to see a specific user's jobs"
echo -e ""