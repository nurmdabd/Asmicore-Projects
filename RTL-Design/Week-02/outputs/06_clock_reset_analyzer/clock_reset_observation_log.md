# Clock Reset Analyzer Observations

Modules Analyzed: 4

Clock Signals:
- clk

Reset Signals:
- rst

---

## uart_top_design

Reset Type: combinational_only

Sequential Always Blocks: 0
---

## uart_baud_rate

Reset Type: synchronous

Sequential Always Blocks: 2
---

## uart_rx

Reset Type: synchronous

Sequential Always Blocks: 4
---

## uart_tx

Reset Type: synchronous

Sequential Always Blocks: 3

---

Limitation:
IR schema v0.1 does not preserve procedural assignments.
Register reset values cannot be extracted.