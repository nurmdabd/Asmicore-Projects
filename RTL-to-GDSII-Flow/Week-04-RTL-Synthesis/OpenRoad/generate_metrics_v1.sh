#!/usr/bin/env bash
set -e
############################################################
# Required Folder Structure:
############################################################
# tiny-tpu-hardened
# ├── run_500mhz
# │   ├── reports
# │   │   ├── 1_Post_synthesis.rpt
# │   │   └── synth_stat.txt
# │   └── results
# │       └── clock_period.txt
# ├── run_600mhz
# │   ├── reports
# │   │   ├── 1_Post_synthesis.rpt
# │   │   └── synth_stat.txt
# │   └── results
# │       └── clock_period.txt
# └── run_700mhz
#     ├── reports
#     │   ├── 1_Post_synthesis.rpt
#     │   └── synth_stat.txt
#     └── results
#         └── clock_period.txt

############################################################
# DESIGN_DIR Selection
############################################################
DESIGN_DIR=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/tiny-tpu
# DESIGN_DIR=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/kronos

RTL_DIR="$DESIGN_DIR/rtl"

RUN1="$DESIGN_DIR/run_500mhz"
RUN2="$DESIGN_DIR/run_600mhz"
RUN3="$DESIGN_DIR/run_700mhz"

RUNS=("$RUN1" "$RUN2" "$RUN3")
FREQS=("500" "600" "700")

############################################################
# Manual Inputs
############################################################
LOGIC_DEPTH="⚠️Input Manually"
FEP="⚠️Input Manually"

############################################################
# Output Files
############################################################
OUT_MD="${DESIGN_DIR}_metrics.md"
OUT_CSV="${DESIGN_DIR}_metrics.csv"

rm -f "$OUT_MD"
rm -f "$OUT_CSV"

############################################################
# Helper Functions
############################################################
safe(){
[[ -z "$1" ]] && echo "N/A" || echo "$1"
}

percent(){
awk "BEGIN{
printf \"%.2f\",100*$1/$2
}"
}

scientific(){
awk "BEGIN{
printf \"%.8e\",$1
}"
}

############################################################
# Extraction Functions
############################################################

extract_clock(){
cat "$1/results/clock_period.txt" \
| awk '{printf "%.0f",$1}'
}

extract_top(){
grep "^===" \
"$1/reports/synth_stat.txt" \
| awk '{print $2}'
}

extract_rtl(){
find "$RTL_DIR" \
\( -name "*.v" -o -name "*.sv" \) \
| wc -l
}

extract_total(){
grep "cells$" \
"$1/reports/synth_stat.txt" \
| awk '{print $1}'
}

extract_seq(){
grep -E "DFF|SDFF|LATCH" \
"$1/reports/synth_stat.txt" \
| awk '{sum+=$1} END{print sum}'
}

extract_dff(){
grep -E "DFF|SDFF" \
"$1/reports/synth_stat.txt" \
| awk '{sum+=$1} END{print sum}'
}

extract_comb(){
TOTAL=$(extract_total "$1")
SEQ=$(extract_seq "$1")
echo $((TOTAL-SEQ))
}

extract_seqpercent(){
TOTAL=$(extract_total "$1")
SEQ=$(extract_seq "$1")
percent "$SEQ" "$TOTAL"
}

extract_seqarea(){
grep "used for sequential elements" \
"$1/reports/synth_stat.txt" \
| sed -E 's/.*\(([0-9.]+)%.*/\1/'
}

extract_area(){
grep "Chip area" \
"$1/reports/synth_stat.txt" \
| awk '{print $NF}'
}

extract_slack(){
grep "worst slack max" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '{print $NF}'
}

extract_wns(){
grep "wns max" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '{print $NF}'
}

extract_tns(){
grep "tns max" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '{print $NF}'
}

extract_period(){
grep "clk period_min" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '{print $4}'
}

extract_fmax(){
grep "clk period_min" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '{print $7}'
}

extract_pathgroup(){
grep "Path Group:" \
"$1/reports/1_Post_synthesis.rpt" \
| head -1 \
| awk '{print $3}'
}

extract_numgroups(){
grep "Path Group:" \
"$1/reports/1_Post_synthesis.rpt" \
| sort -u \
| wc -l
}

extract_maxpaths(){
grep -c "Path Type: max" \
"$1/reports/1_Post_synthesis.rpt"
}

extract_start(){
grep "Startpoint:" \
"$1/reports/1_Post_synthesis.rpt" \
| tail -1 \
| sed 's/Startpoint: //'
}

extract_end(){
grep "Endpoint:" \
"$1/reports/1_Post_synthesis.rpt" \
| tail -1 \
| sed 's/Endpoint: //'
}

############################################################
# Remaining Extraction Functions
############################################################

extract_largest_cell(){
sed -n '/Path Type: max/,/slack (MET)/p' \
"$1/reports/1_Post_synthesis.rpt" \
| grep "ASAP7" \
| sort -k4 -n \
| tail -1 \
| sed -E 's/.*\((.*)\).*/\1/'
}

extract_largest_delay(){
sed -n '/Path Type: max/,/slack (MET)/p' \
"$1/reports/1_Post_synthesis.rpt" \
| grep "ASAP7" \
| awk '{print $4}' \
| sort -n \
| tail -1
}

extract_arrival(){
grep "data arrival time" \
"$1/reports/1_Post_synthesis.rpt" \
| awk '$1>0 {print $1}' \
| sort -n \
| tail -1
}

extract_setup(){
grep "library setup time" \
"$1/reports/1_Post_synthesis.rpt" \
| head -1 \
| awk '{print -$1}'
}

extract_vt(){
echo "RVT"
}

extract_rvt(){
echo "100"
}

extract_internal(){
grep "^Total" \
"$1/reports/1_Post_synthesis.rpt" \
| tail -1 \
| awk '{print $2}'
}

extract_switch(){
grep "^Total" \
"$1/reports/1_Post_synthesis.rpt" \
| tail -1 \
| awk '{print $3}'
}

extract_leakage(){
grep -A15 "report_power" \
"$1/reports/1_Post_synthesis.rpt" \
| grep "^Total" \
| tail -1 \
| awk '{print $4}'
}

extract_totalpower(){
grep -A15 "report_power" \
"$1/reports/1_Post_synthesis.rpt" \
| grep "^Total" \
| tail -1 \
| awk '{print $5}'
}

extract_seqcontrib(){
grep -A15 "report_power" \
"$1/reports/1_Post_synthesis.rpt" \
| grep "^Sequential" \
| awk '{print $6}' \
| tr -d '%'
}

extract_combcontrib(){
grep -A15 "report_power" \
"$1/reports/1_Post_synthesis.rpt" \
| grep "^Combinational" \
| awk '{print $6}' \
| tr -d '%'
}

extract_buf(){
grep "BUF" \
"$1/reports/synth_stat.txt" \
| awk '{sum+=$1} END{print sum}'
}

extract_inv(){
grep "INV" \
"$1/reports/synth_stat.txt" \
| awk '{sum+=$1} END{print sum}'
}

extract_arith(){
egrep "FAx|HAxp|MAJ" \
"$1/reports/synth_stat.txt" \
| awk '{sum+=$1} END{print sum}'
}

extract_avgarea(){
AREA=$(extract_area "$1")
CELL=$(extract_total "$1")
awk "BEGIN{printf \"%.4f\",$AREA/$CELL}"
}

extract_density(){
AREA=$(extract_area "$1")
POWER=$(extract_totalpower "$1")
awk "BEGIN{printf \"%.8e\",$POWER/$AREA}"
}

extract_elapsed_time(){
grep -m1 "Elapsed time:" $1/logs/1_2_yosys.log \
| sed -E 's/.*Elapsed time: ([0-9]+:[0-9]+\.[0-9]+).*/\1/'
}

extract_peak_memory_usage(){
grep -m1 "Peak memory:" $1/logs/1_2_yosys.log \
| awk '
{
for(i=1;i<=NF;i++)
if($i=="memory:")
printf "%.2f\n",$(i+1)/1024
}'
}

############################################################
# Arrays
############################################################

CLOCK=()
TOP=()
RTL=()

TOTAL=()
COMB=()
SEQ=()
DFF=()

SEQP=()
SEQA=()

AREA=()

SLACK=()
WNS=()
TNS=()

PERIOD=()
FMAX=()

GROUP=()
NGROUP=()

MAXPATH=()

START=()
ENDPT=()

LTYPE=()
LDELAY=()

ARR=()
SETUP=()

VT=()
RVT=()

IPWR=()
SPWR=()
LPWR=()
TPWR=()

SEQC=()
COMBC=()

BUF=()
INV=()
ARITH=()

AVGAREA=()
DENSITY=()

ELAPSED_TIME=()
PEAK_MEMORY_USAGE=()

############################################################
# Collect Metrics
############################################################

for RUN in "${RUNS[@]}"
do

CLOCK+=("$(extract_clock "$RUN")")
TOP+=("$(extract_top "$RUN")")
RTL+=("$(extract_rtl)")

TOTAL+=("$(extract_total "$RUN")")
COMB+=("$(extract_comb "$RUN")")
SEQ+=("$(extract_seq "$RUN")")
DFF+=("$(extract_dff "$RUN")")

SEQP+=("$(extract_seqpercent "$RUN")")
SEQA+=("$(extract_seqarea "$RUN")")

AREA+=("$(extract_area "$RUN")")

SLACK+=("$(extract_slack "$RUN")")
WNS+=("$(extract_wns "$RUN")")
TNS+=("$(extract_tns "$RUN")")

PERIOD+=("$(extract_period "$RUN")")
FMAX+=("$(extract_fmax "$RUN")")

GROUP+=("$(extract_pathgroup "$RUN")")
NGROUP+=("$(extract_numgroups "$RUN")")

MAXPATH+=("$(extract_maxpaths "$RUN")")

START+=("$(extract_start "$RUN")")
ENDPT+=("$(extract_end "$RUN")")

LTYPE+=("$(extract_largest_cell "$RUN")")
LDELAY+=("$(extract_largest_delay "$RUN")")

ARR+=("$(extract_arrival "$RUN")")
SETUP+=("$(extract_setup "$RUN")")

VT+=("$(extract_vt)")
RVT+=("$(extract_rvt)")

IPWR+=("$(extract_internal "$RUN")")
SPWR+=("$(extract_switch "$RUN")")
LPWR+=("$(extract_leakage "$RUN")")
TPWR+=("$(extract_totalpower "$RUN")")

SEQC+=("$(extract_seqcontrib "$RUN")")
COMBC+=("$(extract_combcontrib "$RUN")")

BUF+=("$(extract_buf "$RUN")")
INV+=("$(extract_inv "$RUN")")
ARITH+=("$(extract_arith "$RUN")")

AVGAREA+=("$(extract_avgarea "$RUN")")
DENSITY+=("$(extract_density "$RUN")")

ELAPSED_TIME+=("$(extract_elapsed_time "$RUN")")
PEAK_MEMORY_USAGE+=("$(extract_peak_memory_usage "$RUN")")

done

############################################################
# Markdown Initialization
############################################################

cat > "$OUT_MD" << EOF
# ${DESIGN_DIR} Metrics Summary

| Count | Metric | 500 MHz | 600 MHz | 700 MHz |
|:---:|---|---|---|---|
EOF

############################################################
# CSV Initialization
############################################################

echo "Count,Metric,500MHz,600MHz,700MHz" \
> "$OUT_CSV"

############################################################
# Metric Writer
############################################################

write_metric(){
IDX="$1"
NAME="$2"
A="$3"
B="$4"
C="$5"

printf "| %2d | %-30s | %s | %s | %s |\n" \
"$IDX" "$NAME" "$A" "$B" "$C" \
>> "$OUT_MD"

echo "$IDX,\"$NAME\",\"$A\",\"$B\",\"$C\"" \
>> "$OUT_CSV"

printf "%2d. %-30s : %-20s %-20s %-20s\n" \
"$IDX" "$NAME" "$A" "$B" "$C"
}

############################################################
# Terminal Header
############################################################

echo
echo "=============================================================="
echo "               ${DESIGN_DIR} Metrics Summary"
echo "=============================================================="
echo

############################################################
# Populate Table
############################################################

write_metric 1  "Clock Period (ps)"                     "${CLOCK[0]}" "${CLOCK[1]}" "${CLOCK[2]}"
write_metric 2  "Top Module"                            "${TOP[0]}" "${TOP[1]}" "${TOP[2]}"
write_metric 3  "RTL Files"                             "${RTL[0]}" "${RTL[1]}" "${RTL[2]}"

write_metric 4  "Total Cells"                           "${TOTAL[0]}" "${TOTAL[1]}" "${TOTAL[2]}"
write_metric 5  "Combinational Cells"                   "${COMB[0]}" "${COMB[1]}" "${COMB[2]}"
write_metric 6  "Sequential Cells"                      "${SEQ[0]}" "${SEQ[1]}" "${SEQ[2]}"
write_metric 7  "DFF Count"                             "${DFF[0]}" "${DFF[1]}" "${DFF[2]}"

write_metric 8  "Sequential Cell %"                     "${SEQP[0]}%" "${SEQP[1]}%" "${SEQP[2]}%"
write_metric 9  "Sequential Area (%)"                   "${SEQA[0]}%" "${SEQA[1]}%" "${SEQA[2]}%"

write_metric 10 "Chip Area (um2)"                       "${AREA[0]}" "${AREA[1]}" "${AREA[2]}"

write_metric 11 "Worst Slack"                           "${SLACK[0]}" "${SLACK[1]}" "${SLACK[2]}"
write_metric 12 "WNS (ps)"                              "${WNS[0]}" "${WNS[1]}" "${WNS[2]}"
write_metric 13 "TNS (ps)"                              "${TNS[0]}" "${TNS[1]}" "${TNS[2]}"
write_metric 14 "FEP"                                   "$FEP" "$FEP" "$FEP"

write_metric 15 "Minimum Period (ps)"                   "${PERIOD[0]}" "${PERIOD[1]}" "${PERIOD[2]}"
write_metric 16 "Estimated Fmax (MHz)"                  "${FMAX[0]}" "${FMAX[1]}" "${FMAX[2]}"

write_metric 17 "Path Groups  (⚠️DCheck)"               "${GROUP[0]}" "${GROUP[1]}" "${GROUP[2]}"
write_metric 18 "Number of Path Groups (⚠️DCheck)"      "${NGROUP[0]}" "${NGROUP[1]}" "${NGROUP[2]}"
write_metric 19 "Most Critical Path Group"              "${GROUP[0]}" "${GROUP[1]}" "${GROUP[2]}"

write_metric 20 "Number of Max Paths"                   "${MAXPATH[0]}" "${MAXPATH[1]}" "${MAXPATH[2]}"

write_metric 21 "Start Point"                           "${START[0]}" "${START[1]}" "${START[2]}"
write_metric 22 "End Point"                             "${ENDPT[0]}" "${ENDPT[1]}" "${ENDPT[2]}"

write_metric 23 "Critical Path Logic Depth"             "${LOGIC_DEPTH}" "${LOGIC_DEPTH}" "${LOGIC_DEPTH}"

write_metric 24 "Largest Cell Type (⚠️DCheck)"          "${LTYPE[0]}" "${LTYPE[1]}" "${LTYPE[2]}"
write_metric 25 "Largest Cell Delay (ps) (⚠️DCheck)"    "${LDELAY[0]}" "${LDELAY[1]}" "${LDELAY[2]}"

write_metric 26 "Data Arrival Time (ps)"                "${ARR[0]}" "${ARR[1]}" "${ARR[2]}"
write_metric 27 "Setup Time (ps)"                       "${SETUP[0]}" "${SETUP[1]}" "${SETUP[2]}"

write_metric 28 "VT Type"                               "${VT[0]}" "${VT[1]}" "${VT[2]}"
write_metric 29 "RVT Percentage"                        "${RVT[0]}%" "${RVT[1]}%" "${RVT[2]}%"

write_metric 30 "Internal Power (W)"                    "${IPWR[0]}" "${IPWR[1]}" "${IPWR[2]}"
write_metric 31 "Switching Power (W)"                   "${SPWR[0]}" "${SPWR[1]}" "${SPWR[2]}"
write_metric 32 "Leakage Power (W)"                     "${LPWR[0]}" "${LPWR[1]}" "${LPWR[2]}"
write_metric 33 "Total Power (W)"                       "${TPWR[0]}" "${TPWR[1]}" "${TPWR[2]}"

write_metric 34 "Sequential Contribution (%)"           "${SEQC[0]}%" "${SEQC[1]}%" "${SEQC[2]}%"
write_metric 35 "Combinational Contribution (%)"        "${COMBC[0]}%" "${COMBC[1]}%" "${COMBC[2]}%"

write_metric 36 "Buffer Count"                          "${BUF[0]}" "${BUF[1]}" "${BUF[2]}"
write_metric 37 "Inverter Count"                        "${INV[0]}" "${INV[1]}" "${INV[2]}"
write_metric 38 "Arithmetic Cell Count"                 "${ARITH[0]}" "${ARITH[1]}" "${ARITH[2]}"

write_metric 39 "Average Cell Area"                     "${AVGAREA[0]}" "${AVGAREA[1]}" "${AVGAREA[2]}"
write_metric 40 "Power Density"                         "${DENSITY[0]}" "${DENSITY[1]}" "${DENSITY[2]}"

write_metric 41 "Elapsed Time (Min:Sec)"                "${ELAPSED_TIME[0]}" "${ELAPSED_TIME[1]}" "${ELAPSED_TIME[2]}"
write_metric 42 "Peak Memory Usage (MB)"                "${PEAK_MEMORY_USAGE[0]}" "${PEAK_MEMORY_USAGE[1]}" "${PEAK_MEMORY_USAGE[2]}"

############################################################
# Final Message
############################################################

echo
echo "=============================================================="
echo "Markdown Report : $OUT_MD"
echo "CSV Report      : $OUT_CSV"
echo "=============================================================="
echo