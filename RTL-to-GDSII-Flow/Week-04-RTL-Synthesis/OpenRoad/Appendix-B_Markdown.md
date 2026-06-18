
## Appendix-B: Metrics Extraction Methodology

### Environment Setup
```bash
cd /home/nurmdabd/Asmicore-Projects/RTL-to-GDSII-Flow/Week-04-RTL-Synthesis/OpenRoad
```
```bash
# --------------------------------------------------
# Design Selection
# --------------------------------------------------
DESIGN="tiny-tpu"
# DESIGN="kronos"

RTL_DIR="$DESIGN/rtl"

RUN1="$DESIGN/run_500mhz"
RUN2="$DESIGN/run_600mhz"
RUN3="$DESIGN/run_700mhz"
```


### 1. Clock Period

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
cat $RUN/results/clock_period.txt
echo
done
```

---

### 2. Top Module Name
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "^===" $RUN/reports/synth_stat.txt
echo
done
```

---

### 3. RTL Source File Count

```bash
find $RTL_DIR \
\( -name "*.v" -o -name "*.sv" \) \
| wc -l
```


### 4. Total Cell Count

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "cells$" -B14 \
$RUN/reports/synth_stat.txt
echo
done
```
### 5. Combinational Cell Count
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== Combinational of $RUN ====="
TOTAL=$(grep "cells$" \
$RUN/reports/synth_stat.txt | awk '{print $1}')
SEQ=$(grep -E "DFF|SDFF|LATCH" \
$RUN/reports/synth_stat.txt | awk '{sum+=$1} END{print sum}')
echo "$TOTAL $SEQ" | awk '{print $1-$2}'
echo
done
```
### 6. Sequential Cell Count
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== Sequential of $RUN ====="
grep -E "DFF|SDFF|LATCH" \
$RUN/reports/synth_stat.txt | awk '{sum+=$1}
END{print sum}'
echo
done
```

### 4-8. Multiple Cell Count (Total, Combinational, Sequential, DFF)
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
TOTAL=$(grep "cells$" \
$RUN/reports/synth_stat.txt | awk '{print $1}')
SEQ=$(grep -E "DFF|SDFF|LATCH" \
$RUN/reports/synth_stat.txt | awk '{sum+=$1} END{print sum}')
DFF=$(grep -E "DFF|SDFF" \
$RUN/reports/synth_stat.txt | awk '{sum+=$1} END{print sum}')
COMB=$((TOTAL-SEQ))
SEQP=$(awk "BEGIN{print 100*$SEQ/$TOTAL}")

printf "Total Cells         : %d\n" "$TOTAL"
printf "Sequential Cells    : %d\n" "$SEQ"
printf "DFF Count           : %d\n" "$DFF"
printf "Combinational Cells : %d\n" "$COMB"
printf "Sequential %%        : %.2f\n" "$SEQP"
echo
done
```
### 9. Sequential Area (%)
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "used for sequential elements" \
$RUN/reports/synth_stat.txt
echo
done
```

---

### 10. Chip Area

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "Chip area" \
$RUN/reports/synth_stat.txt
echo
done
```

### 11. Worst Slack or Setup Timing Margin

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "worst slack max" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

---

### 12. Worst Negative Slack (WNS)

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "wns" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

---

### 13. Total Negative Slack (TNS)

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "tns max" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

---

### 15-16. Minimum Clock Period and Fmax

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "clk period_min" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

---
### 17. Path Groups

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "Path Group" \
$RUN/reports/1_Post_synthesis.rpt \
| sort | uniq -c
echo
done
```
### 18. Number of Path Groups
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "Path Group" \
$RUN/reports/1_Post_synthesis.rpt | sort -u | wc -l
echo
done
```
### 19. Most Critical Path Group
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
## Grab the first occurrence of Path Group and Worst Slack
GROUP=$(grep -m1 "Path Group:" $RUN/reports/1_Post_synthesis.rpt)
SLACK=$(grep -m1 "worst slack max" $RUN/reports/1_Post_synthesis.rpt)
## Print them beautifully in one line
echo "$GROUP | $SLACK"
echo
done
```
### 20. Number of Max Paths
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep -c "Path Type: max" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

### 21-22. Startpoint and Endpoint
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep -E "Startpoint:|Endpoint:" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

### 24. Largest Cell Type:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep -B5 -A300 "Path Type: max" \
$RUN/reports/1_Post_synthesis.rpt \
| grep "ASAP7" \
| sort -k4 -n \
| tail -1 \
| sed -E 's/.*\((.*)\).*/\1/'
echo
done
```
### 25. Largest Single Cell Delay
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep -B5 -A300 "Path Type: max" \
$RUN/reports/1_Post_synthesis.rpt \
| grep "ASAP7" \
| awk '{print $4,$5,$6}' \
| sort -n \
| tail -1
echo
done
```


### 26. Data Arival Time:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "data arrival time" \
$RUN/reports/1_Post_synthesis.rpt | tail -1
echo
done
```
### 27. Setup Time:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "library setup time" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

### 28. VT Type Identification
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "VT" \
$RUN/reports/synth_stat.txt
echo
done
```

### 29. RVT Cell Percentage
For ASAP7 designs synthesized in this work, only RVT libraries were used.
```text
RVT Percentage = 100%
LVT Percentage = 0%
SLVT Percentage = 0%
```


### 30-35. Power Breakdown
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep -A15 "report_power" \
$RUN/reports/1_Post_synthesis.rpt
echo
done
```

### 36. Buffer Count:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
grep "BUF" $RUN/reports/synth_stat.txt \
| awk '{sum+=$1} END{print sum}'
echo
done
```

### 37. Inverter Count:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="

grep "INV" \
$RUN/reports/synth_stat.txt \
| awk '{sum+=$1}

END{
print sum
}'

echo
done
```
### 38. Arithmetic Cell Count:
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
egrep "FAx|HAxp|MAJ" \
$RUN/reports/synth_stat.txt | awk '{sum+=$1} END{print sum}'
echo
done
```

### 39. Average Cell Area (μm²/cell)

```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
AREA=$(grep "Chip area" \
$RUN/reports/synth_stat.txt | awk '{print $NF}')
CELLS=$(grep "cells$" \
$RUN/reports/synth_stat.txt | awk '{print $1}')
echo "$AREA $CELLS" | awk '{printf "%.4f\n",$1/$2}'
echo
done
```
### 40. Power Density (W/μm²)
```bash
for RUN in "$RUN1" "$RUN2" "$RUN3"
do
echo "===== $RUN ====="
AREA=$(grep "Chip area" \
$RUN/reports/synth_stat.txt | awk '{print $NF}')
POWER=$(grep "^Total" \
$RUN/reports/1_Post_synthesis.rpt | tail -1 | awk '{print $5}')
echo "$POWER $AREA" | awk '{printf "%.8e\n",$1/$2}'
echo
done
```