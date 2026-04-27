# CemuX — Product Requirements Document

**Version:** 1.0 (MVP)
**Date:** April 12, 2026
**Status:** Draft for Review
**Platform:** Flutter (Mobile & Desktop)

---

## 1. Executive Summary

CemuX is an interactive, offline CPU emulator built with Flutter, designed to teach Computer Engineering students how a processor fetches, decodes, and executes instructions. Students write simple assembly-like programs and watch — cycle by cycle — how data moves through registers, memory, and the program counter.

**The problem:** CPU architecture courses rely on static diagrams and dry textbook explanations. Students memorize concepts without ever seeing a processor "think." Existing tools like emu8086 are powerful but overwhelming for beginners, and none are cross-platform mobile-friendly apps students can carry in their pockets.

**The solution:** CemuX strips the CPU down to its essentials — nine instructions, four registers, a small memory space — and makes every execution cycle visible and interactive. It is simple enough for a first-year student yet architected to grow into a full emulator over time.

---

## 2. Goals and Objectives

### 2.1 Educational Goals

- Demystify the Fetch–Decode–Execute cycle through real-time visualization.
- Build intuition for how registers, memory, and the program counter interact.
- Provide a sandbox where students can experiment freely without fear of breaking anything.
- Serve as a companion tool for Microprocessors and Computer Architecture courses.

### 2.2 Technical Goals

- Deliver a modular instruction engine where adding a new instruction requires registering a single handler — zero changes to the core execution loop.
- Maintain a clean separation between the CPU engine (pure Dart logic) and the UI layer (Flutter widgets).
- Ensure the entire app runs offline with no backend dependency.

### 2.3 UX Goals

- Present a clean, minimal interface inspired by emu8086 but free of visual clutter.
- Enable "Focus Mode" — one cycle at a time — so students can pause and reason about each step.
- Make the app immediately usable without a tutorial; the layout itself should teach.

---

## 3. Target Users

### 3.1 Primary Persona — "The First-Year Student"

A Computer Engineering student encountering CPU architecture for the first time. They understand basic programming but have never thought about what happens below high-level code. They need a visual, forgiving environment.

### 3.2 Secondary Persona — "The Curious Tinkerer"

A second- or third-year student revisiting fundamentals or preparing for exams. They want to write small programs, trace execution manually, and verify their understanding against the emulator.

### 3.3 Tertiary Persona — "The Instructor"

A professor or teaching assistant who wants to demo CPU execution live during a lecture or assign hands-on exercises.

### 3.4 Use Scenarios

| Scenario | Description |
|---|---|
| Lecture Demo | Instructor projects CemuX, writes a short program, steps through it while explaining each cycle. |
| Self-Study | Student loads a sample program, runs it in step mode, and traces how values change in registers and memory. |
| Assignment | Student writes an assembly program to solve a given task, then runs and verifies correctness in CemuX. |
| Exam Prep | Student practices predicting register/memory states after execution, then checks against CemuX output. |

---

## 4. Core Features (MVP)

### 4.1 Code Editor Panel

- A text input area where students write assembly-like instructions, one per line.
- Syntax highlighting for instruction mnemonics, register names, and numeric values.
- Line numbers displayed alongside the code.
- The currently executing line is visually highlighted during simulation.
- Basic error feedback: invalid instruction or malformed operand surfaces a clear, human-readable message.

### 4.2 Register Panel

- Displays four general-purpose registers: R1, R2, R3, R4.
- Displays special registers: PC (Program Counter) and IR (Instruction Register).
- Each register shows its current value in decimal (with an optional hex toggle in future versions).
- When a register value changes during a cycle, it briefly animates (highlight or pulse) to draw attention.

### 4.3 Memory View

- Displays a linear array of memory cells (addresses 0–31 for MVP).
- Each cell shows its address and stored value.
- Cells that were read or written in the current cycle are visually distinguished.
- Memory is initialized to zero on program load.

### 4.4 Execution Controls

| Control | Behavior |
|---|---|
| **Load** | Parses the code, loads instructions into memory, resets all state. |
| **Step** | Executes exactly one Fetch–Decode–Execute cycle, then pauses. |
| **Auto Run** | Continuously executes cycles at a configurable speed (e.g., 500ms–2000ms per cycle). |
| **Pause** | Halts auto-run, preserving current state. |
| **Reset** | Clears all registers and memory, resets PC to zero. |

### 4.5 Execution Visualization

- During each cycle, the app displays the current phase: **FETCH → DECODE → EXECUTE**.
- A status bar or label shows a plain-language description of what is happening, e.g., "Loading value 5 into register R1."
- Animated transitions between phases reinforce the sequential nature of the cycle.

---

## 5. Instruction Set (MVP)

The MVP supports nine instructions. All values are integers. Registers are R1–R4. Memory addresses are integers (0–31).

### 5.1 Data Movement

| Instruction | Syntax | Description |
|---|---|---|
| **LOAD** | `LOAD Rx N` | Places the immediate value N into register Rx. Think of it as "put this number into this box." |
| **STORE** | `STORE Rx addr` | Copies the value in register Rx into memory at the given address. The register keeps its value; memory gets a copy. |
| **MOV** | `MOV Rd Rs` | Copies the value from source register Rs into destination register Rd. Rs is unchanged. |

### 5.2 Arithmetic & Logic

| Instruction | Syntax | Description |
|---|---|---|
| **ADD** | `ADD Rd Rs` | Adds the value in Rs to the value in Rd and stores the result in Rd. Example: if R1=3 and R2=7, then `ADD R1 R2` makes R1=10. |
| **SUB** | `SUB Rd Rs` | Subtracts the value in Rs from the value in Rd. Result goes into Rd. |
| **AND** | `AND Rd Rs` | Performs a bitwise AND between Rd and Rs. Result goes into Rd. |
| **OR** | `OR Rd Rs` | Performs a bitwise OR between Rd and Rs. Result goes into Rd. |
| **NOT** | `NOT Rd` | Flips all bits in Rd (bitwise complement). Only one operand. |

### 5.3 Control Flow

| Instruction | Syntax | Description |
|---|---|---|
| **JMP** | `JMP addr` | Sets the Program Counter to addr, causing execution to jump to that line. This is how loops and branching begin — even without conditions in the MVP. |

### 5.4 Sample Program

```
LOAD R1 10
LOAD R2 20
ADD  R1 R2
STORE R1 0
```

This program loads 10 into R1, loads 20 into R2, adds them (R1 becomes 30), and stores the result at memory address 0.

---

## 6. Execution Model

### 6.1 The Fetch–Decode–Execute Cycle

CemuX follows the classical three-phase cycle:

**Fetch:** The CPU reads the instruction at the address pointed to by the Program Counter (PC). The instruction is placed into the Instruction Register (IR). The PC increments by one to point to the next instruction.

**Decode:** The CPU parses the IR content to identify the operation (mnemonic) and its operands (registers, values, or addresses).

**Execute:** The CPU performs the operation — moving data, computing a result, or updating the PC (in the case of JMP).

### 6.2 Program Counter Behavior

The PC starts at 0. After each fetch, it increments by 1. When a JMP instruction executes, the PC is overwritten with the target address, causing the next fetch to occur at that new location. If the PC exceeds the number of loaded instructions, execution halts.

### 6.3 JMP and Control Flow

In the MVP, JMP is unconditional — it always jumps. This alone enables infinite loops (JMP to an earlier line) and skip-ahead patterns. Conditional jumps (requiring flags and CMP) are reserved for a future version.

### 6.4 Halting

Execution halts when the PC points beyond the last instruction and no JMP redirects it. There is no explicit HALT instruction in the MVP; the program simply ends.

---

## 7. System Architecture

This is the most critical section. CemuX is built in layers with strict boundaries so that the CPU engine is a pure-Dart library with no Flutter dependency, and the UI layer consumes it through a well-defined state interface.

### 7.1 Layer Diagram

```
┌─────────────────────────────────────────────┐
│                  UI Layer                   │
│         (Flutter Widgets + GetX)            │
│  ┌──────────┐ ┌──────────┐ ┌─────────────┐ │
│  │  Code    │ │ Register │ │   Memory    │ │
│  │  Editor  │ │  Panel   │ │    View     │ │
│  └──────────┘ └──────────┘ └─────────────┘ │
│  ┌──────────────────────────────────────┐   │
│  │       Execution Controls + Status    │   │
│  └──────────────────────────────────────┘   │
├─────────────────────────────────────────────┤
│            State Management Layer           │
│              (GetX Controller)              │
│     Bridges UI ↔ CPU Engine via state       │
├─────────────────────────────────────────────┤
│               CPU Engine Layer              │
│                (Pure Dart)                  │
│  ┌──────────────────────────────────────┐   │
│  │          Execution Engine            │   │
│  │   fetch() → decode() → execute()    │   │
│  └──────────────┬───────────────────────┘   │
│                 │                            │
│  ┌──────────────▼───────────────────────┐   │
│  │      Instruction Registry            │   │
│  │  Map<String, InstructionHandler>     │   │
│  │                                      │   │
│  │  "LOAD" → LoadHandler                │   │
│  │  "ADD"  → AddHandler                 │   │
│  │  "JMP"  → JmpHandler                 │   │
│  │   ...                                │   │
│  └──────────────────────────────────────┘   │
│  ┌─────────────┐  ┌────────────────────┐    │
│  │  Registers  │  │      Memory        │    │
│  │  R1–R4,PC,IR│  │  int[32] array     │    │
│  └─────────────┘  └────────────────────┘    │
└─────────────────────────────────────────────┘
```

### 7.2 CPU Engine Layer (Pure Dart, No Flutter)

This layer contains all emulation logic. It has no dependency on Flutter, meaning it can be unit-tested independently.

**Execution Engine:** Owns the fetch–decode–execute loop. It reads the current instruction from the program list using the PC, decodes it into an operation name and operand list, then looks up the matching handler in the Instruction Registry and invokes it.

**Instruction Registry:** A map from mnemonic strings (e.g., "LOAD", "ADD") to handler objects. Each handler implements a single interface method: `execute(operands, cpuState)`. To add a new instruction, a developer creates a new handler class and registers it — no other file changes.

**CPU State:** A data object holding the register file, memory array, program counter, instruction register, and current phase. The Execution Engine reads and mutates this object; the UI layer observes it.

### 7.3 Instruction Handler Interface

Every instruction handler conforms to a single contract:

- **Input:** A list of parsed operands and a reference to the current CPU state.
- **Output:** The handler mutates the CPU state directly (updates a register, writes to memory, or modifies the PC).
- **Validation:** Each handler validates its own operands and throws a descriptive error if they are malformed.

This is the extensibility mechanism. Adding CMP in the future means writing a CmpHandler and registering it as `"CMP" → CmpHandler`. The execution loop, parser, and UI remain untouched.

### 7.4 State Management Layer (GetX Controller)

A GetX controller wraps the CPU Engine and exposes observable state to the UI. It provides methods like `loadProgram()`, `step()`, `autoRun()`, `pause()`, and `reset()`. The UI never interacts with the CPU Engine directly.

### 7.5 UI Layer (Flutter Widgets)

Stateless or reactive widgets that read from the GetX controller and render the code editor, register panel, memory view, and execution controls. The UI is a consumer — it displays state and dispatches user actions. It contains zero emulation logic.

### 7.6 Extensibility Summary

| Action | What to do | What NOT to touch |
|---|---|---|
| Add a new instruction | Create a handler class, register it in the registry. | Execution loop, parser, UI. |
| Add new registers | Extend the CPU State data object. | Instruction handlers (unless they use new registers). |
| Add flags | Extend CPU State with a flags field. | Existing handlers (unless they now set flags). |
| Add a new UI panel | Create a new widget, bind it to the GetX controller. | CPU Engine. |

---

## 8. Data Model

### 8.1 Registers

| Register | Type | Initial Value | Description |
|---|---|---|---|
| R1–R4 | int | 0 | General-purpose registers for computation. |
| PC | int | 0 | Program Counter — index of the next instruction to fetch. |
| IR | String | "" | Instruction Register — raw text of the currently fetched instruction. |

### 8.2 Memory

A fixed-size array of 32 integer cells, indexed 0–31, all initialized to zero. Each cell holds a single integer value. In the MVP, memory is used exclusively by STORE (write) and can be extended for LOAD-from-memory in future versions.

### 8.3 Instruction Representation

Each parsed instruction is represented as a structured object with three fields:

- **mnemonic** (String): The operation name, e.g., "ADD".
- **operands** (List): Parsed operands — register identifiers or integer values.
- **lineNumber** (int): The original line number in the source code, used for highlighting.

### 8.4 CPU State Snapshot

At any point during execution, the full CPU state can be captured as a snapshot containing: all register values, the full memory array, the PC, the IR, and the current phase (FETCH / DECODE / EXECUTE). This snapshot model enables future features like undo/step-back.

---

## 9. UI/UX Design

### 9.1 Design Principles

- **Clarity over decoration.** Every pixel must teach. No ornamental gradients, no unnecessary icons.
- **State is always visible.** The student should never wonder "what just happened?" — changed values animate, the current line highlights, and the phase label updates.
- **One action, one result.** Pressing "Step" does exactly one cycle. No hidden side effects.

### 9.2 Layout (Landscape / Desktop)

```
┌────────────────────┬─────────────────────┐
│                    │    Register Panel    │
│    Code Editor     │  R1  R2  R3  R4     │
│    (with line      │  PC      IR         │
│     numbers &      ├─────────────────────┤
│     highlighting)  │    Memory View       │
│                    │  [0]=0  [1]=0  ...   │
├────────────────────┴─────────────────────┤
│  [ Load ] [ Step ] [ Run ] [ Pause ] [ Reset ]  │
│  Phase: EXECUTE  |  "Adding R2 to R1"           │
└──────────────────────────────────────────────────┘
```

### 9.3 Layout (Portrait / Mobile)

On narrow screens, panels stack vertically: Code Editor on top, then a tabbed area below toggling between Registers and Memory, with execution controls pinned to the bottom.

### 9.4 Color and Typography

- Dark theme by default (easier on the eyes during study sessions), with a light theme toggle.
- Monospace font for the code editor and memory values.
- A calm, muted accent color (teal or blue-grey) for highlights and active states.
- Changed values flash briefly in a warm accent color (amber or soft green) before settling.

### 9.5 Focus Mode

When the student presses "Step," the interface does three things in sequence: highlights the fetched line, shows the decoded instruction in plain language, then animates the execution result (register change, memory write, or PC jump). Each phase is visible long enough to be understood before transitioning.

---

## 10. User Flow

**Step 1 — Launch.** The student opens CemuX and sees an empty code editor on the left, zeroed registers and memory on the right, and execution controls at the bottom.

**Step 2 — Write or Load.** The student either types a program directly or selects one from a list of built-in examples (e.g., "Add Two Numbers," "Simple Loop").

**Step 3 — Load Program.** The student presses "Load." The app parses the code, validates it, and reports any errors. If valid, the instructions are loaded and the UI resets all state.

**Step 4 — Choose Mode.** The student decides between Step mode (manual, one cycle at a time) or Auto Run (continuous at a set speed).

**Step 5 — Execute.** In Step mode, each press advances one cycle. The current line highlights, the phase label updates, and changed values animate. In Auto Run, this happens automatically with a visible pause between cycles.

**Step 6 — Observe.** The student watches registers and memory update, reads the plain-language status messages, and builds understanding of how the CPU processes each instruction.

**Step 7 — Reset or Modify.** The student resets to try again, edits the code, or loads a different program.

---

## 11. Non-Functional Requirements

### 11.1 Performance

- Step execution must complete in under 16ms (one frame at 60fps) to ensure animations remain smooth.
- Auto-run mode must handle programs of up to 100 instructions without lag or frame drops.
- Memory and register UI updates must be reactive and efficient — only changed cells should re-render.

### 11.2 Simplicity

- A student with no prior emulator experience should be able to write and run a three-line program within two minutes of opening the app.
- Error messages must be educational, not cryptic. Example: "Line 3: LOAD expects a register and a number, like LOAD R1 5" — not "SyntaxError at token 2."

### 11.3 Maintainability

- The CPU Engine must have zero Flutter imports, enabling independent unit testing.
- Each instruction handler must be self-contained — its logic, validation, and error messages live in one file.
- Code coverage for the CPU Engine layer should target 90% or above.

### 11.4 Extensibility

- Adding a new instruction must require creating one handler file and one registry entry.
- The architecture must accommodate future additions (flags, stack, interrupts) without restructuring the core execution loop.

### 11.5 Accessibility

- All interactive elements must be keyboard-navigable on desktop.
- Text sizes must respect system accessibility settings.
- Color is never the sole indicator of state change — animations and labels supplement it.

---

## 12. Future Roadmap

The MVP is version 1.0. The following features are planned for subsequent releases, ordered by priority and dependency.

### Phase 2 — Comparison and Flags

- Add a Flags register (Zero, Carry, Sign).
- Introduce the CMP instruction, which subtracts two values and sets flags without storing the result.
- Flags panel in the UI.

### Phase 3 — Conditional Jumps

- Add JZ (Jump if Zero), JNZ (Jump if Not Zero), JG (Jump if Greater), JL (Jump if Less).
- These depend on flags from Phase 2.
- Enable meaningful branching logic and conditional programs.

### Phase 4 — Stack and Subroutines

- Add a Stack Pointer (SP) register and stack memory region.
- Introduce PUSH, POP, CALL, and RET instructions.
- Stack visualization panel in the UI.

### Phase 5 — Advanced Features

- Breakpoints: click a line number to set/remove a breakpoint; execution pauses when it hits one.
- Step-back / undo: navigate backward through execution history using state snapshots.
- Expanded memory (256 cells) with scrollable, searchable memory view.
- Instruction timing simulation (cycle counts per instruction).

### Phase 6 — Toward Full 8086

- Expand register set (AX, BX, CX, DX, segment registers).
- Add addressing modes (direct, indirect, indexed).
- Interrupt handling.
- I/O simulation.

---

## 13. Success Metrics

### 13.1 Usability Metrics

| Metric | Target |
|---|---|
| Time to first successful program run (new user) | Under 2 minutes |
| Task completion rate for "Add Two Numbers" exercise | 95% of test users |
| System Usability Scale (SUS) score | 80+ (grade A) |

### 13.2 Educational Impact

| Metric | Target |
|---|---|
| Student self-reported understanding of fetch–decode–execute cycle (post-use survey) | 4.0+ out of 5.0 |
| Correct answers on a 10-question CPU concepts quiz (post-use vs. control group) | 20% improvement |

### 13.3 Technical Quality

| Metric | Target |
|---|---|
| CPU Engine unit test coverage | 90%+ |
| Average step execution time | Under 5ms |
| Crash rate during demo sessions | 0% |

### 13.4 Adoption

| Metric | Target |
|---|---|
| Instructor willingness to use in lectures (survey) | 80%+ |
| Student return usage within one week | 60%+ |

---

## 14. Constraints

### 14.1 Technical Constraints

- The app must run entirely offline. No network calls, no backend, no cloud sync.
- All logic must be implemented in Dart. No native platform channels for core emulation.
- The app must compile and run on Android, iOS, Windows, macOS, and Linux from a single Flutter codebase.

### 14.2 Scope Constraints

- The MVP is limited to nine instructions. Feature creep (adding "just one more instruction") is the primary risk and must be actively resisted until MVP is shipped and validated.
- No file I/O, no persistent storage of user programs in MVP. Programs are typed or selected from examples each session.

### 14.3 Design Constraints

- Educational clarity takes priority over technical completeness. If a design choice makes the app more realistic but harder to understand, choose understanding.
- The UI must not assume the user knows what a register is. Tooltips or inline hints should gently explain concepts on first encounter.

### 14.4 Timeline

- MVP development target: 4–6 weeks for a solo developer or a small academic team.
- The architecture investment in Phase 1 (modular instruction engine) pays dividends in every subsequent phase.

---

## Appendix A — Glossary

| Term | Definition |
|---|---|
| **PC (Program Counter)** | A register that holds the address of the next instruction to fetch. |
| **IR (Instruction Register)** | A register that holds the instruction currently being decoded/executed. |
| **Register** | A small, fast storage location inside the CPU used for computation. |
| **Memory** | A larger, slower storage area addressed by number, used to hold data. |
| **Mnemonic** | The human-readable name of an instruction (e.g., ADD, LOAD). |
| **Operand** | The data an instruction operates on — a register name, value, or address. |
| **Fetch–Decode–Execute** | The three-phase cycle every CPU repeats to process instructions. |

---

## Appendix B — Sample Programs

### B.1 — Add Two Numbers

```
LOAD  R1 15
LOAD  R2 25
ADD   R1 R2
STORE R1 0
```

Expected result: R1 = 40, Memory[0] = 40.

### B.2 — Swap Two Values

```
LOAD  R1 7
LOAD  R2 3
MOV   R3 R1
MOV   R1 R2
MOV   R2 R3
```

Expected result: R1 = 3, R2 = 7, R3 = 7.

### B.3 — Infinite Loop (Demonstrating JMP)

```
LOAD  R1 1
ADD   R1 R1
JMP   1
```

Expected result: R1 doubles every iteration (1 → 2 → 4 → 8 → ...). Execution never halts — student must press Pause.

---

*End of Document*
