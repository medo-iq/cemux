# 🚀 CemuX — Development Tasks Roadmap

**Project:** CemuX (CPU Emulator)  
**Goal:** Build a clean, extensible, Flutter-based CPU simulator (MVP → Advanced)  
**Strategy:** Phase-based execution with clear deliverables  

---

# 🧠 Phase 0 — Project Setup (Foundation)

## 🎯 Goal
Initialize clean Flutter project with scalable architecture

## ✅ Tasks
- [ ] Create Flutter project (`cemux`)
- [ ] Setup folder structure:
  - [ ] `lib/core/`
  - [ ] `lib/features/cpu/`
  - [ ] `lib/features/editor/`
  - [ ] `lib/features/ui/`
- [ ] Setup state management (GetX or preferred)
- [ ] Setup theme (dark mode default)
- [ ] Configure app name:
  - [ ] Display: **CemuX**
- [ ] Remove default Flutter boilerplate

---

# ⚙️ Phase 1 — Core CPU Engine (MVP)

## 🎯 Goal
Build pure Dart CPU engine (NO Flutter dependency)

## ✅ Tasks

### 🔹 CPU State
- [ ] Create Registers model:
  - [ ] R1, R2, R3, R4
  - [ ] PC (Program Counter)
  - [ ] IR (Instruction Register)
- [ ] Create Memory model:
  - [ ] Fixed array (size: 32)
  - [ ] Read / Write methods
- [ ] Create CPU State object

---

### 🔹 Instruction System (CRITICAL)
- [ ] Implement Instruction Registry (Map-based)
- [ ] Create base Instruction Handler interface
- [ ] Implement MVP Instructions:
  - [ ] LOAD
  - [ ] STORE
  - [ ] MOV
  - [ ] ADD
  - [ ] SUB
  - [ ] AND
  - [ ] OR
  - [ ] NOT
  - [ ] JMP

---

### 🔹 Execution Engine
- [ ] Implement Fetch logic
- [ ] Implement Decode logic
- [ ] Implement Execute logic
- [ ] Implement cycle runner (step)
- [ ] Implement auto-run loop
- [ ] Implement max cycle guard (prevent infinite loops)

---

### 🔹 Parser
- [ ] Parse text into instructions
- [ ] Strip comments (`;`, `#`)
- [ ] Validate syntax
- [ ] Normalize instructions

---

# 🔄 Phase 2 — State Management Layer

## 🎯 Goal
Connect CPU engine to UI safely

## ✅ Tasks
- [ ] Create GetX Controller (CPUController)
- [ ] Expose observable state:
  - [ ] Registers
  - [ ] Memory
  - [ ] Current instruction
  - [ ] Current phase (FETCH / DECODE / EXECUTE)
- [ ] Implement controller actions:
  - [ ] loadProgram()
  - [ ] step()
  - [ ] autoRun()
  - [ ] pause()
  - [ ] reset()

---

# 🧪 Phase 3 — Code Editor

## 🎯 Goal
Allow user to write and edit assembly code

## ✅ Tasks
- [ ] Build code editor UI:
  - [ ] Multi-line input
  - [ ] Line numbers
- [ ] Highlight current executing line
- [ ] Add basic syntax highlighting:
  - [ ] Instructions
  - [ ] Registers
  - [ ] Numbers
- [ ] Show error messages:
  - [ ] Invalid instruction
  - [ ] Invalid operand

---

# 🧠 Phase 4 — CPU Visualization UI

## 🎯 Goal
Make execution understandable visually

## ✅ Tasks

### 🔹 Registers Panel
- [ ] Display R1–R4
- [ ] Display PC and IR
- [ ] Animate changed values

---

### 🔹 Memory Panel
- [ ] Show memory cells (0–31)
- [ ] Highlight updated cells
- [ ] Show values clearly

---

### 🔹 Execution Panel
- [ ] Show:
  - [ ] Current Instruction
  - [ ] Operation description
- [ ] Show phase:
  - [ ] FETCH
  - [ ] DECODE
  - [ ] EXECUTE

---

### 🔹 Focus Mode
- [ ] Step animation:
  - [ ] Highlight instruction
  - [ ] Show decode
  - [ ] Show execution result

---

# 🎮 Phase 5 — Execution Controls

## 🎯 Goal
Control simulation behavior

## ✅ Tasks
- [ ] Add buttons:
  - [ ] Load
  - [ ] Step
  - [ ] Run
  - [ ] Pause
  - [ ] Reset
- [ ] Add speed control (Auto mode)
- [ ] Disable invalid actions during execution

---

# 🧪 Phase 6 — Testing & Validation

## 🎯 Goal
Ensure system correctness

## ✅ Tasks
- [ ] Create test programs:
  - [ ] Arithmetic test
  - [ ] Logic test
  - [ ] Jump test
- [ ] Validate:
  - [ ] Register updates
  - [ ] Memory writes
  - [ ] Jump behavior
- [ ] Test edge cases:
  - [ ] Invalid instruction
  - [ ] Memory overflow
  - [ ] Infinite loop

---

# 🎨 Phase 7 — UI Polish (Competition Level)

## 🎯 Goal
Make it visually professional

## ✅ Tasks
- [ ] Improve layout (emu8086 style)
- [ ] Add transitions/animations
- [ ] Improve spacing & alignment
- [ ] Ensure responsive design (mobile + desktop)
- [ ] Add dark/light toggle (optional)

---

# 🚀 Phase 8 — Advanced Features (Post-MVP)

## 🎯 Goal
Prepare for expansion

## ✅ Tasks

### 🔹 Instruction Expansion
- [ ] Add CMP
- [ ] Add Flags (ZERO, NEGATIVE)
- [ ] Add Conditional Jumps (JZ, JNZ)

---

### 🔹 Stack System
- [ ] Add SP register
- [ ] Implement PUSH / POP

---

### 🔹 Debugging Tools
- [ ] Add Breakpoints
- [ ] Add Step Back (state snapshots)
- [ ] Add Execution history

---

### 🔹 Memory Upgrade
- [ ] Expand memory (256 cells)
- [ ] Add scrollable memory viewer

---

# 📊 Phase 9 — Finalization

## 🎯 Goal
Prepare for presentation / competition

## ✅ Tasks
- [ ] Clean codebase
- [ ] Add README.md
- [ ] Add screenshots
- [ ] Add demo scripts
- [ ] Optimize performance
- [ ] Build release version

---

# 🏁 FINAL GOAL

```text
CemuX = Clean + Educational + Extensible CPU Emulator