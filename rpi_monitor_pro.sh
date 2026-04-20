#!/bin/bash

INTERVAL=${1:-2}

# ANSI Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

get_stats() { grep "^cpu" /proc/stat; }

while true; do
    PREV_STATS=$(get_stats)
    sleep 1
    CURR_STATS=$(get_stats)

    # 1. Hardware Metrics
    TEMP_RAW=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
    CLOCK_HZ=$(vcgencmd measure_clock arm | cut -d= -f2)
    CLOCK=$((CLOCK_HZ / 1000000))
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # 2. Logic for Temp Color
    # RPi5 starts throttling at 80-82°C
    if (( $(echo "$TEMP_RAW >= 75" | bc -l) )); then T_COL=$RED
    elif (( $(echo "$TEMP_RAW >= 60" | bc -l) )); then T_COL=$YELLOW
    else T_COL=$GREEN; fi

    # 3. Logic for Clock Color (Turbo vs Idle)
    if [ "$CLOCK" -ge 2400 ]; then C_COL=$RED
    elif [ "$CLOCK" -ge 1500 ]; then C_COL=$YELLOW
    else C_COL=$GREEN; fi

    clear
    echo -e "============================================"
    echo -e "    RPi 5 LIVE MONITOR (Ctrl+C to exit)     "
    echo -e "============================================"
    echo -e " Time:  $TIMESTAMP"
    echo -e " Temp:  ${T_COL}${TEMP_RAW}'C${NC}"
    echo -e " Clock: ${C_COL}${CLOCK} MHz${NC}"
    echo -e "--------------------------------------------"
    echo -e " CPU Core Usage:"

    # 4. Core Usage Logic
    for i in {0..3}; do
        P_LINE=$(echo "$PREV_STATS" | grep "cpu$i")
        C_LINE=$(echo "$CURR_STATS" | grep "cpu$i")
        read -r -a P_ARR <<< "$P_LINE"
        read -r -a C_ARR <<< "$C_LINE"

        P_IDLE=${P_ARR[4]}; C_IDLE=${C_ARR[4]}
        P_TOTAL=0; for v in "${P_ARR[@]:1:7}"; do P_TOTAL=$((P_TOTAL + v)); done
        C_TOTAL=0; for v in "${C_ARR[@]:1:7}"; do C_TOTAL=$((C_TOTAL + v)); done

        DIFF_IDLE=$((C_IDLE - P_IDLE))
        DIFF_TOTAL=$((C_TOTAL - P_TOTAL))
        USAGE=$((100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL))

        # Core Usage Color
        if [ "$USAGE" -ge 80 ]; then U_COL=$RED
        elif [ "$USAGE" -ge 50 ]; then U_COL=$YELLOW
        else U_COL=$GREEN; fi

        # Simple Progress Bar
        BAR_SIZE=$((USAGE / 5))
        BAR=$(printf "%${BAR_SIZE}s" | tr ' ' '#')
	
	printf "  ${U_COL}Core %d: [%-3d%%] [%-20s]${NC}\n" "$i" "$USAGE" "$BAR"
	#printf "  Core %d: %-15b [%-3d%%] [%-20s]\n" "$i" "${U_COL}" "$USAGE" "${BAR}"
    done
    echo -e "${NC}============================================"

    WAIT=$((INTERVAL - 1))
    [ $WAIT -gt 0 ] && sleep $WAIT
done
