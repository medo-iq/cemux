// ─────────────────────────────────────────────────────────────────────────────
// Editor state — pure data types, no Flutter or GetX dependencies.
// ─────────────────────────────────────────────────────────────────────────────

/// Distinguishes instruction mnemonics from register names in suggestions.
enum SuggestionKind { instruction, register }

/// A single autocomplete suggestion returned by [SuggestionEngine].
class SuggestionItem {
  const SuggestionItem({
    required this.label,
    required this.kind,
    this.detail = '',
  });

  /// The text that will be inserted when the user accepts this suggestion.
  final String label;

  final SuggestionKind kind;

  /// Short description shown in the right column of the overlay.
  final String detail;
}
