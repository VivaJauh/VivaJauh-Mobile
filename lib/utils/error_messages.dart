String friendlyErrorMessage(Object error) {
  final raw = _cleanErrorText(error);
  final lower = raw.toLowerCase();

  if (_isNetworkError(lower)) {
    return 'Server tidak bisa dihubungi. Cek koneksi internet kamu.';
  }
  if (lower.contains('response server tidak valid') ||
      lower.contains('respons server tidak valid') ||
      lower.contains('formatexception')) {
    return 'Respons server tidak valid. Coba lagi nanti.';
  }
  if (lower.contains('sync failed') ||
      lower.contains('internal server error') ||
      lower.contains('status code 500') ||
      lower == '500') {
    return 'Terjadi gangguan di server. Coba lagi nanti.';
  }

  if (lower.contains('amount exceeds outstanding balance')) {
    return 'Nominal pembayaran melebihi sisa tagihan.';
  }
  if (lower.contains('amount must be a finite positive number') ||
      lower.contains('invalid_amount') ||
      lower.contains('invalid_quantity')) {
    return 'Nominal harus lebih dari 0.';
  }
  if (lower.contains('member not found')) {
    return 'Anggota tidak ditemukan.';
  }
  if (lower.contains('member is not part of your cooperative')) {
    return 'Anggota bukan bagian dari koperasi kamu.';
  }
  if (lower.contains('only primary admin can record fund payments')) {
    return 'Hanya admin primer yang bisa mencatat pembayaran dana.';
  }
  if (lower.contains('period_key must use yyyy-mm')) {
    return 'Periode dana tidak valid.';
  }

  if (lower.contains('applicant_name is required') ||
      lower.contains('missing_applicant_name')) {
    return 'Nama pemohon wajib diisi.';
  }
  if (lower.contains('target_koperasi is required') ||
      lower.contains('missing_target_koperasi')) {
    return 'Koperasi tujuan wajib dipilih.';
  }
  if (lower.contains('requested_amount must be') ||
      lower.contains('invalid_requested_amount')) {
    return 'Jumlah pinjaman harus lebih dari 0.';
  }
  if (lower.contains('tenure_months must be') ||
      lower.contains('invalid_tenure_months')) {
    return 'Tenor pinjaman tidak valid.';
  }
  if (lower.contains('forbidden_scope')) {
    return 'Akses kamu tidak punya izin untuk aksi ini.';
  }
  if (lower.contains('unauthorized') || lower.contains('jwt')) {
    return 'Sesi berakhir. Silakan login ulang.';
  }

  return _humanizeBackendMessage(raw);
}

String _cleanErrorText(Object error) {
  var text = error.toString().trim();
  while (text.startsWith('Exception: ')) {
    text = text.substring('Exception: '.length).trim();
  }
  final colon = text.indexOf(': ');
  if (colon > 0) {
    final prefix = text.substring(0, colon);
    final isMachinePrefix = RegExp(r'^[A-Z][A-Z0-9_]+$').hasMatch(prefix);
    if (isMachinePrefix) text = text.substring(colon + 2).trim();
  }
  return text;
}

bool _isNetworkError(String lower) =>
    lower.contains('socketexception') ||
    lower.contains('failed host lookup') ||
    lower.contains('host lookup') ||
    lower.contains('clientexception') ||
    lower.contains('tidak bisa dihubungi') ||
    lower.contains('connection refused') ||
    lower.contains('connection timed out') ||
    lower.contains('timeout');

String _humanizeBackendMessage(String message) {
  var text = message
      .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
      .replaceAll('_', ' ')
      .trim();
  if (text.isEmpty) return 'Terjadi kesalahan. Coba lagi nanti.';
  if (text.length > 120) return 'Terjadi kesalahan. Coba lagi nanti.';
  return text[0].toUpperCase() + text.substring(1);
}
