# CemuX — CPU Emulator

**CemuX** is a Flutter educational CPU simulator for Computer Engineering students. It demonstrates how a simplified processor executes instructions through the cycle:

```text
Fetch -> Decode -> Execute
```

This is not a full 8086 emulator. The current implementation is an MVP focused on clarity, step-by-step execution, and a clean architecture that can grow safely.

## Current MVP

CemuX currently implements:

- A pure Dart CPU engine with no Flutter dependency
- Four general-purpose registers: `R1`, `R2`, `R3`, `R4`
- Special registers: `PC` and `IR`
- Fixed-size memory with 32 integer cells
- Assembly-like parser with clear validation errors
- Instruction registry and separate instruction handlers
- Manual step execution
- Auto-run with pause and cycle guard
- Flutter UI connected through GetX
- Live register and memory display
- Basic current-line and phase visualization

## Supported Instructions

| Category | Instructions |
| --- | --- |
| Data | `LOAD`, `STORE`, `MOV` |
| Arithmetic | `ADD`, `SUB` |
| Logic | `AND`, `OR`, `NOT` |
| Control | `JMP` |

## Example Program

```asm
LOAD R1 10
LOAD R2 5
ADD R1 R2
STORE R1 0
```

Expected result:

- `R1 = 15`
- `Memory[0] = 15`

## Architecture

The project follows a layered architecture:

```text
Flutter UI
  -> GetX Controller
    -> Pure Dart CPU Engine
      -> Instruction Registry
        -> Instruction Handlers
```

The CPU engine is intentionally independent from Flutter. This keeps the emulator testable, portable, and easier to extend.

## Project Structure

```text
lib/
  app/
    controllers/
    screens/
    widgets/
  colors/
  config/
  core/
    cpu/
    instructions/
    models/
    parser/
  features/
    editor/
    execution/
    memory_view/
    registers/
  main.dart

test/
  core/
    cpu/
    parser/
  widget_test.dart
```

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

## Adding Instructions

To add a new instruction:

1. Create a new `InstructionHandler`.
2. Register it in `InstructionRegistry`.
3. Add parser validation for its syntax.
4. Add engine tests for execution behavior.

The execution loop does not need to change for normal instruction additions.

## Current Limitations

- No flags yet
- No `CMP`
- No conditional jumps
- No stack
- No breakpoints
- No persistence
- `JMP` targets zero-based instruction indexes

## Author

Ahmed Majid

Developed as a Computer Engineering project for UOMUS.
