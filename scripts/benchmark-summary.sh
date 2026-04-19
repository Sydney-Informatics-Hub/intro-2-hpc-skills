#!/bin/bash

# ============================================================
# Usage: bash collect_pbs_logs.sh -d <log_directory> -o <output_file>
# Example: bash collect_pbs_logs.sh -d PBS_logs -o benchmark_summary.txt
# Defaults: log directory = PBS_logs, output = benchmark_summary.txt
# ============================================================

while getopts "d:o:" flag; do
    case "${flag}" in
        d) LOG_DIR=${OPTARG};;
        o) OUTPUT=${OPTARG};;
        *) echo "Usage: bash collect_pbs_logs.sh -d <log_directory> -o <output_file>"; exit 1;;
    esac
done

# Defaults
LOG_DIR=${LOG_DIR:-PBS_logs}
OUTPUT=${OUTPUT:-benchmark_summary.txt}

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo -e "${RED}Error: Log directory '${LOG_DIR}' not found.${NC}"
    exit 1
fi

# Check there are .o files anywhere under the directory
O_FILES=$(find ${LOG_DIR} -name "*.o" 2>/dev/null)
if [ -z "$O_FILES" ]; then
    echo -e "${RED}Error: No .o log files found under '${LOG_DIR}'.${NC}"
    echo -e "${YELLOW}Searched recursively from: $(realpath ${LOG_DIR})${NC}"
    exit 1
fi

clear

echo -e "${CYAN}"
cat << 'EOF'

EOF
echo -e "${NC}"

echo -e "${BOLD}  PBS Log Summary | Directory: ${LOG_DIR} | $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "  ============================================================================"

# Write header to output file
cat > $OUTPUT << EOF
PBS Log Summary
Directory: ${LOG_DIR}
Generated: $(date '+%Y-%m-%d %H:%M:%S')
================================================================================
EOF

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [1] JOB SUMMARY TABLE${NC}\n"

HEADER=$(printf "  %-40s %-8s %-8s %-12s %-12s %-12s %-12s %-6s\n" \
    "Log File" "Exit" "NCPUs" "Mem Req" "Mem Used" "Wall Req" "Wall Used" "SUs")
echo -e "${BOLD}${HEADER}${NC}"
echo -e "  $(printf '%0.s-' {1..115})"

echo "$HEADER" >> $OUTPUT
printf '%0.s-' {1..115} >> $OUTPUT
echo "" >> $OUTPUT

for OFILE in $(find ${LOG_DIR} -name "*.o" | sort); do

    FILENAME=$(basename $OFILE)

    # Check file contains a resource usage block
    if ! grep -q "Resource Usage" $OFILE 2>/dev/null; then
        printf "  %-40s %-s\n" "$FILENAME" "no resource block found -- job may still be running"
        printf "  %-40s %-s\n" "$FILENAME" "no resource block found" >> $OUTPUT
        continue
    fi

    EXIT_STATUS=$(grep "Exit Status"      $OFILE | awk '{print $NF}')
    NCPUS=$(grep "NCPUs Requested"        $OFILE | awk '{print $3}')
    MEM_REQ=$(grep "Memory Requested"     $OFILE | awk '{print $3, $4}' | xargs)
    MEM_USED=$(grep "Memory Used"         $OFILE | awk '{print $NF}')
    WALL_REQ=$(grep "Walltime Requested"  $OFILE | awk '{print $3}')
    WALL_USED=$(grep "Walltime Used"      $OFILE | awk '{print $NF}')
    SUS=$(grep "Service Units"            $OFILE | awk '{print $NF}')

    if [ "$EXIT_STATUS" == "0" ]; then
        EXIT_COLOUR=$GREEN
    else
        EXIT_COLOUR=$RED
    fi

    printf "  %-40s ${EXIT_COLOUR}%-8s${NC} %-8s %-12s %-12s %-12s %-12s %-6s\n" \
        "$FILENAME" "$EXIT_STATUS" "$NCPUS" "$MEM_REQ" "$MEM_USED" "$WALL_REQ" "$WALL_USED" "$SUS"

    printf "  %-40s %-8s %-8s %-12s %-12s %-12s %-12s %-6s\n" \
        "$FILENAME" "$EXIT_STATUS" "$NCPUS" "$MEM_REQ" "$MEM_USED" "$WALL_REQ" "$WALL_USED" "$SUS" >> $OUTPUT

done

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [2] FAILED JOBS${NC}\n"
echo -e "\nFAILED JOBS\n" >> $OUTPUT

FAILED=0
for OFILE in $(find ${LOG_DIR} -name "*.o" | sort); do
    EXIT_STATUS=$(grep "Exit Status" $OFILE 2>/dev/null | awk '{print $NF}')
    if [ ! -z "$EXIT_STATUS" ] && [ "$EXIT_STATUS" != "0" ]; then
        FILENAME=$(basename $OFILE)
        EFILE="${OFILE%.o}.e"
        echo -e "  ${RED}[FAILED]${NC} ${FILENAME} (exit status: ${EXIT_STATUS})"
        echo "  [FAILED] ${FILENAME} (exit status: ${EXIT_STATUS})" >> $OUTPUT

        if [ -f "$EFILE" ] && [ -s "$EFILE" ]; then
            echo -e "  ${YELLOW}  Last 10 lines of stderr ($(basename $EFILE)):${NC}"
            echo "  Last 10 lines of stderr ($(basename $EFILE)):" >> $OUTPUT
            tail -n 10 $EFILE | while read line; do
                echo -e "    ${YELLOW}${line}${NC}"
                echo "    ${line}" >> $OUTPUT
            done
        fi
        echo ""
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -eq 0 ]; then
    echo -e "  ${GREEN}[ok] No failed jobs found${NC}"
    echo "  [ok] No failed jobs found" >> $OUTPUT
fi

# ------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}  [3] SPEEDUP SUMMARY${NC}\n"
echo -e "\nSPEEDUP SUMMARY\n" >> $OUTPUT

echo -e "  ${BOLD}$(printf "  %-8s %-14s %-10s %-12s\n" "NCPUs" "Walltime Used" "Speedup" "Efficiency")${NC}"
echo -e "  $(printf '%0.s-' {1..50})"
printf "  %-8s %-14s %-10s %-12s\n" "NCPUs" "Walltime Used" "Speedup" "Efficiency" >> $OUTPUT
printf '%0.s-' {1..50} >> $OUTPUT
echo "" >> $OUTPUT

declare -A WALL_SECONDS
declare -A WALL_LABELS

for OFILE in $(find ${LOG_DIR} -name "*.o" | sort); do
    WALL_USED=$(grep "Walltime Used"      $OFILE 2>/dev/null | awk '{print $NF}')
    NCPUS=$(grep "NCPUs Requested"        $OFILE 2>/dev/null | awk '{print $3}')
    EXIT_STATUS=$(grep "Exit Status"      $OFILE 2>/dev/null | awk '{print $NF}')

    if [ -z "$WALL_USED" ] || [ -z "$NCPUS" ] || [ "$EXIT_STATUS" != "0" ]; then
        continue
    fi

    SECONDS_VAL=$(echo $WALL_USED | awk -F: '{print ($1*3600)+($2*60)+$3}')
    WALL_SECONDS[$NCPUS]=$SECONDS_VAL
    WALL_LABELS[$NCPUS]=$WALL_USED
done

BASELINE_CPUS=$(echo "${!WALL_SECONDS[@]}" | tr ' ' '\n' | sort -n | head -1)
BASELINE_SECS=${WALL_SECONDS[$BASELINE_CPUS]}

if [ -z "$BASELINE_SECS" ]; then
    echo -e "  ${YELLOW}Not enough completed jobs to calculate speedup${NC}"
    echo "  Not enough completed jobs to calculate speedup" >> $OUTPUT
else
    for NCPUS in $(echo "${!WALL_SECONDS[@]}" | tr ' ' '\n' | sort -n); do
        SECS=${WALL_SECONDS[$NCPUS]}
        LABEL=${WALL_LABELS[$NCPUS]}
        SPEEDUP=$(awk "BEGIN {printf \"%.2f\", ${BASELINE_SECS}/${SECS}}")
        EFFICIENCY=$(awk "BEGIN {printf \"%.0f%%\", (${BASELINE_SECS}/${SECS}/${NCPUS})*100}")

        printf "  %-8s %-14s %-10s %-12s\n" "$NCPUS" "$LABEL" "${SPEEDUP}x" "$EFFICIENCY"
        printf "  %-8s %-14s %-10s %-12s\n" "$NCPUS" "$LABEL" "${SPEEDUP}x" "$EFFICIENCY" >> $OUTPUT
    done
fi

# ------------------------------------------------------------
echo -e "\n  ============================================================================"
echo -e "  ${GREEN}Report saved to: ${OUTPUT}${NC}\n"
echo -e "\n================================================================================" >> $OUTPUT
echo "End of report" >> $OUTPUT