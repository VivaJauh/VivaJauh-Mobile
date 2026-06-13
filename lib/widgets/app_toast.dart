import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Menampilkan toast singkat. Pakai untuk memunculkan pesan error dari backend
/// agar pengguna tahu penyebab kegagalan.
void showAppToast(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final clean = message.replaceFirst('Exception: ', '').trim();
  if (clean.isEmpty) return;

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(clean),
        backgroundColor: isError ? AppColors.danger : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
