# Contributing to CemuX

Thank you for considering a contribution. CemuX is an educational project, and clear explanations, focused bug reports, tests, and documentation improvements are all valuable contributions.

## Before you start

- Read the [README](README.md) for the current implemented behavior.
- Search existing issues and pull requests before opening a new one.
- For a substantial change, open an issue first to discuss scope and approach.
- Do not include secrets, private data, or third-party material without permission.

## Development setup

1. Install Flutter and a Dart SDK compatible with the constraint in [`pubspec.yaml`](pubspec.yaml).
2. Clone the repository and enter its root directory.
3. Fetch dependencies and run the app:

   ```bash
   flutter pub get
   flutter run
   ```

4. Before submitting, run:

   ```bash
   dart format .
   flutter analyze
   flutter test
   ```

Use the platform-specific Flutter toolchain when running on a device or desktop target. Do not change dependencies or generated platform files as part of an unrelated contribution.

## Branch names

Use a short, descriptive prefix and kebab-case name:

- `feat/add-instruction-reference`
- `fix/parser-error-message`
- `docs/update-setup-guide`
- `test/memory-boundaries`

These names are a convention for clarity; they do not imply an automated branch policy.

## Issues and documentation

For bugs, include a minimal reproduction, expected and actual behavior, platform and Flutter/Dart versions, and relevant logs with sensitive information removed. For feature proposals, explain the learner problem, educational value, and alternatives considered.

Documentation changes should link to repository documents using relative paths, distinguish current behavior from proposed behavior, and avoid claims that are not verifiable in the source or tests.

## CPU instruction contributions

An instruction is part of a small simulator, not a promise of complete 8086 compatibility. Before implementing one:

1. Describe its educational purpose, syntax, operands, and expected effects in the issue or pull request.
2. Check the existing handler and registry patterns under `lib/core/instructions/`.
3. Update parser operand-count and operand-type validation in `lib/core/parser/program_parser.dart`.
4. Update relevant editor/reference or insertion metadata when the new instruction should be suggested or documented there.
5. Add focused tests for normal behavior, invalid operands, and relevant edge cases. Keep any register-width or immediate-value behavior consistent with the documented simulator model.
6. Update the README or roadmap when the set of implemented instructions or documented limitations change.

For each instruction, explain any intentional difference from real 8086 behavior rather than suggesting broader compatibility.

## Pull request workflow

- Keep each pull request focused and describe the user-visible or educational effect.
- Link a related issue when one exists; otherwise explain why the change is useful.
- Include tests and documentation updates appropriate to the change.
- Run formatting, analysis, and tests, and report any command that could not be run.
- Do not include unrelated refactoring, generated output, or dependency changes.
- Complete the checklist in [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md).

Maintainers may request clarification or changes before merging. A pull request is not accepted until the repository's review process is complete.
