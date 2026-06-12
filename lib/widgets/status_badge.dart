import 'package:flutter/material.dart';

import '../models/models.dart';
import 'app_icons.dart';
import 'app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge._({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  factory StatusBadge.sync(SyncStatus status) => switch (status) {
    SyncStatus.pending => StatusBadge._(
      label: 'Menunggu',
      background: AppColors.secondaryLight,
      foreground: AppColors.warningDark,
      icon: AppIcons.pending,
    ),
    SyncStatus.syncing => StatusBadge._(
      label: 'Mengirim',
      background: AppColors.primaryLight,
      foreground: AppColors.primaryDark,
      icon: AppIcons.sync,
    ),
    SyncStatus.synced => StatusBadge._(
      label: 'Tersinkron',
      background: const Color(0xFFDCF5E8),
      foreground: AppColors.successDark,
      icon: AppIcons.synced,
    ),
    SyncStatus.failed => StatusBadge._(
      label: 'Gagal',
      background: const Color(0xFFFFE4E1),
      foreground: AppColors.dangerDark,
      icon: AppIcons.failed,
    ),
    SyncStatus.conflict => StatusBadge._(
      label: 'Konflik',
      background: const Color(0xFFFFF0C0),
      foreground: AppColors.warningDark,
      icon: AppIcons.conflict,
    ),
  };

  factory StatusBadge.verification(VerificationStatus status) =>
      switch (status) {
        VerificationStatus.unverified => StatusBadge._(
          label: 'Belum Verifikasi',
          background: AppColors.secondaryLight,
          foreground: AppColors.warningDark,
          icon: AppIcons.unverified,
        ),
        VerificationStatus.verified => StatusBadge._(
          label: 'Terverifikasi',
          background: const Color(0xFFDCF5E8),
          foreground: AppColors.successDark,
          icon: AppIcons.verified,
        ),
        VerificationStatus.rejected => StatusBadge._(
          label: 'Ditolak',
          background: const Color(0xFFFFE4E1),
          foreground: AppColors.dangerDark,
          icon: AppIcons.rejected,
        ),
        VerificationStatus.needsCorrection => StatusBadge._(
          label: 'Perlu Koreksi',
          background: const Color(0xFFFFF0C0),
          foreground: AppColors.warningDark,
          icon: AppIcons.warning,
        ),
      };

  factory StatusBadge.custom({
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) => StatusBadge._(
    label: label,
    background: background,
    foreground: foreground,
    icon: icon,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
