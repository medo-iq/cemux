# CemuX

CemuX is an educational CPU simulator built with Flutter and Dart. It lets learners write a small assembly-like program and observe a simplified processor move through fetch, decode, and execute phases.

The project aims to make processor state and instruction execution easier to inspect while learning computer architecture. It is a teaching simulator, **not a complete or compatible Intel 8086 emulator**.

## Implemented features

- A Dart CPU engine separated from Flutter UI code.
- A simplified Intel 8086-style register profile: `AX`, `BX`, `CX`, `DX` and their byte names (`AH`, `AL`, `BH`, `BL`, `CH`, `CL`, `DH`, `DL`), plus `PC` and `IR`.
- A 32-cell integer memory model with bounds checking, displayed in the UI.
- An assembly-like parser with source-line-aware validation errors and `;` / `#` comments.
- Manual phase stepping and timed run/pause controls, with a guard that stops auto-run after 1,000 executed instructions.
- An editor with line numbers, syntax highlighting, inline validation, instruction suggestions, and quick insertion.
- Visible execution phase, current instruction, register and memory state, and built-in example programs.
- Unit and widget tests for the CPU, parser, controller, and UI.

## Supported instructions

The simulator currently registers these instructions:

| Category | Instructions |
| --- | --- |
| Data movement | `MOV`, `XCHG` |
| Arithmetic | `ADD`, `SUB`, `INC`, `DEC`, `MUL`, `DIV` |
| Logic | `AND`, `OR`, `XOR` |
| Rotate | `ROL`, `ROR` |
| Program termination | `RET` |

The parser accepts decimal immediates and hexadecimal values with an `H` suffix (for example, `10` and `0AH`). `ROL` and `ROR` currently accept a rotate count of `1` only. Instruction operand forms are validated by the parser; consult the editor's instruction reference and the handler/parser code for exact forms. These instructions model only the behavior implemented by CemuX and do not imply full 8086 semantics.

## Fetch–Decode–Execute

When loading a program, CemuX parses the source into structured instructions. Execution then advances through visible phases:

1. **Fetch:** Read the instruction at the program counter, place its normalized text in the instruction register, and advance `PC`.
2. **Decode:** Mark the decoded instruction and expose the decode phase. Parsing and operand validation have already taken place during program loading.
3. **Execute:** Dispatch the parsed instruction to its registered handler, which updates CPU state. `RET` halts the simulator; execution also halts when the program counter moves beyond the loaded program.

The UI's **Step** action advances one phase at a time. The engine also provides a `run()` method that runs complete instruction cycles.

## Technical architecture

```text
Flutter screens and feature widgets
                |
          GetX controllers
                |
      CPU engine and CPU state
         /             \
 Program parser    Instruction registry
                           |
                  Individual handlers
```

The CPU engine, state, parser, instruction registry, and handlers live in Dart modules under `lib/core/`. Flutter widgets render state and dispatch actions through controllers. GetX is used for UI state management.

## Project structure

```text
lib/
  app/                 Screens, shared widgets, and controllers
  colors/              App color definitions
  config/              Theme and example programs
  core/
    cpu/               CPU engine, state, registers, memory, utilities
    instructions/      Instruction registry and handlers
    models/            Execution phase, status, and snapshots
    parser/            Assembly-like parser and parsed instructions
  features/
    editor/            Code editor, validation, suggestions, highlighting
    quick_panel/       Instruction insertion palette
    reference/         Instruction reference UI
    right_panel/       CPU state and execution controls
  main.dart            App entry point
test/                  Unit and widget tests
android/ ios/ linux/ macos/ web/ windows/
                       Flutter platform project files
.github/
  workflows/           Existing build workflow
CemuX_PRD.md           Historical product requirements proposal
CemuX_Tasks_Roadmap.md Current implementation status and planned work
```

## Prerequisites

- Flutter SDK installed and available on `PATH`.
- A Flutter/Dart SDK compatible with the Dart constraint in [`pubspec.yaml`](pubspec.yaml) (Dart `^3.10.4`).
- For launching on a device or desktop target, the corresponding Flutter platform toolchain and a connected/available target.

The repository contains Flutter platform project files, but it does not define a verified support or release matrix. Check the target's local Flutter setup before relying on a particular platform.

## Setup and run

From the repository root:

```bash
flutter pub get
flutter run
```

To run on a specific connected device, first inspect available targets with `flutter devices`, then use `flutter run -d <device-id>`.

## Test and analyze

```bash
flutter analyze
flutter test
```

## Example program

```asm
MOV AX,0AH
MOV BX,5H
ADD AX,BX
RET
```

`AX` contains `15` (decimal, `000FH`) when the program halts.

## Current limitations

- CemuX is not a full 8086 emulator and does not implement the complete 8086 instruction set, flags, addressing modes, segmented memory, or hardware behavior.
- The current register set is limited to the general registers and byte names listed above, with `PC` and `IR`.
- Memory is a fixed 32-cell integer array; memory-addressing instructions are not currently part of the registered instruction set.
- `ROL` and `ROR` only support a rotate count of one.
- There are no flags, conditional branches, stack, breakpoints, reverse execution, or persisted user programs.
- Platform files exist, but a supported-platform/build matrix and release artifacts are not documented.

## Development roadmap

See [`CemuX_Tasks_Roadmap.md`](CemuX_Tasks_Roadmap.md) for verified implemented functionality, explicitly documented in-progress work, and planned work. [`CemuX_PRD.md`](CemuX_PRD.md) is retained as a historical requirements proposal; its original MVP descriptions do not necessarily match the current implementation.

## Contributing

Contributions are welcome, including beginner-friendly documentation and tests. For substantial changes, discuss scope in an issue first; keep pull requests focused, run formatting, analysis, and tests, and update related documentation. CPU instruction changes should include parser/editor integration where needed and tests for the instruction's behavior. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup and the complete workflow.

## Security

Please report suspected vulnerabilities privately rather than posting exploit details in a public issue. See [`SECURITY.md`](SECURITY.md) for the reporting guidance and current support policy.

## License

CemuX is distributed under the [MIT License](LICENSE). That license does not automatically cover third-party assets or materials; review their individual licensing before reuse.

## Maintainer

**Ahmed Majid** — [@medo-iq](https://github.com/medo-iq)
