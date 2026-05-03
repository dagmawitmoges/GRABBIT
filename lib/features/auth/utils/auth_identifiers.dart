/// Normalizes login/signup identifiers for Supabase (email is optional; phone is primary).
String normalizePhoneForStorage(String input) {
  var t = input.trim().replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return t;
  if (t.startsWith('0') && t.length >= 9) {
    t = '+251${t.substring(1)}';
  } else if (!t.startsWith('+')) {
    t = '+$t';
  }
  return t;
}

/// When the user skips email, Supabase still needs a unique email — derive from phone digits.
///
/// GoTrue rejects many synthetic domains and often rejects an all-numeric local-part.
/// `example.net` is reserved (RFC 2606); the `grabbit_` prefix keeps the local-part valid.
String syntheticEmailFromPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    throw ArgumentError('Invalid phone for synthetic email');
  }
  return 'grabbit_$digits@example.net';
}

/// Login field: real email or phone (maps to synthetic email when no @).
String loginEmailFromInput(String raw) {
  final t = raw.trim();
  if (t.contains('@')) return t;
  return syntheticEmailFromPhone(normalizePhoneForStorage(t));
}
