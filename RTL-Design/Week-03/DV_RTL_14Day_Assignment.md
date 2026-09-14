# DV & RTL Team - 14-Day Assignment Plan

*From RTL Fundamentals to Verification Thinking*

**Asmicore Semiconductor - Internship Program**

## Program at a Glance

| **Item**              | **Details**                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| **Program**           | RTL Design + Design Verification Fundamentals                                                  |
| **Prerequisites**     | Basic digital logic, familiarity with logic gates and flip-flops                               |
| **Duration**          | 14 working days (Day 14 = submission + presentation)                                           |
| **Daily structure**   | Learning Topics → Experimental Work → Output → KB Entry                                        |
| **Designs you build** | RTL #1 Sequence Detector, RTL #2 Traffic Light Controller, RTL #3 Synchronous FIFO             |
| **Core deliverables** | RTL_Specifications.docx + Knowledge Base + Issue Log + Git repo + Presentation                 |
| **Golden rule**       | Understand before you build. Every design decision must be something you can explain out loud. |

## Work Expectation

| **Step** | **Activity**    | **Description**                                   | **Output**              |
| -------- | --------------- | ------------------------------------------------- | ----------------------- |
| 1        | Study           | Research each topic area before touching any code | KB notes                |
| 2        | Experiment      | Do the hands-on tasks to reinforce understanding  | Artifacts per day       |
| 3        | Design          | Write three RTL blocks from scratch               | SystemVerilog files     |
| 4        | Document        | Spec doc capturing all three designs              | RTL_Specifications.docx |
| 5        | Reflect         | Knowledge Base + Issue Log maintained daily       | DOCX / MD files         |
| 6        | Version Control | Track all work in Git with regular commits        | Git history             |

## The Designs You Will Build

| **RTL** | **Design**                           | **Difficulty** | **What it exercises**                              |
| ------- | ------------------------------------ | -------------- | -------------------------------------------------- |
| #1      | Sequence Detector (overlapping 1011) | Easy           | Pure control FSM, Moore states, 1-bit serial I/O   |
| #2      | Traffic Light Controller             | Medium         | FSM + timed states driven by a counter             |
| #3      | Synchronous FIFO                     | Medium         | Datapath: memory array, pointers, full/empty flags |

## Repository Structure

```
<group>-dv-assignment/
├── README.md
├── rtl/
│   ├── seq_detect_1011.sv
│   ├── traffic_light.sv
│   └── sync_fifo.sv
├── tb/
│   └── smoke testbenches (one per RTL)
├── docs/
│   ├── RTL_Specifications.docx
│   └── Knowledge_Base.docx
└── issues/
    └── ISSUE_LOG.md
```

## Final Deliverables (submitted Day 14)

| **#** | **Item**                | **Requirement**                                          |
| ----- | ----------------------- | -------------------------------------------------------- |
| 1     | RTL_Specifications.docx | All 3 RTLs - every section complete, RTL code included   |
| 2     | Knowledge_Base.docx     | Day-by-day entries + Issue Log + Final Reflection        |
| 3     | ISSUE_LOG.md            | Every problem encountered, its cause, and its resolution |
| 4     | Git repository          | Clean structure, regular commits, all files present      |

## Rules & Policy

**Core rules**

- Each group works independently. No cross-group copying.
- Understand each concept before writing any code.
- Produce real outputs even if incomplete. Do not hide mistakes.

**Documentation & issue rules**

- Maintain the Knowledge Base daily - not at the end.
- Log every error, confusion, and assumption honestly.
- One KB entry per day, written by the person who did the work.

**Behaviour rules**

- Try to solve a problem yourself before asking.
- Every member must be able to explain every part of the group's work.
- Every member must speak during the final presentation.

# STUDY BLOCK 1 - RTL & Digital Design Fundamentals

## Days 1-3

_Before writing a single line of SystemVerilog, you must understand the conceptual foundation. These three days are study-first days. Read, research, discuss within your group, and document everything in your Knowledge Base. The experimental work reinforces what you read - it is not a shortcut to skip the reading._

## Day 1 - What is RTL? HDL Basics & SystemVerilog Essentials

**Stage: Study Block 1 | Goal: Understand what RTL is, where it sits in the chip design flow, and learn the core SystemVerilog building blocks.**

### Learning Topics 

#### 1.1 What is RTL?

- Definition of Register Transfer Level (RTL) - what "register transfer" actually means
- RTL vs behavioural description vs gate-level netlist - the three abstraction levels
- Why RTL is the standard handoff format between design and verification teams
- The RTL-to-silicon flow: RTL → synthesis → place & route → GDSII
- What a simulator does with RTL vs what a synthesiser does

#### 1.2 HDL Fundamentals

- What a Hardware Description Language is and why it is not a programming language
- Verilog vs SystemVerilog - history and what SystemVerilog adds
- Simulation vs synthesis: not all valid SV is synthesisable
- The concept of concurrency - why hardware runs in parallel, not sequentially
- Delta cycles and the simulation event queue (high level understanding)

#### 1.3 SystemVerilog Module Structure

- module / endmodule - the basic unit of hardware
- Port declaration: input, output, inout
- Data types: logic, wire, reg - differences and when to use each
- parameter and localparam - how to make designs configurable
- Multi-bit signals and part-selects: `logic [7:0]`, `signal[3:1]`
- Signed vs unsigned signals

#### 1.4 Concurrent vs Procedural Code

- assign statements - continuous assignment, runs always
- always_comb - combinational logic block, re-evaluates on any input change
- always_ff - sequential logic block, triggered on clock edge
- always_latch - when it appears and why it is usually unintended
- Sensitivity lists - `@(posedge clk)`, `@(*)`, and what they mean

#### 1.5 Operators & Expressions

- Bitwise operators: &, |, ^, ~
- Logical operators: &&, ||, !
- Reduction operators: &a, |a, ^a
- Relational operators: ==, !=, ===, !==
- Concatenation: {a, b} and replication: {4{a}}
- Shift operators: `<<`, `>>`, `<<<`, `>>>`

### Experimental Work

- Research and write a one-paragraph explanation of what happens to your RTL code between the moment you write it and the moment it becomes transistors on a chip.
- Find one example of a simple module in SystemVerilog online or from your study materials. Annotate every line - what each keyword does, what each signal represents.
- Write a minimal SV module by hand (no simulator yet): a 2-input AND gate with a, b inputs and y output using assign. Annotate it fully.
- Write out the difference between wire and logic in your own words. When would you use each?
- List five things that are valid in simulation but would not synthesise. Explain why for each.

### Output

- Document everything in your Knowledge Base document - covering all five topic areas above in your own words
- Annotated AND gate module saved in your repo under docs/experiments/

## Day 2 - FSM Theory: Moore, Mealy, State Encoding & Transition Tables

**Stage: Study Block 1 | Goal: Deeply understand Finite State Machines - the backbone of most RTL control logic.**

### Learning Topics

#### 2.1 What is a Finite State Machine?

- Definition: a system with a finite number of states, transitions between them, and outputs
- The four components of any FSM: states, inputs, outputs, transitions
- Why FSMs are the dominant pattern for control logic in digital design
- Real-world examples in hardware: serial receiver, traffic light, USB controller, arbiters

#### 2.2 Moore vs Mealy

- Moore FSM: outputs depend only on current state
- Mealy FSM: outputs depend on current state AND current inputs
- Comparison table - latency, glitch risk, gate count, typical use cases
- When to choose Moore (most RTL control logic) vs Mealy
- How to convert a Mealy FSM to a Moore FSM

#### 2.3 State Encoding

- Binary encoding: states are numbered 0, 1, 2... - compact, fewer flip-flops
- One-hot encoding: one flip-flop per state, only one HIGH at a time - faster decode
- Gray encoding: adjacent states differ by one bit - minimises switching noise
- How synthesis tools choose encoding with `/* synthesis enum */` or tool directives
- Trade-offs: speed vs area vs power vs debuggability

#### 2.4 Transition Tables & State Diagrams

- How to build a state transition table: current state + input → next state + output
- How to draw a state diagram: circles = states, arrows = transitions, labels = condition/output
- Reading and verifying a transition table against a state diagram
- Identifying unreachable states and invalid state handling
- Self-loops, reset states, and default state handling

#### 2.5 Two-Block FSM Style in SystemVerilog

- Block 1: state register - always_ff clocked block that updates state <= next_state
- Block 2: next-state & output logic - always_comb block with case statement
- Why two blocks is cleaner than one monolithic always block
- `typedef enum logic [N:0] { STATE_A, STATE_B } state_t;` - proper state type declaration
- Reset handling: synchronous vs asynchronous reset in the state register

#### 2.6 Common FSM Bugs

- Incomplete case statement → inferred latch
- Missing default state in case → undefined behaviour on illegal state
- Output registered one cycle late - Moore timing vs Mealy timing confusion
- State register not reset properly - FSM starts in unknown state
- Overlapping detection errors - not handling the overlap case in sequence detectors

### Experimental Work

- Draw the state diagram for an overlapping 1011 sequence detector by hand. Label every state, every transition condition, and the output for each state.
- Build the state transition table for the same detector. Columns: Current State, Input (din), Next State, Output (detected).
- Hand-trace the input sequence 1 1 0 1 0 1 1 through your transition table. Record state and output at each step.
- Write the state transition table for a simple traffic light: MAIN_GREEN → MAIN_YELLOW → SIDE_GREEN → SIDE_YELLOW → back to MAIN_GREEN. No timers yet - just the sequence.
- Write a one-paragraph comparison of Moore vs Mealy in your own words. Give one example where you would choose each.

### Output

- Document everything in your Knowledge Base document - covering all topic areas above
- Hand-drawn (or neatly typed) state diagram for 1011 detector saved as docs/experiments/seq_detect_state_diagram.md
- Completed transition tables for both the sequence detector and traffic light

## Day 3 - DV Fundamentals: What is Verification and Why Does It Exist?

**Stage: Study Block 1 | Goal: Understand what design verification is, why it is a separate discipline from design, and what the core concepts and vocabulary are.**

### Learning Topics

#### 3.1 Verification vs Validation

- Verification: are we building the design right? (Does the RTL match the spec?)
- Validation: are we building the right design? (Does the spec match what the customer needs?)
- Why both are needed and why they happen at different stages
- The cost of finding a bug: at RTL stage vs post-silicon - the 10x rule at each stage
- Famous chip bugs caused by insufficient verification (Pentium FDIV, Ariane 5)

#### 3.2 The Verification Problem

- Why you cannot simulate every possible input combination (state space explosion)
- Coverage-driven verification: you stop when you've hit your coverage targets, not when you run out of ideas
- The difference between finding a bug and proving correctness
- Formal verification vs simulation - high level concept only

#### 3.3 Testbench Anatomy

- DUT (Device Under Test) - the RTL block being verified
- Stimulus generator - creates inputs to drive the DUT
- Monitor - observes DUT outputs without interfering
- Checker / Scoreboard - compares DUT output to expected (golden reference)
- Coverage collector - tracks which scenarios have been exercised
- How these components connect: the testbench wraps the DUT

#### 3.4 Types of Tests

- Directed tests: hand-crafted inputs targeting a specific behaviour - predictable, good for corner cases
- Random / constrained-random tests: inputs generated automatically within constraints - broad coverage
- Regression: running all tests together to catch regressions after a design change
- Smoke test: a minimal directed test just to confirm the design is not obviously broken

#### 3.5 The Verification Plan

- What a verification plan is: a document listing what needs to be verified and how
- Feature: a named, independently testable behaviour of the DUT
- Test case: a specific scenario that exercises one or more features
- Priority: P0 (must pass), P1 (high importance), P2 (nice to have)
- Status: Not Started / In Progress / Pass / Fail
- Why the verification plan must be written before testbench coding begins

#### 3.6 Coverage Basics

- Code coverage: did the simulator execute this line / branch / toggle this signal?
  - Statement coverage
  - Branch coverage
  - Toggle coverage
  - FSM state + transition coverage
- Functional coverage: did you exercise this scenario that matters to the spec?
  - Coverpoints: a variable you want to track the values of
  - Bins: the specific values or ranges you care about
  - Cross coverage: combinations of two coverpoints
- Coverage closure: the process of reaching your coverage targets

#### 3.7 Assertions

- What an assertion is: a statement that must always be true during simulation
- Immediate assertions vs concurrent assertions
- Examples: reset must deassert before any output changes; full flag must not be set when count < DEPTH
- Why assertions are better than manual checking: they fire automatically, every cycle
- SystemVerilog Assertion (SVA) - concept level only

### Experimental Work

- Write a one-page explanation of why verification is a separate job from RTL design. What does a DV engineer do that a designer does not?
- Draw the anatomy of a testbench - a block diagram with DUT in the centre and all testbench components around it, with arrows showing data/signal flow.
- Look at the FIFO you will design next week. List 5 features of that FIFO that need to be verified. For each, write one sentence describing what a test for that feature would do.
- Write 3 assertions in plain English (not code) for the sequence detector you studied in Day 2. Example: "detected must never be HIGH for two consecutive cycles."
- Research: what is the difference between a scoreboard and a monitor? Write the answer in your own words with a concrete example.

### Output

- Document everything in your Knowledge Base document - all topic areas above in your own words
- Block diagram of testbench anatomy saved in docs/experiments/
- 5 features + test descriptions for the FIFO (preview of DV thinking)

# RTL DESIGN BLOCK

## Days 4-8

_You now apply the foundation you built in Days 1-3. Each day has a specific RTL to design, smoke-test, and commit. Day 8 is a documentation day - you pull everything together into a single professional specification document._

## Day 4 - RTL #1: Sequence Detector (Overlapping 1011)

**Stage: RTL Design | Goal: Implement a Moore FSM that detects the overlapping bit sequence 1011 on a serial input.**

### Learning Topics

#### 4.1 Quick Review - Sequence Detector Theory

- Overlapping detection: after a match, the last bits of the match can be the start of the next match
- Non-overlapping vs overlapping - what changes in the state diagram
- Why the Moore output is registered and how this affects the detected pulse timing

#### 4.2 Two-Block SV Implementation

- Declaring the state type with typedef enum
- State register block: always_ff @(posedge clk or negedge rst_n)
- Next-state + output block: always_comb with case(state)
- Synchronous vs asynchronous reset - which to use and why

#### 4.3 Smoke Testbench Basics

- How to write a minimal initial block to drive a clock and stimulus
- `$display` and `$monitor` for printing signal values
- How to check output by eye in the waveform or terminal log

### Experimental Work

- Write the mini-spec first: ports (clk, rst_n, din, detected), states (IDLE, S1, S10, S101), and the full transition table for overlapping 1011.
- Implement rtl/seq_detect_1011.sv as a clean two-block Moore FSM.
- Hand-trace the input 1 1 0 1 0 1 1 through your RTL logic before simulating. Predict exactly which cycle detected goes HIGH.
- Write a smoke testbench. Drive the stream 1 1 0 1 0 1 1, print din / state / detected each cycle.
- Run it on EDA Playground. Confirm the detector fires on the cycle you predicted.
- Fix any bugs. Document each bug in the Issue Log: what was wrong, why, how you fixed it.

### Output

- rtl/seq_detect_1011.sv - committed to repo
- Smoke test log (copy terminal output into docs/experiments/seq_detect_smoke_log.md)
- KB entry: transition table, bugs found and fixed
- Issue Log updated

## Day 5 - RTL #2: Traffic Light Controller

**Stage: RTL Design | Goal: Implement an FSM with timed states driven by a down-counter datapath.**

### Learning Topics

#### 5.1 FSM + Datapath Pattern

- Why a pure FSM is not enough when states have durations
- The counter-driven FSM pattern: FSM controls state, counter controls duration
- How the FSM transitions only when the counter reaches zero
- Parameterising state durations - why hardcoding numbers in RTL is bad practice

#### 5.2 Counter Datapath in SV

- Down-counter: loads a value on state entry, decrements each cycle, signals done at zero
- How to load vs decrement: using if (load) count <= duration; else count <= count - 1
- parameter for duration values - makes the design testable with short durations

#### 5.3 Output Encoding

- Driving multiple output bits from a state (main_green, main_yellow, side_green, side_yellow)
- One-hot output style: only one light group active per state
- What to output during YELLOW states - both roads red? Which road yellow?

### Experimental Work

- Define states: MAIN_GREEN, MAIN_YELLOW, SIDE_GREEN, SIDE_YELLOW. Define durations as parameters (use small values like 4, 2, 6, 2 for simulation).
- Build a state + duration table: State | Duration (cycles) | main_road lights | side_road lights.
- Implement rtl/traffic_light.sv: state register + down-counter in one always_ff; next-state logic in always_comb.
- Drive the four light outputs (main_red, main_yellow, main_green, side_red, side_yellow, side_green) from the state.
- Smoke test with the small durations. Print state name and all 6 light outputs each cycle.
- Verify the full cycle runs correctly: MAIN_GREEN → MAIN_YELLOW → SIDE_GREEN → SIDE_YELLOW → MAIN_GREEN.

### Output

- rtl/traffic_light.sv - committed to repo
- Smoke test log in docs/experiments/traffic_light_smoke_log.md
- Knowledge Base entry: state/duration table, how the counter drives transitions, bugs found
- Issue Log updated

## Day 6 - RTL #3: Synchronous FIFO

**Stage: RTL Design | Goal: Implement a datapath-heavy design with memory, read/write pointers, and full/empty flags.**

### Learning Topics

#### 6.1 What is a FIFO and Why It Exists

- FIFO: First In First Out - data comes out in the same order it went in
- Where FIFOs appear in SoC design: clock domain crossings, rate matching, buffering between producer and consumer
- Synchronous FIFO: single clock domain - simpler than async FIFO

#### 6.2 FIFO Architecture

- Memory array: `logic [WIDTH-1:0] mem [0:DEPTH-1]`
- Write pointer (wr_ptr): points to where the next write goes
- Read pointer (rd_ptr): points to where the next read comes from
- Count register: tracks number of valid entries - used to derive full and empty
- Pointer wraparound: when pointer reaches DEPTH, it wraps back to 0

#### 6.3 Full & Empty Flag Logic

- empty: count == 0 - no valid data to read
- full: count == DEPTH - no room to write
- Simultaneous read + write: count stays the same - handle this case explicitly
- Write when full: must be blocked - data would be lost
- Read when empty: must be blocked - undefined data would be returned

#### 6.4 Pointer Arithmetic

- Why you cannot just compare wr_ptr == rd_ptr to detect full vs empty - ambiguous
- Two approaches: use a count register (simpler, our approach) or use an extra bit on the pointers
- Wraparound arithmetic: wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1

### Experimental Work

- Define ports: clk, rst_n, wr_en, rd_en, `din [WIDTH-1:0]`, `dout [WIDTH-1:0]`, full, empty. Parameters: WIDTH=8, DEPTH=8.
- Implement rtl/sync_fifo.sv: memory array, wr_ptr, rd_ptr, count all in one always_ff block. Derive full and empty combinationally from count.
- Handle simultaneous read+write in a single cycle - count must not change.
- Smoke test sequence: reset → fill to full → attempt one extra write (should be blocked) → drain to empty → attempt one extra read (should be blocked).
- Print wr_en / rd_en / din / dout / count / full / empty each cycle.
- Verify: no data lost, correct order, flags correct throughout.

### Output

- rtl/sync_fifo.sv - committed to repo
- Smoke test log in docs/experiments/sync_fifo_smoke_log.md
- KB entry: how full/empty are computed, pointer wraparound, corner cases found and fixed
- Issue Log updated

## Day 7 - Study: RTL Specification Writing

**Stage: RTL Design (Study Day) | Goal: Learn how to write a professional RTL specification document before writing yours on Day 8.**

### Learning Topics

#### 7.1 What is an RTL Specification Document?

- The spec is the contract between the designer and the verifier - it defines correct behaviour
- A DV engineer must be able to write tests from the spec alone, without reading the RTL
- What happens when a spec is ambiguous - the designer and verifier disagree on expected behaviour
- The spec is written after the design is stable but before verification planning begins

#### 7.2 Sections of a Good RTL Spec

- **Overview**: what the block does, its role in the SoC, key design decisions
- **Key Features**: bullet list of the main capabilities (what can it do?)
- **Interface Table**: every port - name, direction, width, clock domain, description
- **Microarchitecture**: how the design works internally - key datapath, control structure, parameters
- **FSM Specification**: state encoding table, state transition table, ASCII state diagram
- **Timing Diagrams**: key waveforms showing signal relationships across clock cycles
- **Corner Cases**: list of boundary conditions and how each is handled
- **RTL Code**: the actual SV code, included at the end

#### 7.3 Writing a Good Interface Table

- Every port on one row: Port Name | Direction | Width | Clock Domain | Active Level | Description
- Description must say *when* the signal is asserted and *what it causes*, not just its name
- Active level matters: rst_n is active-low - say so
- Width must match the RTL exactly

#### 7.4 Writing a Good FSM Spec

- State encoding table: State Name | Encoding | Description
- Transition table: Current State | Condition | Next State | Output Actions
- ASCII state diagram: boxes for states, arrows for transitions, labels for conditions
- Every state must be reachable, every transition must be explained

#### 7.5 Writing Good Corner Cases

- A corner case is a boundary condition where the design could fail if not handled explicitly
- How to find corner cases: think about what happens at the edges of every parameter and every signal
- Examples for FIFO: write when full, read when empty, simultaneous read+write at full, simultaneous read+write at empty, reset mid-transaction
- Each corner case entry: Scenario | Expected Behaviour | How it is Handled in RTL

### Experimental Work

- Read both worked examples in example_rtl_and_testplan/ - focus on their spec document structure, not the content.
- For each of your three RTLs, list the corner cases you can identify. Aim for at least 3 per design.
- Draft the interface table for RTL #1 (Sequence Detector) by hand or in a text file. Every port, every column filled.
- Write the ASCII state diagram for the Traffic Light Controller using text characters.
- Write a one-paragraph overview for the FIFO as if explaining it to a DV engineer who has never seen the design.

### Output

- Document everything in your Knowledge Base document - covering all topic areas above
- Draft interface table for RTL #1
- Corner case list for all 3 RTLs
- ASCII state diagram for Traffic Light

## Day 8 - Combined RTL Specification Document

**Stage: RTL Design | Goal: Produce one professional RTL_Specifications.docx covering all three designs.**

### Learning Topics

#### 8.1 Consistency Across Multiple Designs

- Using a consistent template across all three spec sections
- Naming conventions must match the RTL exactly - signal names, state names, parameter names
- Going back to fix RTL issues the spec writing reveals (naming, widths, reset values)

### Experimental Work

- Open the example RTL_Specifications_EXAMPLE.docx and copy the section structure exactly.
- For each RTL write all sections: Overview, Key Features, Interface Table, Microarchitecture, FSM Specification, Timing, Corner Cases, RTL Code.
- Re-read each RTL file after writing its spec. Fix any inconsistencies - naming, widths, missing reset values, undefined corner cases.
- Commit the cleaned RTL files and the spec document together.

### Output

- docs/RTL_Specifications.docx - all 3 RTLs, every section complete - committed to repo
- Cleaned rtl/ folder with any fixes applied
- KB entry: corner cases you found while writing the spec that weren't in your original RTL

# STUDY BLOCK 2 - Verification Planning

## Days 9-11

_With your RTL designs complete and documented, you now study the concepts needed to plan verification. These three study days are as important as the design days. A DV engineer who cannot plan a verification strategy is not ready to write a single testbench line. Study carefully, document thoroughly._

## Day 9 - Verification Planning Methodology, Test Categories & Req-IDs

**Stage: Study Block 2 | Goal: Understand how a professional verification plan is structured and how to organise tests into categories with traceability.**

### Learning Topics

#### 9.1 The Verification Plan as a Document

- The verification plan (also called a test plan) is written before any testbench code
- It answers three questions: what are we verifying, how are we verifying it, and how do we know when we are done?
- Who writes it: the DV lead, with input from the RTL designer
- Who uses it: every DV engineer, the project manager, the sign-off reviewer
- The verification plan is a living document - it gets updated as bugs are found and design changes are made

#### 9.2 Feature Identification

- A feature is a named, independently testable behaviour of the DUT
- Features come from: the RTL spec (interface table, corner cases), protocol requirements, design intent
- Feature granularity: not too coarse (write_operation is too broad), not too fine (wr_ptr_increments_on_cycle_3 is too specific)
- Good feature examples: reset_initialises_all_outputs, full_flag_asserts_when_count_equals_depth, data_preserved_on_simultaneous_read_write
- Feature list is the input to the verification plan

#### 9.3 Test Categories

- **Reset / Initialisation tests**: verify the DUT starts in the correct state after reset
- **Functional tests**: verify the core intended behaviour - the happy path
- **Corner case / boundary tests**: verify behaviour at the edges (full FIFO, zero-length sequence, single-cycle pulse)
- **Negative tests**: verify the DUT handles illegal inputs correctly (write when full, read when empty, invalid state)
- **Stress / consecutive tests**: verify sustained operation over many cycles without error accumulation

#### 9.4 Requirement IDs (Req-IDs)

- A Req-ID is a unique identifier for each test case: RST_001, FUNC_003, CORNER_002
- Prefix identifies the category: RST, FUNC, CORNER, NEG, STRESS
- Sequential numbering within each category
- Why Req-IDs matter: traceability - you can link a test to a feature to a coverage item to a bug report
- Req-IDs never change once assigned - even if a test is removed, its ID is retired, not reused

#### 9.5 Entry and Exit Criteria

- Entry criteria: conditions that must be true before verification can start (RTL frozen, spec complete, sim environment set up)
- Exit criteria: conditions that mean verification is done (all P0 tests pass, 90% functional coverage, zero open P0 bugs)
- Why these must be written down before verification starts - prevents "just one more test" scope creep

#### 9.6 Traceability

- Traceability: every feature links to at least one test; every test links to at least one coverage item
- A test with no coverage item cannot be measured - you don't know if the scenario was actually exercised
- A coverage item with no test means the scenario was never deliberately targeted
- Traceability matrix: Feature → Req-ID → Coverage Link - the spine of a professional verification plan

### Experimental Work

- Take the feature list you drafted for the FIFO on Day 3. Refine it - are any features too broad or too fine? Can you split or merge?
- Assign test categories to each FIFO feature. Write the category next to each feature and justify your choice.
- Assign Req-IDs to all FIFO features using the prefix convention above.
- Write entry and exit criteria for verifying the Sequence Detector. Be specific - what does "done" actually mean?
- Draw a simple traceability table for 3 FIFO features: Feature Name | Req-ID | Test Description (one line) | Coverage item (one line).

### Output

- Document everything in your Knowledge Base document - all topic areas above in your own words
- Refined FIFO feature list with categories and Req-IDs
- Traceability table for 3 FIFO features

## Day 10 - Checker Types, Directed vs Random Stimulus & Priority

**Stage: Study Block 2 | Goal: Understand how to choose the right verification method for each feature.**

### Learning Topics

#### 10.1 Checker Types

**Assertion (SVA)**

- A property that must be true on every clock cycle during simulation
- Best for: protocol invariants, timing rules, signal relationships that are always true
- Examples: full and empty must never both be HIGH simultaneously; detected must be LOW when din has not completed the sequence
- Fires automatically - no need to manually check in the testbench
- Syntax overview (concept level): assert property (@(posedge clk) !(full && empty))

**Scoreboard**

- A component that tracks what the DUT should produce and compares it to what it actually produces
- Requires a reference model (golden model) - a simple software representation of the correct behaviour
- Best for: data integrity checks, output value correctness, order-preserving designs (FIFOs, pipelines)
- Example: FIFO scoreboard stores written data in a software queue; on each read, checks dout matches the oldest entry

**Checker with Expected Value**

- Simpler than a full scoreboard - for directed tests where you know exactly what the output should be
- Best for: directed corner case tests where the stimulus is fully controlled
- Example: after driving 1011 on din, check that detected goes HIGH on the next cycle

#### 10.2 Directed vs Random Stimulus

**Directed Stimulus**

- You write the exact input sequence by hand
- Best for: corner cases, protocol-specific sequences, negative tests, reset sequences
- Pros: predictable, easy to debug, good for P0 features
- Cons: limited coverage breadth - you can only test what you think of

**Random / Constrained-Random Stimulus**

- Inputs are generated automatically within defined constraints
- Best for: broad functional coverage, finding unexpected interactions, stress testing
- Pros: finds bugs you didn't think of; scales to cover large input spaces
- Cons: harder to debug (which input caused the failure?); needs a scoreboard to check correctness
- Constraint example: wr_en and rd_en randomised independently, but not when full or empty to avoid illegal cases

**Choosing Between Them**

- Reset, corner cases, negative tests → directed
- Broad functional behaviour, data integrity → constrained-random
- Most real verification plans use both - directed for P0, random for coverage closure

#### 10.3 Priority Levels

- **P0 (Must Pass)**: the design is broken without this. Silicon cannot be signed off if a P0 fails.
  - Examples: reset works, basic write/read works, full/empty flags correct
- **P1 (High Importance)**: important feature, sign-off requires passing but may have workarounds
  - Examples: simultaneous read/write, consecutive operations without gaps
- **P2 (Nice to Have)**: adds confidence but not a sign-off blocker
  - Examples: long stress runs, unusual but valid input patterns

#### 10.4 Matching Features to Methods

- Protocol invariants (always true) → assertion
- Data correctness (output matches input) → scoreboard
- Specific timed sequence → directed + checker
- Broad coverage → constrained-random + scoreboard
- Negative / illegal input → directed + assertion (should not fire in normal operation)

### Experimental Work

- For each of the 5 FIFO features you identified, assign: checker type (assertion / scoreboard / checker with expected) and stimulus type (directed / random). Write one sentence justifying each choice.
- Write 3 assertions in plain English for the Traffic Light Controller. Example: "main_green and side_green must never be HIGH at the same time."
- Describe a scoreboard for the FIFO in plain English: what does it store, when does it compare, what does a mismatch mean?
- Assign P0 / P1 / P2 priority to each FIFO feature. Justify each.
- Write one paragraph explaining: why would you use both directed and random stimulus on the same design?

### Output

- Document everything in your Knowledge Base document - all topic areas above
- FIFO feature table: Feature | Req-ID | Checker Type | Stimulus | Priority
- 3 Traffic Light assertions in plain English

## Day 11 - Coverage Theory: Code Coverage, Functional Coverage & Covergroups

**Stage: Study Block 2 | Goal: Understand how coverage is measured, modelled, and used as the metric for verification completeness.**

### Learning Topics

#### 11.1 Why Coverage Exists

- The fundamental problem: how do you know when you have done enough testing?
- Without coverage, the answer is "when we run out of time" - not good enough for silicon
- Coverage gives an objective, measurable answer: we are done when we hit our targets
- Coverage is a proxy for confidence - high coverage does not guarantee correctness, but low coverage guarantees insufficient testing

#### 11.2 Code Coverage

Automatically collected by the simulator. Tells you which parts of the RTL code were exercised.

- **Statement coverage**: was this line of RTL ever executed? A line never executed cannot have been tested.
- **Branch coverage**: for every if/case, was every branch taken? A branch never taken is an untested path.
- **Toggle coverage**: did each signal toggle between 0 and 1 at least once? A signal stuck at 0 could be wrong and you'd never know.
- **FSM coverage**:
  - State coverage: was every state entered at least once?
  - Transition coverage: was every arc in the state diagram traversed at least once?
  - The strongest FSM metric - a transition never taken could hide a bug in that condition
- **Condition coverage**: for compound conditions (a && b), was every sub-condition independently true and false?

Target: 100% code coverage is the baseline. It means no dead code and no untested paths.

#### 11.3 Functional Coverage

Written by the DV engineer. Tells you which *meaningful scenarios* were exercised - things the simulator cannot infer from the code alone.

- **Coverpoint**: a variable or expression you want to track
  - Example: coverpoint count - tracks which values of the FIFO count were seen
- **Bins**: the specific values or ranges within a coverpoint that you care about
  - Example: `bins empty = {0}; bins full = {DEPTH}; bins mid = {[1:DEPTH-1]}`
- **Cross coverage**: combinations of two or more coverpoints
  - Example: cross wr_en, rd_en - did you see all four combinations (both off, wr only, rd only, both)?
- **Assertion coverage**: did a specific assertion's cover property ever fire?

#### 11.4 Coverage Closure

- Coverage closure: the process of reaching all your functional coverage targets
- Typical target: 90-100% functional coverage before sign-off (depends on company policy)
- When a bin is not hit: write a directed test to target that specific scenario
- Coverage holes: scenarios your random stimulus never generated - need directed tests to fill them
- Coverage report: the simulator produces a report showing percentage hit for each covergroup

#### 11.5 Linking Coverage to Tests

- Every covergroup item should link to at least one test Req-ID
- A coverage item with no test means it was never deliberately targeted - it might be hit by accident, or might never be hit
- The Coverage Link column in the test plan: FUNC_003 means test case FUNC_003 is responsible for hitting this coverage item
- This link is what makes the verification plan a complete, traceable document

#### 11.6 Designing a Coverage Model

- Start from your feature list - each feature needs at least one coverage item
- For FSM designs: add bins for every state and every transition
- For datapath designs: add bins for boundary values (0, 1, max-1, max) and mid-range
- For data signals: add bins for all-zeros, all-ones, alternating patterns
- For control signals: add bins for all combinations of related signals (use cross)

### Experimental Work

- For the Sequence Detector: list the FSM states and transitions. Write a coverage model in plain English - what coverpoints and bins would you define to say "the FSM has been fully exercised"?
- For the FIFO: write a coverage plan in plain English for count. What bins would you define? Why?
- Write a cross coverage item in plain English for wr_en and rd_en in the FIFO. List all four bins and why each matters.
- Look at your FIFO feature table from Day 10. Add a "Coverage Item" column. Write one coverage item per feature in plain English.
- Write one paragraph: what is the difference between 100% branch coverage and 100% functional coverage? Can you have one without the other?

### Output

- Document everything in your Knowledge Base document - all topic areas above in your own words
- FSM coverage model for Sequence Detector (plain English)
- FIFO coverage plan with bins defined
- Updated FIFO feature table: Feature | Req-ID | Checker | Stimulus | Priority | Coverage Item

# WRAP-UP

## Days 12-14

## Day 12 - Knowledge Base Completion & Self-Review

**Stage: Wrap-up | Goal: Complete all documentation, review everything against the rubric, and ensure the repo is clean.**

### Learning Topics

#### 12.1 Traceability Check

- Every feature from your spec → at least one Req-ID in your feature table
- Every Req-ID → at least one coverage item
- Every coverage item → links back to a Req-ID
- Run through each RTL and check this chain is unbroken

#### 12.2 Verification Metrics & Closure Thinking

- Look at your priority assignments - are all P0 features covered?
- Are all corner cases listed in your spec captured as Req-IDs?
- Are there any features with no coverage item assigned?
- What would a DV engineer need to do next to actually run these tests? (Preview of the next assignment)

### Experimental Work

- Complete all KB entries for Days 1-11 that are missing or incomplete.
- Finalise the Issue Log - every problem encountered across all 14 days must have an entry.
- Do a self-review against the evaluation rubric below. For each criterion, write one honest sentence on where your work stands.
- Clean up the Git repo: consistent commit messages, no junk files, all deliverables present.
- Do a final check of RTL_Specifications.docx - are all sections complete for all 3 RTLs?

### Output

- Complete docs/Knowledge_Base.docx with all entries
- Complete issues/ISSUE_LOG.md
- Clean, committed repo
- KB entry: traceability gaps you found and fixed

## Day 13 - Final Reflection & Presentation Preparation

**Stage: Wrap-up | Goal: Write your final reflection and prepare for the Day 14 presentation.**

### Experimental Work

- Each member writes their own Final Reflection in the KB (Part C):
  - What I understood well
  - What was genuinely difficult
  - The most important thing I learned
  - One thing I would do differently
  - One question I still have
- As a group, prepare your presentation walkthrough. Every member must be able to cover their assigned section.
- Do a dry run - practice the design walkthrough, spec walkthrough, and DV concepts section out loud.

### Output

- Final Reflection entries in Knowledge Base (one per member)
- Presentation ready for Day 14

## Day 14 - Submission & Presentation

**Stage: Wrap-up | Goal: Submit all artifacts and present to the DV/RTL team.**

### Submission Checklist

| **#** | **Item**                | **Requirement**                                                    |
| ----- | ----------------------- | ------------------------------------------------------------------ |
| 1     | RTL_Specifications.docx | All 3 RTLs, every section complete, RTL code included              |
| 2     | Knowledge_Base.docx     | Day-by-day entries (Days 1-13) + Final Reflection (one per member) |
| 3     | ISSUE_LOG.md            | Every problem, its cause, and its resolution                       |
| 4     | Git repository          | Clean structure, regular commits, all files present and runnable   |

### Presentation Format

| **Item**     | **Details**                                                       |
| ------------ | ----------------------------------------------------------------- |
| Duration     | 20-30 minutes per group including Q&A                             |
| Audience     | DV / RTL engineering team                                         |
| Format       | Slide deck - polished, structured, one slide per major topic area |
| Who presents | Every member must speak                                           |

### Presentation Checklist - Every Member Must Be Able to Cover

| **Area**         | **What you must demonstrate**                                                         |
| ---------------- | ------------------------------------------------------------------------------------- |
| RTL walkthrough  | For one RTL: interface table, FSM/datapath, and one corner case - explained clearly   |
| Spec walkthrough | Open RTL_Specifications.docx and walk through one design's sections                   |
| FSM explanation  | Draw or point to a state diagram; explain entry condition and output for each state   |
| DV concepts      | Explain: what is a feature, what is a Req-ID, what is a checker, what is a coverpoint |
| Coverage model   | Explain one coverpoint and why it matters for that design                             |
| Issue log        | Name one real problem encountered, its cause, and how it was resolved                 |
| Final reflection | Read your own Final Reflection - honest and specific                                  |

## Evaluation Focus

| **Criterion**                                                         | **Weight** |
| --------------------------------------------------------------------- | ---------- |
| Depth of understanding - can you explain every decision?              | 25%        |
| Three RTLs - correctness, clean code, spec quality                    | 25%        |
| Study Block documentation - KB entries thorough and in your own words | 20%        |
| DV thinking - feature list, coverage model, test category reasoning   | 15%        |
| Issue log and reflection - honest, specific, detailed                 | 10%        |
| Presentation and Q&A                                                  | 5%         |

## Appendix A - Knowledge Base Structure

Your Knowledge_Base.docx must have three parts:

**Part A - Daily Entries (Days 1-13)**

Each entry must include:

- What topics you studied
- Key concepts in your own words (no copy-paste from the internet)
- Experimental work outputs and observations
- Any bugs or confusions encountered

**Part B - Issue Log**

Each issue must include:

- Day it occurred
- What happened
- What caused it
- How it was resolved (or if still unresolved, what you tried)

**Part C - Final Reflection (one per member)**

- What I understood well
- What was genuinely difficult
- The most important thing I learned
- One thing I would do differently
- One question I still have

## Appendix B - Resources

- SystemVerilog simulator: EDA Playground - <https://www.edaplayground.com>
- Worked examples: example_rtl_and_testplan/ - RTL, spec doc, and KB template
- Study base: DV Fundamentals (Class 0/1) and SV/RTL Curriculum notes
- Reference RTLs for extra study: Week-2 UART / SPI / APB repositories