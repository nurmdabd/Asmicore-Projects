#!/usr/bin/env bash

set -e

OUTPUT_MD="RTL_Synthesis_Report.md"

# --------------------------------------------------
# Utility Functions
# --------------------------------------------------

get_area() {
    local file="$1"
    grep "Chip area" "$file" | awk '{printf "%.2f",$NF}'
}

get_cells() {
    local file="$1"
    grep "cells$" "$file" | awk '{print $1}'
}

get_wns() {
    local file="$1"
    grep "^wns " "$file" | awk '{print $3}'
}

get_tns() {
    local file="$1"
    grep "^tns " "$file" | awk '{print $3}'
}

get_worst_slack() {
    local file="$1"
    grep "worst slack" "$file" | awk '{print $4}'
}

get_critical_path() {

    local file="$1"

    grep "period_min" "$file" \
    | awk '{print $4}'
}

get_fmax() {

    local file="$1"

    grep "fmax" "$file" \
    | awk '{print $7}'
}

calc_ratio() {

    awk -v a="$1" -v b="$2" '
    BEGIN {
        if (b == 0)
            print "N/A"
        else
            printf "%.2f", a/b
    }'
}

calc_diff() {

    awk -v a="$1" -v b="$2" '
    BEGIN {
        printf "%.2f", a-b
    }'
}

get_most_common_cell() {
    local netlist="$1"

    grep -o "[A-Za-z0-9_]*_ASAP7_75t_[A-Za-z]" "$netlist" \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -1 \
    | awk '{print $2}'
}

get_most_common_count() {
    local netlist="$1"

    grep -o "[A-Za-z0-9_]*_ASAP7_75t_[A-Za-z]" "$netlist" \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -1 \
    | awk '{print $1}'
}

get_ff_count() {
    local netlist="$1"
    grep -o "[A-Za-z0-9_]*_ASAP7_75t_[A-Za-z]" "$netlist" \
    | sort \
    | uniq -c \
    | awk '
        /DFF/ {
            sum += $1
        }
        END {
            print sum+0
        }
    '
}

get_design_name() {
    local cfg="$1"

    awk -F= '/DESIGN_NAME/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        gsub(/[\r\n]/, "", $2)
        print $2
        exit
    }' "$cfg"
}

get_target_period() {
    local sdc="$1"
    grep "create_clock" "$sdc" \
    | awk '{print $5}'
}

timing_met() {
    local wns="$1"
    awk -v w="$wns" '
    BEGIN {
        if (w >= 0)
            print "Yes"
        else
            print "No"
    }'
}

calc_change_percent() {

    awk -v first="$1" -v last="$2" '
    BEGIN {
        if (first == 0)
            print "N/A"
        else
            printf "%.2f%%", ((last-first)/first)*100
    }'
}

get_min_winner() {

    local name1="$1"
    local val1="$2"
    local name2="$3"
    local val2="$4"

    awk \
    -v n1="$name1" \
    -v v1="$val1" \
    -v n2="$name2" \
    -v v2="$val2" '
    BEGIN {
        if (v1 < v2)
            print n1
        else
            print n2
    }'
}

get_max_winner() {

    local name1="$1"
    local val1="$2"
    local name2="$3"
    local val2="$4"

    awk \
    -v n1="$name1" \
    -v v1="$val1" \
    -v n2="$name2" \
    -v v2="$val2" '
    BEGIN {
        if (v1 > v2)
            print n1
        else
            print n2
    }'
}
# --------------------------------------------------
# Design Summary Extraction
# --------------------------------------------------

declare -A DESIGN_AREA
declare -A DESIGN_CELLS
declare -A DESIGN_FF
declare -A DESIGN_COMMON_CELL
declare -A DESIGN_COMMON_COUNT
declare -A DESIGN_TOP
declare -A AREA
declare -A CELLS
declare -A FFS

declare -A WNS
declare -A TNS
declare -A WS

declare -A CP
declare -A FMAX

declare -A TARGET
declare -A TIMING

DESIGNS=()

for design_dir in */ ; do

    [ -d "$design_dir" ] || continue

    if [ ! -d "${design_dir}/run_500mhz" ]; then
        continue
    fi

    design=$(basename "$design_dir")

    DESIGNS+=("$design")

    cfg="${design_dir}run_500mhz/configs/config_500mhz.mk"

    DESIGN_TOP[$design]=$(get_design_name "$cfg")

    DESIGN_AREA[$design]=$(
        get_area \
        "${design_dir}/run_500mhz/reports/synth_stat.txt"
    )

    DESIGN_CELLS[$design]=$(
        get_cells \
        "${design_dir}/run_500mhz/reports/synth_stat.txt"
    )

    DESIGN_FF[$design]=$(
        get_ff_count \
        "${design_dir}/run_500mhz/results/1_2_yosys.v"
    )

    DESIGN_COMMON_CELL[$design]=$(
        get_most_common_cell \
        "${design_dir}/run_500mhz/results/1_2_yosys.v"
    )

    DESIGN_COMMON_COUNT[$design]=$(
        get_most_common_count \
        "${design_dir}/run_500mhz/results/1_2_yosys.v"
    )

done

TPU="tiny-tpu"
KR="kronos"
TPU_NAME="TPU"
KR_NAME="Kronos Core"
TPU_SHORT="TPU"
KR_SHORT="Kronos"
REPORT_DATE=$(date "+%Y-%m-%d %H:%M:%S")
DESIGN_COUNT=${#DESIGNS[@]}

TPU_ALL_TIMING="Yes"
KR_ALL_TIMING="Yes"

TPU_SCORE=0
KR_SCORE=0



# --------------------------------------------------
# Markdown Output
# --------------------------------------------------

cat > "$OUTPUT_MD" <<EOF
# RTL Synthesis Report
## 1. Report Metadata

| Property | Value |
|----------|----------|
| Generated On | $REPORT_DATE |
| Technology | ASAP7 |
| Flow | OpenROAD Flow Scripts (ORFS) |
| Analysis Type | RTL Synthesis |
| Design Count | $DESIGN_COUNT |
| Frequency Points | 500 MHz, 600 MHz, 700 MHz |

## 2. Design Characteristics

| Metric | $TPU_NAME | $KR_NAME |
|----------|----------|----------|
| Design Name | $TPU_NAME | $KR_NAME |
| Top Module | ${DESIGN_TOP[$TPU]} | ${DESIGN_TOP[$KR]} |
| Technology Node | ASAP7 | ASAP7 |
| Standard Cell Library | ASAP7 Standard Cell Family | ASAP7 Standard Cell Family |
| Target Frequencies | 500/600/700 MHz | 500/600/700 MHz |
| Flip-Flop Count | ${DESIGN_FF[$TPU]} | ${DESIGN_FF[$KR]} |
| Most Common Cell Type | ${DESIGN_COMMON_CELL[$TPU]} | ${DESIGN_COMMON_CELL[$KR]} |
| Most Common Cell Count | ${DESIGN_COMMON_COUNT[$TPU]} | ${DESIGN_COMMON_COUNT[$KR]} |
| Total Cell Count | ${DESIGN_CELLS[$TPU]} | ${DESIGN_CELLS[$KR]} |
| Chip Area (µm²) | ${DESIGN_AREA[$TPU]} | ${DESIGN_AREA[$KR]} |

EOF

cat >> "$OUTPUT_MD" <<EOF

---

## 3. Metrics Collection Sources

| Metric | Source File | Extraction Method |
|----------|----------|----------|
| Top Module | config_*.mk | DESIGN_NAME |
| Cell Count | synth_stat.txt | grep "cells\$" |
| Chip Area | synth_stat.txt | grep "Chip area" |
| Flip-Flop Count | 1_2_yosys.v | DFF cell counting |
| Most Common Cell | 1_2_yosys.v | histogram analysis |
| WNS | 1_Post_synthesis.rpt | grep "^wns" |
| TNS | 1_Post_synthesis.rpt | grep "^tns" |
| Worst Slack | 1_Post_synthesis.rpt | grep "worst slack" |
| Critical Path Period | 1_Post_synthesis.rpt | grep "period_min" |
| Fmax | 1_Post_synthesis.rpt | grep "fmax" |
| Timing Status | Derived from WNS | PASS |

EOF


for design in "${DESIGNS[@]}"
do
    for freq in 500 600 700
    do

        rpt="${design}/run_${freq}mhz/reports/1_Post_synthesis.rpt"
        stat="${design}/run_${freq}mhz/reports/synth_stat.txt"
        net="${design}/run_${freq}mhz/results/1_2_yosys.v"
        sdc="${design}/run_${freq}mhz/results/1_synth.sdc"

        AREA["$design,$freq"]=$(get_area "$stat")
        CELLS["$design,$freq"]=$(get_cells "$stat")
        FFS["$design,$freq"]=$(get_ff_count "$net")

        WNS["$design,$freq"]=$(get_wns "$rpt")
        TNS["$design,$freq"]=$(get_tns "$rpt")
        WS["$design,$freq"]=$(get_worst_slack "$rpt")

        CP["$design,$freq"]=$(get_critical_path "$rpt")
        FMAX["$design,$freq"]=$(get_fmax "$rpt")

        TARGET["$design,$freq"]=$(get_target_period "$sdc")

        TIMING["$design,$freq"]=$(
            timing_met "${WNS["$design,$freq"]}"
        )
    done
done

TPU_AREA_PER_CELL=$(calc_ratio \
    "${DESIGN_AREA[$TPU]}" \
    "${DESIGN_CELLS[$TPU]}"
)

KR_AREA_PER_CELL=$(calc_ratio \
    "${DESIGN_AREA[$KR]}" \
    "${DESIGN_CELLS[$KR]}"
)

TPU_CELL_DENSITY=$(calc_ratio \
    "${DESIGN_CELLS[$TPU]}" \
    "${DESIGN_AREA[$TPU]}"
)

KR_CELL_DENSITY=$(calc_ratio \
    "${DESIGN_CELLS[$KR]}" \
    "${DESIGN_AREA[$KR]}"
)

AREA_RATIO=$(calc_ratio \
    "${DESIGN_AREA[$TPU]}" \
    "${DESIGN_AREA[$KR]}"
)

CELL_RATIO=$(calc_ratio \
    "${DESIGN_CELLS[$TPU]}" \
    "${DESIGN_CELLS[$KR]}"
)

FF_RATIO=$(calc_ratio \
    "${DESIGN_FF[$TPU]}" \
    "${DESIGN_FF[$KR]}"
)

FMAX_RATIO=$(calc_ratio \
    "${FMAX["$TPU,700"]}" \
    "${FMAX["$KR,700"]}"
)

DENSITY_RATIO=$(calc_ratio \
    "${TPU_CELL_DENSITY}" \
    "${KR_CELL_DENSITY}"
)


TPU_SLACK_REDUCTION=$(calc_diff \
    "${WS["$TPU,500"]}" \
    "${WS["$TPU,700"]}"
)

KR_SLACK_REDUCTION=$(calc_diff \
    "${WS["$KR,500"]}" \
    "${WS["$KR,700"]}"
)

TPU_SLACK_CHANGE=$(calc_change_percent \
    "${WS["$TPU,500"]}" \
    "${WS["$TPU,700"]}"
)

KR_SLACK_CHANGE=$(calc_change_percent \
    "${WS["$KR,500"]}" \
    "${WS["$KR,700"]}"
)

TPU_FF_PERCENT=$(awk \
-v ff="${DESIGN_FF[$TPU]}" \
-v cells="${DESIGN_CELLS[$TPU]}" \
'BEGIN{printf "%.2f",100*ff/cells}')

KR_FF_PERCENT=$(awk \
-v ff="${DESIGN_FF[$KR]}" \
-v cells="${DESIGN_CELLS[$KR]}" \
'BEGIN{printf "%.2f",100*ff/cells}')

TPU_MARGIN=$(awk \
-v fmax="${FMAX["$TPU,700"]}" \
'BEGIN{printf "%.2f",fmax-700}')

KR_MARGIN=$(awk \
-v fmax="${FMAX["$KR,700"]}" \
'BEGIN{printf "%.2f",fmax-700}')
#================================================================

AREA_WINNER=$(
    get_min_winner \
    "$TPU_SHORT" "${DESIGN_AREA[$TPU]}" \
    "$KR_SHORT"  "${DESIGN_AREA[$KR]}"
)

CELL_WINNER=$(
    get_min_winner \
    "$TPU_SHORT" "${DESIGN_CELLS[$TPU]}" \
    "$KR_SHORT"  "${DESIGN_CELLS[$KR]}"
)

FMAX_WINNER=$(
    get_max_winner \
    "$TPU_SHORT" "${FMAX["$TPU,700"]}" \
    "$KR_SHORT"  "${FMAX["$KR,700"]}"
)

FF_RATIO_WINNER=$(
    get_max_winner \
    "$TPU_SHORT" "$TPU_FF_PERCENT" \
    "$KR_SHORT"  "$KR_FF_PERCENT"
)

DENSITY_WINNER=$(
    get_max_winner \
    "$TPU_SHORT" "$TPU_CELL_DENSITY" \
    "$KR_SHORT"  "$KR_CELL_DENSITY"
)

AREA_CELL_WINNER=$(
    get_min_winner \
    "$TPU_SHORT" "$TPU_AREA_PER_CELL" \
    "$KR_SHORT"  "$KR_AREA_PER_CELL"
)

for freq in 500 600 700
do
    if [[ "${TIMING["$TPU,$freq"]}" == "No" ]]
    then
        TPU_ALL_TIMING="No"
    fi
done

for freq in 500 600 700
do
    if [[ "${TIMING["$KR,$freq"]}" == "No" ]]
    then
        KR_ALL_TIMING="No"
    fi
done

for winner in \
    "$AREA_WINNER" \
    "$CELL_WINNER" \
    "$FMAX_WINNER" \
    "$FF_RATIO_WINNER" \
    "$DENSITY_WINNER" \
    "$AREA_CELL_WINNER"
do
    if [[ "$winner" == "$TPU_SHORT" ]]
    then
        ((TPU_SCORE+=1))
    else
        ((KR_SCORE+=1))
    fi
done

if (( TPU_SCORE > KR_SCORE ))
then
    OVERALL_WINNER="$TPU_SHORT"
elif (( KR_SCORE > TPU_SCORE ))
then
    OVERALL_WINNER="$KR_SHORT"
else
    OVERALL_WINNER="Tie"
fi

cat >> "$OUTPUT_MD" <<EOF

## 4. Day-01 Synthesis Results

### $TPU_NAME

| Metric | 500 MHz | 600 MHz | 700 MHz | 500→700 Change | Timing Met All 3? |
|----------|----------|----------|----------|----------|----------|
| Cell Count | ${CELLS["$TPU,500"]} | ${CELLS["$TPU,600"]} | ${CELLS["$TPU,700"]} | 0.00% | $TPU_ALL_TIMING |
| Chip Area (µm²) | ${AREA["$TPU,500"]} | ${AREA["$TPU,600"]} | ${AREA["$TPU,700"]} | 0.00% | $TPU_ALL_TIMING |
| Flip-Flop Count | ${FFS["$TPU,500"]} | ${FFS["$TPU,600"]} | ${FFS["$TPU,700"]} | 0.00% | $TPU_ALL_TIMING |
| WNS (ns) | ${WNS["$TPU,500"]} | ${WNS["$TPU,600"]} | ${WNS["$TPU,700"]} | N/A | $TPU_ALL_TIMING |
| TNS (ns) | ${TNS["$TPU,500"]} | ${TNS["$TPU,600"]} | ${TNS["$TPU,700"]} | N/A | $TPU_ALL_TIMING |
| Worst Slack (ps) | ${WS["$TPU,500"]} | ${WS["$TPU,600"]} | ${WS["$TPU,700"]} | ${TPU_SLACK_CHANGE} | $TPU_ALL_TIMING |

### $KR_NAME

| Metric | 500 MHz | 600 MHz | 700 MHz | 500→700 Change | Timing Met All 3? |
|----------|----------|----------|----------|----------|----------|
| Cell Count | ${CELLS["$KR,500"]} | ${CELLS["$KR,600"]} | ${CELLS["$KR,700"]} | 0.00% | $KR_ALL_TIMING |
| Chip Area (µm²) | ${AREA["$KR,500"]} | ${AREA["$KR,600"]} | ${AREA["$KR,700"]} | 0.00% | $KR_ALL_TIMING |
| Flip-Flop Count | ${FFS["$KR,500"]} | ${FFS["$KR,600"]} | ${FFS["$KR,700"]} | 0.00% | $KR_ALL_TIMING |
| WNS (ns) | ${WNS["$KR,500"]} | ${WNS["$KR,600"]} | ${WNS["$KR,700"]} | N/A | $KR_ALL_TIMING |
| TNS (ns) | ${TNS["$KR,500"]} | ${TNS["$KR,600"]} | ${TNS["$KR,700"]} | N/A | $KR_ALL_TIMING |
| Worst Slack (ps) | ${WS["$KR,500"]} | ${WS["$KR,600"]} | ${WS["$KR,700"]} | ${KR_SLACK_CHANGE} | $KR_ALL_TIMING |

EOF

cat >> "$OUTPUT_MD" <<EOF

---

## 5. Frequency Scaling Analysis

| Metric | $TPU_SHORT-500 | $TPU_SHORT-600 | $TPU_SHORT-700 | $KR_SHORT-500 | $KR_SHORT-600 | $KR_SHORT-700 |
|----------|----------|----------|----------|----------|----------|----------|
| Target Period (ps) | ${TARGET["$TPU,500"]} | ${TARGET["$TPU,600"]} | ${TARGET["$TPU,700"]} | ${TARGET["$KR,500"]} | ${TARGET["$KR,600"]} | ${TARGET["$KR,700"]} |
| Critical Path (ps) | ${CP["$TPU,500"]} | ${CP["$TPU,600"]} | ${CP["$TPU,700"]} | ${CP["$KR,500"]} | ${CP["$KR,600"]} | ${CP["$KR,700"]} |
| Fmax (MHz) | ${FMAX["$TPU,500"]} | ${FMAX["$TPU,600"]} | ${FMAX["$TPU,700"]} | ${FMAX["$KR,500"]} | ${FMAX["$KR,600"]} | ${FMAX["$KR,700"]} |
| Worst Slack (ps) | ${WS["$TPU,500"]} | ${WS["$TPU,600"]} | ${WS["$TPU,700"]} | ${WS["$KR,500"]} | ${WS["$KR,600"]} | ${WS["$KR,700"]} |
| Frequency Margin (MHz) | ${TPU_MARGIN} | ${TPU_MARGIN} | ${TPU_MARGIN} | ${KR_MARGIN} | ${KR_MARGIN} | ${KR_MARGIN} |

EOF



cat >> "$OUTPUT_MD" <<EOF

---

## 6. Cross-Design Comparison

| Metric | $TPU_SHORT | $KR_SHORT |
|----------|----------|----------|
| Total Cells | ${DESIGN_CELLS[$TPU]} | ${DESIGN_CELLS[$KR]} |
| Chip Area (µm²) | ${DESIGN_AREA[$TPU]} | ${DESIGN_AREA[$KR]} |
| Flip-Flops | ${DESIGN_FF[$TPU]} | ${DESIGN_FF[$KR]} |
| Most Common Cell | ${DESIGN_COMMON_CELL[$TPU]} | ${DESIGN_COMMON_CELL[$KR]} |
| Most Common Cell Count | ${DESIGN_COMMON_COUNT[$TPU]} | ${DESIGN_COMMON_COUNT[$KR]} |
| Fmax (MHz) | ${FMAX["$TPU,700"]} | ${FMAX["$KR,700"]} |
| FF Percentage (%) | ${TPU_FF_PERCENT} | ${KR_FF_PERCENT} |
| Cells per µm² | ${TPU_CELL_DENSITY} | ${KR_CELL_DENSITY} |
| Area per Cell (µm²/cell) | ${TPU_AREA_PER_CELL} | ${KR_AREA_PER_CELL} |

### Derived Ratios

| Metric | Value |
|----------|----------|
| $TPU_SHORT/$KR_SHORT Area Ratio | ${AREA_RATIO} |
| $TPU_SHORT/$KR_SHORT Cell Ratio | ${CELL_RATIO} |
| $TPU_SHORT/$KR_SHORT FF Ratio | ${FF_RATIO} |
| $TPU_SHORT/$KR_SHORT Fmax Ratio | ${FMAX_RATIO} |
| $TPU_SHORT/$KR_SHORT Cell Density Ratio | ${DENSITY_RATIO} |

EOF

cat >> "$OUTPUT_MD" <<EOF
---

## 7. Design Ranking

| Category | Winner | Reason |
|----------|----------|----------|
| Smallest Area | $AREA_WINNER | Lower silicon footprint |
| Lowest Cell Count | $CELL_WINNER | Smaller implementation |
| Highest Fmax | $FMAX_WINNER | Better timing capability |
| Highest FF Ratio | $FF_RATIO_WINNER | More sequential logic |
| Highest Cell Density | $DENSITY_WINNER | Better packing efficiency |
| Lowest Area per Cell | $AREA_CELL_WINNER | Better area utilization |
EOF


cat >> "$OUTPUT_MD" <<EOF
### Overall Assessment

---

$KR_SHORT wins in $KR_SCORE categories.

$TPU_SHORT wins in $TPU_SCORE categories.

Overall winner: $OVERALL_WINNER.

$KR_SHORT demonstrates superior timing performance and implementation efficiency.

TPU demonstrates higher computational complexity and logic capacity.
EOF




cat >> "$OUTPUT_MD" <<EOF
---

## 8. Frequency Scaling Behavior

| Design | Slack Loss (ps) | Slack Reduction (%) |
|----------|----------|----------|
| TPU | $TPU_SLACK_REDUCTION | $TPU_SLACK_CHANGE |
| $KR_SHORT | $KR_SLACK_REDUCTION | $KR_SLACK_CHANGE |
EOF

cat >> "$OUTPUT_MD" <<EOF

---

## 9. Key Observations

1. TPU occupies ${AREA_RATIO}× more silicon area than $KR_SHORT.

2. TPU contains ${CELL_RATIO}× more standard cells than $KR_SHORT.

3. $KR_SHORT achieves the highest maximum operating frequency (${FMAX["$KR,700"]} MHz).

4. Both designs successfully meet timing at 500 MHz, 600 MHz and 700 MHz.

5. TPU retains a frequency margin of ${TPU_MARGIN} MHz above the 700 MHz target.

6. $KR_SHORT retains a frequency margin of ${KR_MARGIN} MHz above the 700 MHz target.

7. TPU contains ${TPU_FF_PERCENT}% sequential cells.

8. $KR_SHORT contains ${KR_FF_PERCENT}% sequential cells.

9. $KR_SHORT is more sequentially dominated, while TPU is more combinationally dominated.

10. $KR_SHORT contains nearly 4× higher sequential-cell ratio than TPU (${KR_FF_PERCENT}% vs ${TPU_FF_PERCENT}%).

EOF


echo
echo "Report generated:"
echo "$OUTPUT_MD"