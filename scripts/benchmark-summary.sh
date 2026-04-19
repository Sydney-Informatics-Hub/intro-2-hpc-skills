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
  ____  ____  ____    __    __    __    ___  ____  __  __  __  __ _  ___
 (  _ \(  _ \/ ___)  (  )  /  \  / _\  / __)(  __)(  )(  )(  )(  ( \/ __)
  )   / ) __/\___ \   )( (  O )/    \ ( (_ \ ) _)  )( )(  )( /    /( (_ \
 (__\_)(__)  (____/  (__) \__/ \_/\_/ \___/(____)(__(__)(__)\_)__) \___/
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
    "Log File" "Exit" "NCPUs" "Mem Req" "Mem Used" "Wall Req"