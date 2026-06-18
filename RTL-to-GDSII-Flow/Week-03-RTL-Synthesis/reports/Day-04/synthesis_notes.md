\# Day-04 Synthesis Tuning Notes



\## Run 1 — Baseline Configuration



\- Strategy: AREA 0

\- Clock Period: 20 ns

\- Cell Count: 93,781

\- Area: 804,275.11 um²

\- WNS: 0.00 ns

\- Timing Met: Yes



Observation:

The baseline configuration achieved timing closure while maintaining the lowest area and lowest cell count.



\---



\## Run 2 — Tight Timing Configuration



\- Strategy: AREA 0

\- Clock Period: 10 ns

\- Cell Count: 93,781

\- Area: 804,275.11 um²

\- WNS: -1.68 ns

\- TNS: -52.73 ns

\- Timing Met: No



Observation:

Reducing the clock period from 20 ns to 10 ns caused timing violations. The synthesis engine produced the same netlist structure, indicating that AREA 0 optimization did not add additional timing-focused optimizations.



\---



\## Run 3 — Delay Optimized Configuration



\- Strategy: DELAY 0

\- Clock Period: 20 ns

\- Cell Count: 110,151

\- Area: 942,737.91 um²

\- WNS: 0.00 ns

\- Timing Met: Yes



Observation:

DELAY 0 increased both cell count and chip area. Additional cells were inserted to improve timing robustness.



\---



\## Final Configuration Selection



Selected Run: Run 1



Reasons:



\- Timing closure achieved.

\- Lowest area.

\- Lowest cell count.

\- Most area-efficient implementation.

\- Suitable handoff package for Week-02 physical design.

