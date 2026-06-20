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
# DESIGN_DIR=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/tiny-tpu
DESIGN_DIR=/home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad/kronos

RTL_DIR="$DESIGN_DIR/rtl/core"

RUN1="$DESIGN_DIR/run_500mhz"
RUN2="$DESIGN_DIR/run_600mhz"
RUN3="$DESIGN_DIR/run_700mhz"
RUN4="$DESIGN_DIR/extra_run_1.5GHz"
RUN5="$DESIGN_DIR/extra_run_2GHz"

RUNS=("$RUN1" "$RUN2" "$RUN3" "$RUN4" "$RUN5")
FREQS=(
500
600
700
1500
2000
)

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

HEADER="| Count | Metric |"
ALIGN="|:---:|---|"

for F in "${FREQS[@]}"
do
    HEADER+=" ${F} MHz |"
    ALIGN+="---|"
done

{
echo "# ${DESIGN_DIR} Metrics Summary"
echo
echo "$HEADER"
echo "$ALIGN"
} > "$OUT_MD"

############################################################
# CSV Initialization
############################################################

CSV_HEADER="Count,Metric"

for F in "${FREQS[@]}"
do
CSV_HEADER+=",${F}MHz"
done

echo "$CSV_HEADER" > "$OUT_CSV"

############################################################
# Metric Writer
############################################################


write_metric(){

IDX="$1"
NAME="$2"

shift 2


MD="| $IDX | $NAME |"
CSV="$IDX,\"$NAME\""

TERM=$(printf "%2d. %-35s :" \
"$IDX" "$NAME")


for V in "$@"
do

MD+=" $V |"

CSV+=",\"$V\""

TERM+=" $(printf '%-18s' "$V")"

done


echo "$MD" >> "$OUT_MD"

echo "$CSV" >> "$OUT_CSV"

echo "$TERM"

}


SEQP_P=()
SEQA_P=()
RVT_P=()
SEQC_P=()
COMBC_P=()

for i in "${!SEQP[@]}"
do
    SEQP_P+=("${SEQP[$i]}%")
    SEQA_P+=("${SEQA[$i]}%")
    RVT_P+=("${RVT[$i]}%")
    SEQC_P+=("${SEQC[$i]}%")
    COMBC_P+=("${COMBC[$i]}%")
done

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

write_metric 1  "Clock Period (ps)"                     "${CLOCK[@]}"
write_metric 2  "Top Module"                            "${TOP[@]}" 
write_metric 3  "RTL Files"                             "${RTL[@]}" 

write_metric 4  "Total Cells"                           "${TOTAL[@]}" 
write_metric 5  "Combinational Cells"                   "${COMB[@]}" 
write_metric 6  "Sequential Cells"                      "${SEQ[@]}" 
write_metric 7  "DFF Count"                             "${DFF[@]}" 

write_metric 8 "Sequential Cell %"                      "${SEQP_P[@]}"
write_metric 9  "Sequential Area (%)"                   "${SEQA_P[@]}"

write_metric 10 "Chip Area (um2)"                       "${AREA[@]}" 

write_metric 11 "Worst Slack"                           "${SLACK[@]}" 
write_metric 12 "WNS (ps)"                              "${WNS[@]}"
write_metric 13 "TNS (ps)"                              "${TNS[@]}" 
FEP_COLS=()

for ((i=0;i<${#RUNS[@]};i++))
do
FEP_COLS+=("$FEP")
done


write_metric 14 \
"FEP" \
"${FEP_COLS[@]}"

write_metric 15 "Minimum Period (ps)"                   "${PERIOD[@]}" 
write_metric 16 "Estimated Fmax (MHz)"                  "${FMAX[@]}" 

write_metric 17 "Path Groups  (⚠️DCheck)"               "${GROUP[@]}" 
write_metric 18 "Number of Path Groups (⚠️DCheck)"      "${NGROUP[@]}" 
write_metric 19 "Most Critical Path Group"              "${GROUP[@]}" 

write_metric 20 "Number of Max Paths"                   "${MAXPATH[@]}" 

write_metric 21 "Start Point"                           "${START[@]}" 
write_metric 22 "End Point"                             "${ENDPT[@]}" 

LOGIC_COLS=()

for ((i=0;i<${#RUNS[@]};i++))
do
LOGIC_COLS+=("$LOGIC_DEPTH")
done


write_metric 23 \
"Critical Path Logic Depth" \
"${LOGIC_COLS[@]}"

write_metric 24 "Largest Cell Type (⚠️DCheck)"          "${LTYPE[@]}" 
write_metric 25 "Largest Cell Delay (ps) (⚠️DCheck)"    "${LDELAY[@]}" 

write_metric 26 "Data Arrival Time (ps)"                "${ARR[@]}"
write_metric 27 "Setup Time (ps)"                       "${SETUP[@]}" 

write_metric 28 "VT Type"                               "${VT[@]}" 
write_metric 29 "RVT Percentage"                 "${RVT_P[@]}"

write_metric 30 "Internal Power (W)"                    "${IPWR[@]}" 
write_metric 31 "Switching Power (W)"                   "${SPWR[@]}" 
write_metric 32 "Leakage Power (W)"                     "${LPWR[@]}" 
write_metric 33 "Total Power (W)"                       "${TPWR[@]}" 

write_metric 34 "Sequential Contribution (%)"   "${SEQC_P[@]}"
write_metric 35 "Combinational Contribution (%)" "${COMBC_P[@]}"

write_metric 36 "Buffer Count"                          "${BUF[@]}" 
write_metric 37 "Inverter Count"                        "${INV[@]}" 
write_metric 38 "Arithmetic Cell Count"                 "${ARITH[@]}"

write_metric 39 "Average Cell Area"                     "${AVGAREA[@]}" 
write_metric 40 "Power Density"                         "${DENSITY[@]}" 

write_metric 41 "Elapsed Time (Min:Sec)"                "${ELAPSED_TIME[@]}" 
write_metric 42 "Peak Memory Usage (MB)"                "${PEAK_MEMORY_USAGE[@]}" 

############################################################
# Final Message
############################################################

echo
echo "=============================================================="
echo "Markdown Report : $OUT_MD"
echo "CSV Report      : $OUT_CSV"
echo "=============================================================="
echo