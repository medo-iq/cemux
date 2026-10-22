# CemuX development roadmap

This roadmap separates functionality verified in the repository from work that has not been implemented. Status reflects the source and tests reviewed on 2026-10-22; it is not a release plan or a claim about work in progress.

For current setup and feature details, see the [README](README.md). The [PRD](CemuX_PRD.md) is an earlier proposal and is not authoritative for current behavior.

## Implemented

Implementation status was verified against `lib/`. Existing tests cover CPU execution, registers, memory, parsing, controller behavior, and a widget.

- [x] Flutter app with a GetX controller separating UI actions from the Dart CPU engine.
- [x] CPU state with `AX`, `BX`, `CX`, `DX`, byte register names, `PC`, and `IR`.
- [x] Fixed-size memory model (32 integer cells by default), including bounds checks.
- [x] Parser for the supported assembly-like syntax, with source-line-aware validation and `;` / `#` comments.
- [x] Registry-based instruction dispatch and separate handlers for `MOV`, `XCHG`, `ADD`, `SUB`, `INC`, `DEC`, `MUL`, `DIV`, `AND`, `OR`, `XOR`, `ROL`, `ROR`, and `RET`.
- [x] Visible fetch, decode, and execute phases; manual phase stepping; timed run/pause; reset; and an auto-run instruction guard.
- [x] Editor with syntax highlighting, line numbers, current/error line feedback, suggestions, and instruction insertion controls.
- [x] CPU state panels and built-in example programs.
- [x] Tests for CPU execution, registers, memory, parsing, controller behavior, and a widget.

`ROL` and `ROR` currently validate a rotate count of one only. The implemented instruction set is a limited teaching model and is not a complete 8086 implementation.

## In progress

No in-progress work is identified by the reviewed repository documentation or implementation. Update this section when a specific, active effort is confirmed; do not use it to imply unverified progress.

## Planned

The following items appeared as future work in the earlier roadmap or product proposal and are not represented as implemented by the current source:

- [ ] Compare instructions and processor flags.
- [ ] Conditional branches that use flags.
- [ ] Stack pointer, stack operations, and subroutine support.
- [ ] Breakpoints and reverse/step-back execution.
- [ ] Larger memory and an expanded memory viewer.
- [ ] Additional instruction semantics and addressing modes, with a clearly defined compatibility target.
- [ ] Confirmed platform support/build matrix and release documentation.
- [ ] Screenshots or demo materials, once created and approved for publication.

These are candidate directions, not scheduled commitments. Prioritize educational clarity and tests when selecting future work.
